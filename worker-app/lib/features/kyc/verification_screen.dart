import 'package:flutter/material.dart';
import '../../core/models/worker_models.dart';
import '../../core/theme/app_theme.dart';

class VerificationScreen extends StatelessWidget {
  final WorkerProfileModel worker;

  const VerificationScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.slateCanvas,
      appBar: AppBar(
        title: const Text('Tradesperson Verification'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Mandatory Hackathon Sandbox Compliance Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.saffronSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.saffronUrgency, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.saffronUrgency, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMO VERIFICATION FLOW (SIMULATED)',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppTheme.slateNavy,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Academic Hackathon Sandbox • Simulated DigiLocker & e-Shram credentials',
                          style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Worker Identity Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slateBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.slateNavy,
                    child: Text(
                      'RK',
                      style: textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(worker.fullName, style: textTheme.headlineSmall?.copyWith(fontSize: 18)),
                        Text('${worker.primarySkillName} (${worker.primarySkillTa})',
                            style: textTheme.bodyMedium?.copyWith(color: AppTheme.slateMuted)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.slateMuted),
                            const SizedBox(width: 2),
                            Text('T. Nagar, Chennai', style: textTheme.bodyMedium?.copyWith(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.emeraldDark.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.emeraldDark, size: 14),
                        const SizedBox(width: 4),
                        Text('VERIFIED', style: textTheme.labelSmall?.copyWith(color: AppTheme.emeraldDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verification Items
            _buildVerificationCard(
              textTheme: textTheme,
              icon: Icons.credit_card,
              title: 'DigiLocker Aadhaar Verification',
              subtitle: 'Masked UID: XXXX-XXXX-8839',
              statusText: 'SIMULATED MATCH',
              isSuccess: true,
              details: 'Name, DOB, and biometric token authenticated via DigiLocker Sandbox API.',
            ),
            const SizedBox(height: 12),

            _buildVerificationCard(
              textTheme: textTheme,
              icon: Icons.shield,
              title: 'e-Shram National Worker Database',
              subtitle: 'UAN: ${worker.uan}',
              statusText: 'REGISTERED',
              isSuccess: true,
              details: 'Verified under Ministry of Labour & Employment Unorganized Workers Portal.',
            ),
            const SizedBox(height: 12),

            _buildVerificationCard(
              textTheme: textTheme,
              icon: Icons.face_retouching_natural,
              title: 'AI Face Liveness & Photo Match',
              subtitle: 'Live Camera Capture vs Government ID Photo',
              statusText: 'Face Match — Demo Passed',
              isSuccess: true,
              details: 'Zero-spoof passive liveness detected. Identity confirmed without manual officer review.',
            ),
            const SizedBox(height: 12),

            _buildVerificationCard(
              textTheme: textTheme,
              icon: Icons.build_circle,
              title: 'Trade Skills & Certifications',
              subtitle: '${worker.primarySkillName} • Domestic & Commercial',
              statusText: 'LICENSED',
              isSuccess: true,
              details: 'Certified wireman license #TN-EL-4492. Eligible for high-voltage residential diagnostics.',
            ),
            const SizedBox(height: 24),

            // Bottom CTA (56px)
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('VERIFIED & READY TO WORK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldOnline,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationCard({
    required TextTheme textTheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required bool isSuccess,
    required String details,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slateBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.slateLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.slateNavy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.labelLarge?.copyWith(fontSize: 14, color: AppTheme.slateNavy)),
                    Text(subtitle, style: textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuccess ? AppTheme.emeraldSurface : AppTheme.crimsonSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle : Icons.error_outline,
                      color: isSuccess ? AppTheme.emeraldDark : AppTheme.crimsonAlert,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: textTheme.labelSmall?.copyWith(
                        color: isSuccess ? AppTheme.emeraldDark : AppTheme.crimsonAlert,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            details,
            style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
          ),
        ],
      ),
    );
  }
}
