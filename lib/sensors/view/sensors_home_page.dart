import 'package:flutter/material.dart';
import 'package:my_app/sensors/sensors.dart';

class SensorsHomePage extends StatelessWidget {
  const SensorsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Sensors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore and test your device capabilities',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Content section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSensorGrid(context),
                  const SizedBox(height: 32),
                  _buildInfoCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(BuildContext context) {
    final sensors = [
      _SensorInfo(
        title: 'GPS Location',
        icon: Icons.location_on_outlined,
        description: 'Access device location data',
        color: const Color(0xFF10B981),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const GpsPage(),
          ),
        ),
      ),
      _SensorInfo(
        title: 'Camera',
        icon: Icons.camera_alt_outlined,
        description: 'Access device camera',
        color: const Color(0xFF3B82F6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const CameraPage(),
          ),
        ),
      ),
      _SensorInfo(
        title: 'Microphone',
        icon: Icons.mic_outlined,
        description: 'Record audio using microphone',
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const MicrophonePage(),
          ),
        ),
      ),
      _SensorInfo(
        title: 'Vibration',
        icon: Icons.vibration_outlined,
        description: 'Control device vibration',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const VibrationPage(),
          ),
        ),
      ),
      _SensorInfo(
        title: 'Bluetooth',
        icon: Icons.bluetooth_outlined,
        description: 'Scan and connect devices',
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const BluetoothPage(),
          ),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        return _ModernSensorCard(sensor: sensors[index]);
      },
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About This App',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Test and explore various device sensors and capabilities in a modern interface.',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
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
}

class _SensorInfo {
  const _SensorInfo({
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final VoidCallback onTap;
}

class _ModernSensorCard extends StatelessWidget {
  const _ModernSensorCard({required this.sensor});

  final _SensorInfo sensor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: sensor.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sensor.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  sensor.icon,
                  color: sensor.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                sensor.title,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  sensor.description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF94A3B8),
                      size: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
