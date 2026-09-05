import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/worker_models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../kyc/verification_screen.dart';
import '../dispatch/incoming_offer_sheet.dart';
import '../job/active_job_screen.dart';
import '../jobs/worker_jobs_tab_screen.dart';
import '../wallet/worker_wallet_tab_screen.dart';
import '../profile/worker_profile_tab_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late WorkerProfileModel _worker;
  bool _isLoading = true;
  bool _isOnline = true;
  bool _isOfferSheetOpen = false;
  int _currentNavIndex = 0;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _apiClient.getRajeshProfile();
    if (mounted) {
      setState(() {
        _worker = profile;
        _isOnline = profile.isAvailable;
        _isLoading = false;
      });

      // Subscribe to Supabase Realtime for incoming dispatch offers (Decision W-D07)
      _apiClient.subscribeToRealtimeOffers(
        workerId: _worker.id,
        onNewOffer: (offer) {
          if (mounted && _isOnline && !_isOfferSheetOpen) {
            _showIncomingOfferModal(offer);
          }
        },
        onStatusUpdate: (orderId, status) {
          debugPrint('Realtime status update for order $orderId: $status');
        },
      );
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  void _toggleAvailability() async {
    final newState = !_isOnline;
    setState(() {
      _isOnline = newState;
    });
    await _apiClient.toggleAvailability(_worker.id, newState);
  }

  void _showIncomingOfferModal([JobOfferModel? customOffer]) {
    final offer = customOffer ??
        JobOfferModel(
          orderId: 'ord-demo-sih-2026',
          serviceId: 1,
          serviceName: 'Electrician',
          serviceNameTa: 'மின்சார பணியாளர்',
          customerName: AppConstants.defaultCustomerName,
          customerPhone: AppConstants.defaultCustomerPhone,
          addressText: AppConstants.defaultCustomerAddress,
          customerLat: AppConstants.defaultCustomerLat,
          customerLng: AppConstants.defaultCustomerLng,
          description:
              'Switchboard sparking in living room when ceiling fan is turned on. Need urgent inspection.',
          status: 'offered',
          totalAmount: 275.00,
          platformCommission: 25.00,
          workerPayout: 250.00,
          distanceKm: 1.8,
          etaMinutes: 7,
        );

    _isOfferSheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IncomingOfferSheet(
        offer: offer,
        onAccept: (acceptedOffer) {
          Navigator.pop(ctx);
          _isOfferSheetOpen = false;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => ActiveJobScreen(
                offer: acceptedOffer,
                worker: _worker,
              ),
            ),
          ).then((_) => _loadProfile());
        },
        onDecline: () {
          Navigator.pop(ctx);
          _isOfferSheetOpen = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer declined. Order routed to next available verified worker.'),
              backgroundColor: AppTheme.slateNavy,
            ),
          );
        },
      ),
    ).whenComplete(() {
      _isOfferSheetOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.emeraldOnline),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.slateCanvas,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildDashboardScreen(textTheme),
          WorkerJobsTabScreen(worker: _worker),
          WorkerWalletTabScreen(worker: _worker),
          WorkerProfileTabScreen(
            worker: _worker,
            onProfileUpdated: _loadProfile,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboardScreen(TextTheme textTheme) {
    return Scaffold(
      backgroundColor: AppTheme.slateCanvas,
      appBar: _buildHeader(textTheme),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppTheme.emeraldOnline,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Availability Switch
              _buildAvailabilitySwitch(textTheme),
              const SizedBox(height: 16),

              // 2. Today's Earnings Summary Card
              _buildEarningsSummaryCard(textTheme),
              const SizedBox(height: 16),

              // 3. Digital Skill Passport Snippet
              _buildSkillPassportCard(textTheme),
              const SizedBox(height: 16),

              // 4. Verification & KYC Sandbox Banner Card
              _buildKycStatusCard(textTheme),
              const SizedBox(height: 16),

              // 5. Simulated Incoming Job Trigger (Demo Control)
              _buildDemoDispatchCard(textTheme),
              const SizedBox(height: 16),

              // 6. Today's Completed Work Feed
              _buildRecentJobsFeed(textTheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(TextTheme textTheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.slateNavy,
            child: Text(
              'RK',
              style: textTheme.labelLarge?.copyWith(color: Colors.white),
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
                      _worker.fullName,
                      style: textTheme.headlineSmall?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppTheme.emeraldDark.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            _worker.ratingAvg.toStringAsFixed(1),
                            style: textTheme.labelSmall?.copyWith(
                              color: AppTheme.emeraldDark,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_worker.primarySkillName} • ${_worker.primarySkillTa}',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.slateNavy),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySwitch(TextTheme textTheme) {
    return InkWell(
      onTap: _toggleAvailability,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _isOnline ? AppTheme.emeraldSurface : AppTheme.slateLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _isOnline ? AppTheme.emeraldDark : AppTheme.slateBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? AppTheme.emeraldOnline : AppTheme.slateMuted,
                    boxShadow: _isOnline
                        ? [
                            BoxShadow(
                              color: AppTheme.emeraldOnline.withValues(alpha: 0.4 * _radarController.value),
                              blurRadius: 10,
                              spreadRadius: 4 * _radarController.value,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? '🟢 ONLINE • Receiving Jobs' : '⚪ OFFLINE • Shift Paused',
                    style: textTheme.labelLarge?.copyWith(
                      color: _isOnline ? AppTheme.emeraldDark : AppTheme.slateMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _isOnline ? 'Radar active in T. Nagar (5 km radius)' : 'Tap to go online & receive dispatches',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: _isOnline ? AppTheme.emeraldDark.withValues(alpha: 0.8) : AppTheme.slateMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _isOnline,
              onChanged: (_) => _toggleAvailability(),
              activeThumbColor: AppTheme.emeraldOnline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummaryCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(
                "TODAY'S EARNINGS",
                style: textTheme.labelSmall?.copyWith(
                  color: AppTheme.slateMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Instant Settlement',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppTheme.emeraldDark,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹1,250.00',
            style: textTheme.displayLarge?.copyWith(
              color: AppTheme.slateNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.slateLight, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(textTheme, 'Jobs Today', '4 Completed', Icons.check_circle_outline),
              _buildMiniMetric(textTheme, 'Time Online', '5.2 hrs', Icons.access_time),
              _buildMiniMetric(textTheme, 'Accept Rate', '100%', Icons.bolt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(TextTheme textTheme, String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.slateMuted),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.bodyMedium?.copyWith(fontSize: 11)),
            Text(value, style: textTheme.labelLarge?.copyWith(fontSize: 13, color: AppTheme.slateNavy)),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillPassportCard(TextTheme textTheme) {
    return Container(
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
                'Digital Skill Passport',
                style: textTheme.headlineSmall?.copyWith(fontSize: 16),
              ),
              const Spacer(),
              Text(
                _worker.uan,
                style: textTheme.labelSmall?.copyWith(
                  color: AppTheme.slateMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPassportStat(textTheme, '${_worker.ratingAvg}⭐', 'Rating (${_worker.ratingCount})'),
              _buildPassportStat(textTheme, '${_worker.reliabilityPercentage}%', 'Reliability'),
              _buildPassportStat(textTheme, '${_worker.jobsCompleted}', 'Total Jobs'),
              _buildPassportStat(textTheme, '${_worker.experienceYears}y', 'Experience'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassportStat(TextTheme textTheme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: AppTheme.slateNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildKycStatusCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.saffronSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.saffronUrgency.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.saffronUrgency.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.saffronUrgency, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DigiLocker & e-Shram Verified',
                      style: textTheme.labelLarge?.copyWith(fontSize: 14, color: AppTheme.slateNavy),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle, color: AppTheme.emeraldOnline, size: 16),
                  ],
                ),
                Text(
                  'Simulated KYC complete • View credentials',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.slateNavy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => VerificationScreen(worker: _worker),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDemoDispatchCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slateNavy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: AppTheme.saffronUrgency, size: 20),
              const SizedBox(width: 8),
              Text(
                'SIH 2026 Demo Simulation',
                style: textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TEST DISPATCH',
                  style: textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Simulate Customer Senthil Nathan booking an Electrician in T. Nagar to trigger Screen W-03 dispatch offer.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isOnline ? () => _showIncomingOfferModal() : null,
              icon: const Icon(Icons.bolt, color: Colors.white),
              label: const Text('Simulate Incoming Job Offer (30s Ring)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffronUrgency,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJobsFeed(TextTheme textTheme) {
    final jobs = [
      {'title': 'Ceiling Fan Installation', 'time': '10:30 AM', 'amount': '₹300', 'rating': '5.0⭐'},
      {'title': 'MCB Main Switch Trip Fix', 'time': '12:15 PM', 'amount': '₹350', 'rating': '4.9⭐'},
      {'title': 'Living Room Rewiring Inspection', 'time': '02:00 PM', 'amount': '₹350', 'rating': '5.0⭐'},
      {'title': 'Kitchen Power Socket Replacement', 'time': '04:15 PM', 'amount': '₹250', 'rating': '4.8⭐'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S COMPLETED JOBS',
          style: textTheme.labelSmall?.copyWith(color: AppTheme.slateMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        ...jobs.map((j) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.slateBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.emeraldOnline, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(j['title']!, style: textTheme.labelLarge?.copyWith(fontSize: 13, color: AppTheme.slateNavy)),
                        Text(j['time']!, style: textTheme.bodyMedium?.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(j['amount']!, style: textTheme.labelLarge?.copyWith(fontSize: 14, color: AppTheme.emeraldDark)),
                      Text(j['rating']!, style: textTheme.bodyMedium?.copyWith(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });
      },
      selectedItemColor: AppTheme.slateNavy,
      unselectedItemColor: AppTheme.slateMuted,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'My Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
