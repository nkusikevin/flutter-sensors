import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isPermissionGranted = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothPermissions();
    _setupBluetoothListeners();
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _stopScan();
    super.dispose();
  }

  Future<void> _checkBluetoothPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.status;
    final bluetoothConnect = await Permission.bluetoothConnect.status;
    final locationWhenInUse = await Permission.locationWhenInUse.status;

    setState(() {
      _isPermissionGranted = bluetoothScan.isGranted &&
          bluetoothConnect.isGranted &&
          locationWhenInUse.isGranted;
    });
  }

  Future<void> _requestBluetoothPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();

    await _checkBluetoothPermissions();
  }

  void _setupBluetoothListeners() {
    // Listen to scan results
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
    }, onError: (e) {
      debugPrint('Scan results error: $e');
    });

    // Listen to scanning state
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      setState(() {
        _isScanning = isScanning;
      });
    });
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _scanResults = [];
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      debugPrint('Error starting scan: $e');
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.platformName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
        actions: [
          if (_isPermissionGranted)
            IconButton(
              icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
              onPressed: _isScanning ? _stopScan : _startScan,
            ),
        ],
      ),
      body: _isPermissionGranted
          ? Column(
              children: [
                // Status bar
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isScanning ? 'Scanning...' : 'Not scanning',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_scanResults.length} devices found',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                // Device list
                Expanded(
                  child: _scanResults.isEmpty
                      ? Center(
                          child: _isScanning
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'No devices found. Tap scan to start.'),
                        )
                      : ListView.builder(
                          itemCount: _scanResults.length,
                          itemBuilder: (context, index) {
                            final result = _scanResults[index];
                            final device = result.device;
                            final rssi = result.rssi;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  device.platformName.isNotEmpty
                                      ? device.platformName
                                      : 'Unknown Device',
                                ),
                                subtitle: Text(
                                  'ID: ${device.remoteId}\nRSSI: $rssi dBm',
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _connectToDevice(device),
                                  child: const Text('Connect'),
                                ),
                                isThreeLine: true,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.bluetooth),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Bluetooth permissions are required',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This app needs Bluetooth and location permissions to scan for devices.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _requestBluetoothPermissions,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: const Text('Grant Permissions'),
                  ),
                ],
              ),
            ),
      floatingActionButton: _isPermissionGranted
          ? FloatingActionButton.extended(
              onPressed: _isScanning ? _stopScan : _startScan,
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Stop' : 'Scan'),
            )
          : null,
    );
  }
}
