import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_models.dart';
import '../tracking/tracking_screen.dart';

class MatchingScreen extends StatefulWidget {
  final OrderModel order;
  final String serviceName;

  const MatchingScreen({
    super.key,
    required this.order,
    this.serviceName = 'Electrician',
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _currentStage = 0;
  Timer? _stageTimer;

  final List<Map<String, String>> _stages = [
    {
      'title': 'Scanning 5km radius in T. Nagar',
      'detail': 'Found 3 nearby tradespeople within range',
    },
    {
      'title': 'Matching verified skill ontology',
      'detail': 'Primary Electrician qualification verified',
    },
    {
      'title': 'DigiLocker & e-Shram authentication check',
      'detail': 'KYC verified with valid government credentials',
    },
    {
      'title': 'Optimizing 4-factor scoring algorithm',
      'detail': '45% Distance + 30% Rating + 15% Reliability + 10% Fairness',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _advanceStages();
  }

  void _advanceStages() {
    _stageTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (_currentStage < _stages.length - 1) {
        if (mounted) setState(() => _currentStage++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stageTimer?.cancel();
    super.dispose();
  }

  void _proceedToTracking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingScreen(
          order: widget.order,
          serviceName: widget.serviceName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.order.matchedWorker;
    final isMatched = _currentStage >= 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Matching Engine'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildRadarPulse(isMatched),
              const SizedBox(height: 24),
              Text(
                isMatched ? 'Tradesperson Matched!' : 'Finding Best Tradesperson...',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                isMatched
                    ? 'Rajesh Kumar accepted your request'
                    : 'Dispatching via PostGIS 4-factor spatial engine',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildPipelineStages(),
              const Spacer(),
              if (isMatched && worker != null) _buildMatchedWorkerPreview(worker),
              const SizedBox(height: 16),
              if (isMatched)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _proceedToTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.location_on_rounded, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Track Worker on Live Map',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

  Widget _buildRadarPulse(bool isMatched) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          height: 130,
          width: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isMatched) ...[
                Container(
                  width: 130 * _pulseController.value,
                  height: 130 * _pulseController.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withOpacity(0.2 * (1 - _pulseController.value)),
                  ),
                ),
                Container(
                  width: 90 * _pulseController.value,
                  height: 90 * _pulseController.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.15 * (1 - _pulseController.value)),
                  ),
                ),
              ],
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMatched ? AppColors.emerald : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (isMatched ? AppColors.emerald : AppColors.primary).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isMatched ? Icons.check_rounded : Icons.radar_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPipelineStages() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: List.generate(_stages.length, (index) {
          final isCompleted = _currentStage >= index;
          final isCurrent = _currentStage == index;
          final stage = _stages[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.emerald : AppColors.surfaceDim,
                    border: Border.all(
                      color: isCompleted ? AppColors.emerald : AppColors.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['title']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent || isCompleted ? FontWeight.w700 : FontWeight.w500,
                          color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stage['detail']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isCompleted ? AppColors.textSecondary : AppColors.textMuted.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  const Text(
                    'DONE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMatchedWorkerPreview(MatchedWorker worker) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'RK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      worker.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: AppColors.emerald, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.secondary, size: 15),
                    const SizedBox(width: 3),
                    Text(
                      '${worker.ratingAvg} (${worker.ratingCount} jobs)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${worker.distanceKm.toStringAsFixed(1)} km away',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
