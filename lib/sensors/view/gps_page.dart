import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GpsPage extends StatefulWidget {
  const GpsPage({super.key});

  @override
  State<GpsPage> createState() => _GpsPageState();
}

class _GpsPageState extends State<GpsPage> {
  Position? _currentPosition;
  String _status = 'Waiting for location...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking location services...';
    });

    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _status =
              'Location services are disabled. Please enable them in device settings.';
        });
        return;
      }

      // Then check permissions
      await _checkLocationPermission();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error checking location services: $e';
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          _getCurrentLocation();
          break;
        case LocationPermission.denied:
          setState(() {
            _isLoading = false;
            _status =
                'Location permission is denied. Tap "Request Permission" to allow access.';
          });
          break;
        case LocationPermission.deniedForever:
          setState(() {
            _isLoading = false;
            _status =
                'Location permission is permanently denied. Please enable it in device settings.';
          });
          break;
        case LocationPermission.unableToDetermine:
          setState(() {
            _isLoading = false;
            _status = 'Unable to determine location permission status.';
          });
          break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error checking location permission: $e';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting location permission...';
    });

    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // On iOS, try to open location settings
        setState(() {
          _status = 'Location services disabled. Opening settings...';
        });
        await Geolocator.openLocationSettings();
        setState(() {
          _isLoading = false;
          _status = 'Please enable location services and try again.';
        });
        return;
      }

      // Request permission using Geolocator (more reliable on iOS)
      LocationPermission permission = await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          _getCurrentLocation();
          break;
        case LocationPermission.denied:
          setState(() {
            _isLoading = false;
            _status =
                'Location permission denied. Please try again or enable in settings.';
          });
          break;
        case LocationPermission.deniedForever:
          setState(() {
            _isLoading = false;
            _status =
                'Location permission permanently denied. Please enable in device settings.';
          });
          // Open app settings on iOS
          await Geolocator.openAppSettings();
          break;
        case LocationPermission.unableToDetermine:
          setState(() {
            _isLoading = false;
            _status =
                'Unable to determine location permission. Please try again.';
          });
          break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error requesting location permission: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting current location...';
    });

    try {
      // Check location services again before getting position
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _status = 'Location services are disabled.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _status = 'Location retrieved successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Location',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      _InfoRow(
                        label: 'Status',
                        value: _status,
                      ),
                      if (_currentPosition != null) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Latitude',
                          value: _currentPosition!.latitude.toStringAsFixed(6),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Longitude',
                          value: _currentPosition!.longitude.toStringAsFixed(6),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Altitude',
                          value:
                              '${_currentPosition!.altitude.toStringAsFixed(2)} m',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Speed',
                          value:
                              '${_currentPosition!.speed.toStringAsFixed(2)} m/s',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Accuracy',
                          value:
                              '${_currentPosition!.accuracy.toStringAsFixed(2)} m',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Timestamp',
                          value: _currentPosition!.timestamp.toString(),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _requestLocationPermission,
                        icon: const Icon(Icons.location_searching),
                        label: const Text('Request Permission'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Location'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openLocationSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Location Settings'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openAppSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('App Settings'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
