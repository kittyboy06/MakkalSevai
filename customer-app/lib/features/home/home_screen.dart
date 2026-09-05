import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../models/service_models.dart';
import '../../models/order_models.dart';
import '../booking/booking_screen.dart';
import '../booking/booking_tab_screen.dart';
import '../activity/activity_tab_screen.dart';
import '../profile/profile_tab_screen.dart';
import '../tracking/tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _api = ApiClient();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  List<ServiceCategory> _categories = [];
  bool _isLoading = true;
  int _currentNavIndex = 0;
  OrderModel? _activeOrder;
  ServiceItem? _selectedServiceForBooking;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _checkActiveOrder();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await _locationService.acquireLiveLocation();
  }

  Future<void> _loadCategories() async {
    final cats = await _api.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkActiveOrder() async {
    final active = await _api.getActiveOrderMe();
    if (mounted && active != null) {
      setState(() {
        _activeOrder = active;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildExploreScreen(),
          BookingTabScreen(
            initialSelectedService: _selectedServiceForBooking,
            onSwitchToActivity: () => setState(() => _currentNavIndex = 2),
          ),
          ActivityTabScreen(
            onGoToBooking: () => setState(() => _currentNavIndex = 1),
          ),
          const ProfileTabScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildExploreScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await _loadCategories();
                await _checkActiveOrder();
                await _locationService.acquireLiveLocation(forceRefresh: true);
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_activeOrder != null) _buildActiveOrderBanner(_activeOrder!),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildCivicTrustBanner(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      title: 'Core Trades',
                      titleTa: 'முதன்மை தொழில்கள்',
                      actionLabel: 'View ${_categories.isEmpty ? 24 : _categories.fold<int>(0, (sum, c) => sum + c.services.length)} Services',
                      onAction: () => setState(() => _currentNavIndex = 1),
                    ),
                    const SizedBox(height: 12),
                    _buildCoreTradesGrid(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      title: 'Cleaning & Upkeep',
                      titleTa: 'தூய்மை & பராமரிப்பு',
                      actionLabel: 'Explore All',
                      onAction: () => setState(() => _currentNavIndex = 1),
                    ),
                    const SizedBox(height: 12),
                    _buildCleaningCarousel(),
                    const SizedBox(height: 24),
                    _buildCivicAssuranceCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveOrderBanner(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ACTIVE BOOKING: ${(order.serviceName ?? "SERVICE").toUpperCase()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.status.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  order.matchedWorker != null
                      ? 'Worker: ${order.matchedWorker!.fullName}'
                      : 'Connecting with nearby verified tradesperson...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrackingScreen(
                    order: order,
                    serviceName: order.serviceName ?? 'Service',
                  ),
                ),
              ).then((_) => _checkActiveOrder());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Track', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'MakkalSevai',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'GOV-BACKED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onEmeraldContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              ValueListenableBuilder<LocationState?>(
                valueListenable: _locationService.liveLocation,
                builder: (context, loc, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _locationService.isLocating,
                    builder: (context, locating, _) {
                      return InkWell(
                        onTap: () => _locationService.acquireLiveLocation(forceRefresh: true),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 13, color: AppColors.secondary),
                            const SizedBox(width: 3),
                            Text(
                              loc != null ? loc.shortAddress : (locating ? 'Acquiring GPS...' : 'Detecting Location...'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          tooltip: 'Refresh Location & Services',
          onPressed: () {
            _locationService.acquireLiveLocation(forceRefresh: true);
            _loadCategories();
            _checkActiveOrder();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (query) {
          if (query.trim().isNotEmpty) {
            setState(() => _currentNavIndex = 1);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search Electrician, Plumber, AC Repair...',
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 24,
                width: 1,
                color: AppColors.outline,
              ),
              IconButton(
                icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                tooltip: 'Tamil & English Voice Search',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listening... "மின்சார பணியாளர் வேண்டும்"'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCivicTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.emerald, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Verified Local Skills • Fair Civic Pricing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'DigiLocker & e-Shram authenticated tradespeople • ₹250 flat diagnostic standard',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String titleTa,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              titleTa,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            children: [
              Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoreTradesGrid() {
    final coreServices = [
      {'id': 1, 'name': 'Electrician', 'name_ta': 'மின்சார பணியாளர்', 'fee': 250, 'icon': Icons.bolt_rounded, 'tag': 'Popular'},
      {'id': 2, 'name': 'Plumber', 'name_ta': 'குழாய் பழுது', 'fee': 250, 'icon': Icons.water_drop_rounded, 'tag': 'Gov Price'},
      {'id': 3, 'name': 'Carpenter', 'name_ta': 'தச்சர்', 'fee': 300, 'icon': Icons.carpenter_rounded, 'tag': 'Certified'},
      {'id': 4, 'name': 'Painter', 'name_ta': 'ஓவியர்', 'fee': 350, 'icon': Icons.format_paint_rounded, 'tag': 'Fixed Fee'},
      {'id': 5, 'name': 'Mason', 'name_ta': 'கொத்தனார்', 'fee': 400, 'icon': Icons.foundation_rounded, 'tag': 'Verified'},
      {'id': 7, 'name': 'AC Repair', 'name_ta': 'ஏசி பழுது', 'fee': 350, 'icon': Icons.ac_unit_rounded, 'tag': 'Fast ETA'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: coreServices.length,
      itemBuilder: (context, index) {
        final svc = coreServices[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingScreen(
                  serviceId: svc['id'] as int,
                  serviceName: svc['name'] as String,
                  serviceNameTa: svc['name_ta'] as String,
                  baseFee: (svc['fee'] as num).toDouble(),
                ),
              ),
            ).then((_) => _checkActiveOrder());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    svc['tag'] as String,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSecondaryContainer,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    svc['icon'] as IconData,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      svc['name'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '₹${svc['fee']} standard',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCleaningCarousel() {
    final cleaningItems = [
      {
        'title': 'House / Deep Cleaning',
        'subtitle': '4-room full sanitize with verified cleaners',
        'price': '₹500',
        'icon': Icons.cleaning_services_rounded,
        'rating': '4.9 ★ (120+)',
      },
      {
        'title': 'Water Tank Cleaning',
        'subtitle': 'High-pressure mechanized disinfection',
        'price': '₹450',
        'icon': Icons.water_rounded,
        'rating': '4.8 ★ (85+)',
      },
      {
        'title': 'Pest Control',
        'subtitle': 'Safe odorless herbal treatments',
        'price': '₹600',
        'icon': Icons.bug_report_rounded,
        'rating': '4.9 ★ (95+)',
      },
    ];

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cleaningItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = cleaningItems[index];
          return Container(
            width: 270,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['price'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.emerald),
                          ),
                          Flexible(
                            child: Text(
                              item['rating'] as String,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.secondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCivicAssuranceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'No Hidden Charges Guarantee',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text(
                  'Fixed diagnostic fees upfront. Additional repair parts agreed before starting work.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        setState(() => _currentNavIndex = i);
        if (i == 2) {
          _checkActiveOrder();
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Bookings'),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.receipt_long_rounded),
              if (_activeOrder != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          label: 'Activity',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
