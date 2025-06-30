import 'dart:async';
import 'dart:io';

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
  bool _isBluetoothOn = false;
  String? _error;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
    _checkBluetoothPermissions();
    _setupBluetoothListeners();
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _stopScan();
    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      setState(() {
        _isBluetoothOn = adapterState == BluetoothAdapterState.on;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to check Bluetooth state: $e';
      });
    }
  }

  Future<void> _checkBluetoothPermissions() async {
    try {
      bool allPermissionsGranted = true;

      if (Platform.isAndroid) {
        // Android 12+ (API 31+) requires specific Bluetooth permissions
        final bluetoothScan = await Permission.bluetoothScan.status;
        final bluetoothConnect = await Permission.bluetoothConnect.status;
        final bluetoothAdvertise = await Permission.bluetoothAdvertise.status;
        final locationWhenInUse = await Permission.locationWhenInUse.status;

        allPermissionsGranted = bluetoothScan.isGranted &&
            bluetoothConnect.isGranted &&
            bluetoothAdvertise.isGranted &&
            locationWhenInUse.isGranted;
      } else if (Platform.isIOS) {
        // iOS only needs Bluetooth permission
        final bluetooth = await Permission.bluetooth.status;
        allPermissionsGranted = bluetooth.isGranted;
      }

      setState(() {
        _isPermissionGranted = allPermissionsGranted;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to check Bluetooth permissions: $e';
      });
    }
  }

  Future<void> _requestBluetoothPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request Android Bluetooth permissions
        final results = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.locationWhenInUse,
        ].request();

        final allGranted = results.values.every((status) => status.isGranted);
        setState(() {
          _isPermissionGranted = allGranted;
          _error = allGranted
              ? null
              : 'Some permissions were denied. Please grant all permissions to use Bluetooth.';
        });
      } else if (Platform.isIOS) {
        // Request iOS Bluetooth permission
        final status = await Permission.bluetooth.request();
        setState(() {
          _isPermissionGranted = status.isGranted;
          _error = status.isGranted
              ? null
              : 'Bluetooth permission is required to scan for devices.';
        });
      }

      if (_isPermissionGranted) {
        await _checkBluetoothState();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to request Bluetooth permissions: $e';
      });
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  void _setupBluetoothListeners() {
    // Listen to scan results
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
    }, onError: (e) {
      setState(() {
        _error = 'Scan results error: $e';
      });
      debugPrint('Scan results error: $e');
    });

    // Listen to scanning state
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      setState(() {
        _isScanning = isScanning;
      });
    });

    // Listen to Bluetooth adapter state
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _isBluetoothOn = state == BluetoothAdapterState.on;
        if (!_isBluetoothOn && _isScanning) {
          _stopScan();
        }
        _error = null;
      });
    });
  }

  Future<void> _startScan() async {
    if (_isScanning || !_isPermissionGranted || !_isBluetoothOn) return;

    setState(() {
      _scanResults = [];
      _error = null;
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      setState(() {
        _error = 'Error starting scan: $e';
      });
      debugPrint('Error starting scan: $e');
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      setState(() {
        _error = 'Error stopping scan: $e';
      });
      debugPrint('Error stopping scan: $e');
    }
  }

  Future<void> _turnOnBluetooth() async {
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      } else {
        // iOS doesn't allow programmatic Bluetooth enabling
        setState(() {
          _error = 'Please turn on Bluetooth manually in device settings.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to turn on Bluetooth: $e';
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _error = null;
      });

      await device.connect(autoConnect: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Connected to ${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bluetooth Permissions Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Platform.isAndroid
                  ? 'This app needs Bluetooth and location permissions to scan for devices.'
                  : 'This app needs Bluetooth permission to scan for devices.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestBluetoothPermissions,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Grant Permissions'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openAppSettings,
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothOffScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bluetooth is Off',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please turn on Bluetooth to scan for devices.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (Platform.isAndroid)
              ElevatedButton.icon(
                onPressed: _turnOnBluetooth,
                icon: const Icon(Icons.bluetooth),
                label: const Text('Turn On Bluetooth'),
              )
            else
              ElevatedButton.icon(
                onPressed: _openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
        actions: [
          if (_isPermissionGranted && _isBluetoothOn)
            IconButton(
              icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
              onPressed: _isScanning ? _stopScan : _startScan,
            ),
        ],
      ),
      body: !_isPermissionGranted
          ? _buildPermissionScreen()
          : !_isBluetoothOn
              ? _buildBluetoothOffScreen()
              : Column(
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_scanResults.length} devices found',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Error message
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        color: Colors.red.shade50,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Device list
                    Expanded(
                      child: _scanResults.isEmpty
                          ? Center(
                              child: _isScanning
                                  ? const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Scanning for devices...'),
                                      ],
                                    )
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
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Icon(
                                        Icons.bluetooth,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _isPermissionGranted && _isBluetoothOn
          ? FloatingActionButton.extended(
              onPressed: _isScanning ? _stopScan : _startScan,
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Stop' : 'Scan'),
            )
          : null,
    );
  }
}
