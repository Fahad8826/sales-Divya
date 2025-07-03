import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class app extends StatelessWidget {
  Future<void> launchDirectCall(String number) async {
    final status = await Permission.phone.request();

    if (status.isGranted) {
      const platform = MethodChannel('custom.dialer/launch');
      try {
        await platform.invokeMethod('launchDialer', {'number': number});
      } on PlatformException catch (e) {
        print('Failed to launch dialer: ${e.message}');
      }
    } else {
      print('Phone permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Dialer Test')),
        body: Center(
          child: ElevatedButton(
            child: Text('Call Now'),
            onPressed: () => launchDirectCall('9496407635'),
          ),
        ),
      ),
    );
  }
}
