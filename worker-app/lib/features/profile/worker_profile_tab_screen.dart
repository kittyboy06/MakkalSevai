import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/worker_models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../auth/worker_login_screen.dart';
import '../kyc/verification_screen.dart';

class WorkerProfileTabScreen extends StatefulWidget {
  final WorkerProfileModel worker;
  final VoidCallback onProfileUpdated;

  const WorkerProfileTabScreen({
    super.key,
    required this.worker,
    required this.onProfileUpdated,
  });

  @override
  State<WorkerProfileTabScreen> createState() => _WorkerProfileTabScreenState();
}

class _WorkerProfileTabScreenState extends State<WorkerProfileTabScreen> {
  final ApiClient _apiClient = ApiClient();
  late WorkerProfileModel _worker;
  bool _isLocating = false;
  String? _gpsStatus;

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
  }

  Future<void> _updateLiveGps() async {
    setState(() {
      _isLocating = true;
      _gpsStatus = 'Requesting device GPS...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLocating = false;
          _gpsStatus = 'Location services are disabled on this device.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLocating = false;
            _gpsStatus = 'Location permissions denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLocating = false;
          _gpsStatus = 'Location permissions permanently denied.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Sync with FastAPI & PostGIS
      await _apiClient.updateLocationMe(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _worker = _worker.copyWith(
            currentLat: position.latitude,
            currentLng: position.longitude,
          );
          _isLocating = false;
          _gpsStatus = 'Live GPS synced: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
        widget.onProfileUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device GPS synced with MakkalSevai dispatch radar.'),
            backgroundColor: AppTheme.emeraldDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _gpsStatus = 'GPS fetch error: $e';
        });
      }
    }
  }

  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from the Worker Partner app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ApiClient.clearSession();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WorkerLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimsonAlert,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.slateCanvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Trade Partner Profile',
          style: textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.crimsonAlert),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Digital Skill Passport Header Card
            _buildPassportHeaderCard(textTheme),
            const SizedBox(height: 16),

            // 2. Performance & Reliability Stats
            _buildStatsCard(textTheme),
            const SizedBox(height: 16),

            // 3. Real Device GPS Telemetry Card (Decision W-D12)
            _buildGpsCard(textTheme),
            const SizedBox(height: 16),

            // 4. Skills & Trades List
            _buildSkillsCard(textTheme),
            const SizedBox(height: 16),

            // 5. Verification & DigiLocker Sandbox
            _buildVerificationCard(textTheme),
            const SizedBox(height: 24),

            // 6. Sign Out Button
            OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout, color: AppTheme.crimsonAlert),
              label: const Text('Sign Out of Partner Account', style: TextStyle(color: AppTheme.crimsonAlert)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.crimsonAlert),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPassportHeaderCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slateBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.slateNavy,
                child: Text(
                  _worker.fullName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join(),
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _worker.fullName,
                          style: textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppTheme.emeraldOnline, size: 18),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_worker.primarySkillName} • ${_worker.primarySkillTa}',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ApiClient.currentEmail ?? _worker.email ?? AppConstants.defaultWorkerEmail,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateNavy),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.slateLight),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.emeraldDark.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: AppTheme.emeraldDark),
                    const SizedBox(width: 4),
                    Text(
                      _worker.uan,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldDark),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.slateLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DigiLocker Verified',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slateNavy),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMANCE & RELIABILITY',
            style: textTheme.labelSmall?.copyWith(color: AppTheme.slateMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCol(textTheme, '${_worker.ratingAvg.toStringAsFixed(1)}⭐', 'Rating (${_worker.ratingCount})'),
              _buildStatCol(textTheme, '${_worker.reliabilityPercentage.toInt()}%', 'Reliability'),
              _buildStatCol(textTheme, '${_worker.jobsCompleted}', 'Total Jobs'),
              _buildStatCol(textTheme, '${_worker.experienceYears}y', 'Experience'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(TextTheme textTheme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.slateNavy),
        ),
        const SizedBox(height: 4),
        Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted)),
      ],
    );
  }

  Widget _buildGpsCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: AppTheme.emeraldDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Live Device GPS Location',
                style: textTheme.labelLarge?.copyWith(fontSize: 14, color: AppTheme.slateNavy),
              ),
              const Spacer(),
              if (_isLocating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldDark),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current PostGIS Telemetry: ${_worker.currentLat.toStringAsFixed(4)}, ${_worker.currentLng.toStringAsFixed(4)} (T. Nagar radius)',
            style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
          ),
          if (_gpsStatus != null) ...[
            const SizedBox(height: 6),
            Text(
              _gpsStatus!,
              style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.emeraldDark, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _isLocating ? null : _updateLiveGps,
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Update Real Device GPS Coordinates'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.slateNavy,
                side: const BorderSide(color: AppTheme.slateBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VERIFIED SKILLS & SERVICES',
            style: textTheme.labelSmall?.copyWith(color: AppTheme.slateMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSkillBadge('${_worker.primarySkillName} (Primary)', true),
              ..._worker.secondarySkills.map((s) => _buildSkillBadge(s, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBadge(String title, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? AppTheme.emeraldSurface : AppTheme.slateLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPrimary ? AppTheme.emeraldDark.withValues(alpha: 0.4) : AppTheme.slateBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrimary ? Icons.star : Icons.check_circle_outline,
            size: 13,
            color: isPrimary ? AppTheme.emeraldDark : AppTheme.slateNavy,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
              color: isPrimary ? AppTheme.emeraldDark : AppTheme.slateNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.saffronSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.saffronUrgency.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.saffronUrgency, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KYC & Document Verification',
                  style: textTheme.labelLarge?.copyWith(fontSize: 13, color: AppTheme.slateNavy),
                ),
                Text(
                  'View simulated Aadhaar e-KYC & Trade Certificate',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.slateNavy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VerificationScreen(worker: _worker)),
              );
            },
          ),
        ],
      ),
    );
  }
}
