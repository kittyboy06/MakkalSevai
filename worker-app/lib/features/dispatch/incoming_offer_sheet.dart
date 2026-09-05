import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/worker_models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class IncomingOfferSheet extends StatefulWidget {
  final JobOfferModel offer;
  final Function(JobOfferModel) onAccept;
  final VoidCallback onDecline;

  const IncomingOfferSheet({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingOfferSheet> createState() => _IncomingOfferSheetState();
}

class _IncomingOfferSheetState extends State<IncomingOfferSheet> {
  final ApiClient _apiClient = ApiClient();
  int _remainingSeconds = 30;
  Timer? _timer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          widget.onDecline();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleAccept() async {
    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();
    await _apiClient.acceptOrder(widget.offer.orderId);
    if (mounted) {
      widget.onAccept(widget.offer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _remainingSeconds / 30.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.slateBorder, width: 2),
          left: BorderSide(color: AppTheme.slateBorder, width: 1.5),
          right: BorderSide(color: AppTheme.slateBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.slateBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Urgency Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on, color: AppTheme.emeraldOnline, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.offer.serviceName} / ${widget.offer.serviceNameTa}',
                        style: textTheme.headlineSmall?.copyWith(fontSize: 16),
                      ),
                      Text(
                        'Direct Dispatch • T. Nagar Cluster',
                        style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              // Circular 30s Countdown Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: AppTheme.slateLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.saffronUrgency),
                    ),
                  ),
                  Text(
                    '${_remainingSeconds}s',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slateNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer Details Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.slateCanvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slateBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.offer.customerName,
                      style: textTheme.labelLarge?.copyWith(fontSize: 15, color: AppTheme.slateNavy),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 2),
                        Text('4.9 (18 Citizen bookings)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.near_me, size: 14, color: AppTheme.slateMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.offer.addressText,
                        style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.slateBorder),
                  ),
                  child: Text(
                    '📍 ${widget.offer.distanceKm} km away • approx. ${widget.offer.etaMinutes} mins',
                    style: textTheme.labelSmall?.copyWith(color: AppTheme.slateNavy, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Issue Description Snippet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slateBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.report_problem_outlined, color: AppTheme.saffronUrgency, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.offer.description,
                    style: textTheme.bodyMedium?.copyWith(color: AppTheme.slateDark, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Transparent Financials Breakdown (Dynamic backend values)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.emeraldSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.emeraldDark.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'YOUR NET TAKE-HOME PAYOUT',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppTheme.emeraldDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '₹${widget.offer.workerPayout.toStringAsFixed(2)}',
                      style: textTheme.headlineLarge?.copyWith(
                        color: AppTheme.emeraldDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFA7F3D0), height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Total: ₹${widget.offer.totalAmount.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    Text(
                      'Civic Platform Fee: -₹${widget.offer.platformCommission.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Actions (56px Thumb-zone ergonomics)
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emeraldOnline,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ACCEPT JOB • ₹${widget.offer.workerPayout.toStringAsFixed(0)}',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : widget.onDecline,
              child: const Text('Decline Offer'),
            ),
          ),
        ],
      ),
    );
  }
}
