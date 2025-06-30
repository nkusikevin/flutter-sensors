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
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      setState(() {
        _status = 'Location permission not granted';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting permission...';
    });

    final status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      setState(() {
        _isLoading = false;
        _status = 'Location permission denied';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting location...';
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _status = 'Location retrieved';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting location: $e';
        _isLoading = false;
      });
    }
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
                          value: _currentPosition!.latitude.toString(),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Longitude',
                          value: _currentPosition!.longitude.toString(),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Altitude',
                          value: '${_currentPosition!.altitude.toString()} m',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Speed',
                          value: '${_currentPosition!.speed.toString()} m/s',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Accuracy',
                          value: '${_currentPosition!.accuracy.toString()} m',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _requestLocationPermission,
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Request Permission'),
                ),
                ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Get Current Location'),
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
