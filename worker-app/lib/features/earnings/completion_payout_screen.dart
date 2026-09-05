import 'package:flutter/material.dart';
import '../../core/models/worker_models.dart';
import '../../core/theme/app_theme.dart';

class CompletionPayoutScreen extends StatelessWidget {
  final JobOfferModel offer;
  final WorkerProfileModel worker;
  final String workDurationText;

  const CompletionPayoutScreen({
    super.key,
    required this.offer,
    required this.worker,
    required this.workDurationText,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final updatedJobs = worker.jobsCompleted + 1;
    final updatedReviews = worker.ratingCount + 1;

    return Scaffold(
      backgroundColor: AppTheme.slateCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // 1. Success Hero Celebration
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppTheme.emeraldOnline,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3310B981),
                        blurRadius: 20,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Job Completed Successfully!',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slateNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Customer paid via UPI • Order #ORD-2026-8812',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.slateMuted),
              ),
              const SizedBox(height: 24),

              // 2. Payout Credit Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.slateBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'NET WORKER WALLET CREDIT',
                      style: textTheme.labelSmall?.copyWith(color: AppTheme.slateMuted, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+₹${offer.workerPayout.toStringAsFixed(2)}',
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emeraldDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✓ Transferred to Worker Wallet • Instant Settlement',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.emeraldDark,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.slateLight, height: 1),
                    const SizedBox(height: 14),
                    _buildBreakdownRow('Customer Paid', '₹${offer.totalAmount.toStringAsFixed(2)}', textTheme),
                    const SizedBox(height: 8),
                    _buildBreakdownRow('Civic Platform Fee', '-₹${offer.platformCommission.toStringAsFixed(2)}', textTheme, isMuted: true),
                    const SizedBox(height: 8),
                    _buildBreakdownRow('Work Duration', workDurationText, textTheme),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Customer Rating & Review Snippet
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (index) => const Icon(Icons.star, color: Colors.amber, size: 18),
                          ),
                        ),
                        Text(
                          '5.0 RATING',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppTheme.slateNavy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"Rajesh did a very neat job fixing the sparking switchboard safely. Arrived promptly with tester and replacement fuse. Highly recommended!"',
                      style: textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: AppTheme.slateDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${offer.customerName}, T. Nagar',
                      style: textTheme.labelSmall?.copyWith(color: AppTheme.slateMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Digital Skill Passport Live Update Card
              Container(
                padding: const EdgeInsets.all(18),
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
                        const Icon(Icons.verified, color: AppTheme.emeraldOnline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Digital Skill Passport Updated',
                          style: textTheme.headlineSmall?.copyWith(fontSize: 15),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+1 JOB',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppTheme.emeraldDark,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          '${worker.jobsCompleted} → $updatedJobs',
                          'Jobs Done',
                          textTheme,
                          isHighlight: true,
                        ),
                        _buildMetricCol(
                          '4.9⭐',
                          '$updatedReviews reviews',
                          textTheme,
                        ),
                        _buildMetricCol(
                          '98%',
                          'Reliability',
                          textTheme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Verified e-Shram ${worker.uan}',
                        style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Primary CTA (56px)
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldOnline,
                    foregroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.radar, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'READY FOR NEXT JOB • GO ONLINE',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, TextTheme textTheme, {bool isMuted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: isMuted ? AppTheme.slateMuted : AppTheme.slateDark,
          ),
        ),
        Text(
          value,
          style: textTheme.labelLarge?.copyWith(
            fontSize: 13,
            color: isMuted ? AppTheme.slateMuted : AppTheme.slateNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCol(String value, String label, TextTheme textTheme, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isHighlight ? AppTheme.emeraldDark : AppTheme.slateNavy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
