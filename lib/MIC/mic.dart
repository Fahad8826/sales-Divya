import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class MicStreamingPage extends StatefulWidget {
  const MicStreamingPage({super.key});

  @override
  State<MicStreamingPage> createState() => _MicStreamingPageState();
}

class _MicStreamingPageState extends State<MicStreamingPage> {
  static const MethodChannel _channel = MethodChannel('mic_service_channel');
  String _status = 'Mic not started';

  Future<void> _requestMicPermissionAndStart() async {
    var micStatus = await Permission.microphone.status;
    var notificationStatus = await Permission.notification.status;

    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
    }
    if (!notificationStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
    }

    if (micStatus.isGranted && notificationStatus.isGranted) {
      try {
        final result = await _channel.invokeMethod('startMicStream');
        setState(() => _status = 'Mic streaming started');
        debugPrint("Mic service started: $result");
      } catch (e) {
        setState(() => _status = 'Error: $e');
        debugPrint("Error starting mic service: $e");
      }
    } else {
      setState(
        () => _status =
            'Permissions denied: Mic=${micStatus.isGranted}, Notifications=${notificationStatus.isGranted}',
      );
    }
  }

  Future<void> _stopMicStream() async {
    try {
      await _channel.invokeMethod('stopMicStream');
      setState(() => _status = 'Mic stream stopped and Firestore data deleted');
    } catch (e) {
      setState(() => _status = 'Error stopping mic stream: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salesman Mic Stream')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _requestMicPermissionAndStart,
              icon: const Icon(Icons.mic),
              label: const Text("Start Mic Streaming"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _stopMicStream,
              icon: const Icon(Icons.mic),
              label: const Text("Stop Mic Streaming"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}