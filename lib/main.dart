import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: PulseWidget(),
      ),
    );
  }
}

class PulseWidget extends StatefulWidget {
  const PulseWidget({super.key});

  @override
  _PulseWidgetState createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> {
  final String serviceUUID = "<service-uuid>";
  final String characteristicUUID = "<characteristic-uuid>";
  bool _isConnected = false;
  int _pulse = 0;
  StreamSubscription? _valueSubscription;

  @override
  void initState() {
    super.initState();
    _connectToWatch();
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    super.dispose();
  }

  void _connectToWatch() async {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    try {
      // Start scanning for devices
      flutterBlue.startScan(timeout: const Duration(seconds: 4));

      // Listen for scan results
      StreamSubscription scanSubscription =
          flutterBlue.scanResults.listen((results) async {
        for (ScanResult result in results) {
          if (result.device.name.contains("Apple Watch")) {
            // Stop scanning for devices
            flutterBlue.stopScan();

            // Connect to device
            await result.device.connect();

            // Discover services and characteristics
            List<BluetoothService> services =
                await result.device.discoverServices();
            for (var service in services) {
              if (service.uuid.toString() == serviceUUID) {
                service.characteristics.forEach((characteristic) async {
                  if (characteristic.uuid.toString() == characteristicUUID) {
                    // Subscribe to characteristic changes
                    await characteristic.setNotifyValue(true);
                    _valueSubscription = characteristic.value.listen((value) {
                      setState(() {
                        _pulse = value[1];
                      });
                    });
                    setState(() {
                      _isConnected = true;
                    });
                  }
                });
              }
            }
          }
        }
      });

      // Stop scanning after timeout
      Timer(const Duration(seconds: 4), () {
        flutterBlue.stopScan();
        scanSubscription.cancel();
        if (!_isConnected) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                      title: const Text('Error'),
                      content: const Text('Failed to connect to Apple Watch.'),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('OK'))
                      ]));
        }
      });
    } catch (e) {
      print('Error connecting to Apple Watch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.favorite,
          color: Colors.red,
          size: 50.0,
        ),
        const SizedBox(height: 20.0),
        Text(
          'Pulse: $_pulse',
          style: const TextStyle(fontSize: 24.0),
        ),
      ],
    );
  }
}
