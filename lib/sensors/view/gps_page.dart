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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // Location data section
            _buildLocationCard(),
            const SizedBox(height: 24),

            // Action buttons section
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPS Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Access your device\'s precise location',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Current Location',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading) ...[
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading location...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildStatusRow(),
            if (_currentPosition != null) ...[
              const SizedBox(height: 16),
              _buildLocationData(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentPosition != null
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentPosition != null
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFF59E0B).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _currentPosition != null ? Icons.check_circle : Icons.info,
            color: _currentPosition != null
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(
                color: _currentPosition != null
                    ? const Color(0xFF047857)
                    : const Color(0xFFD97706),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationData() {
    return Column(
      children: [
        _InfoCard(
          icon: Icons.location_on,
          label: 'Coordinates',
          value:
              '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.height,
                label: 'Altitude',
                value: '${_currentPosition!.altitude.toStringAsFixed(2)} m',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.speed,
                label: 'Speed',
                value: '${_currentPosition!.speed.toStringAsFixed(2)} m/s',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.my_location,
                label: 'Accuracy',
                value: '${_currentPosition!.accuracy.toStringAsFixed(2)} m',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: Icons.access_time,
                label: 'Updated',
                value:
                    '${_currentPosition!.timestamp?.hour.toString().padLeft(2, '0')}:${_currentPosition!.timestamp?.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.location_searching,
                label: 'Request Permission',
                onPressed: _requestLocationPermission,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.my_location,
                label: 'Get Location',
                onPressed: _getCurrentLocation,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.settings_outlined,
                label: 'Location Settings',
                onPressed: _openLocationSettings,
                color: const Color(0xFF64748B),
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.settings,
                label: 'App Settings',
                onPressed: _openAppSettings,
                color: const Color(0xFF64748B),
                isOutlined: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.isOutlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    return isOutlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          );
  }
}
