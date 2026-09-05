import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../models/service_models.dart';
import '../matching/matching_screen.dart';

class BookingTabScreen extends StatefulWidget {
  final ServiceItem? initialSelectedService;
  final VoidCallback? onSwitchToActivity;

  const BookingTabScreen({
    super.key,
    this.initialSelectedService,
    this.onSwitchToActivity,
  });

  @override
  State<BookingTabScreen> createState() => _BookingTabScreenState();
}

class _BookingTabScreenState extends State<BookingTabScreen> {
  final ApiClient _api = ApiClient();
  final LocationService _locationService = LocationService();
  final TextEditingController _descController = TextEditingController();

  List<ServiceCategory> _categories = [];
  bool _isLoadingServices = true;
  int _selectedCategoryIndex = 0;
  ServiceItem? _selectedService;
  bool _isImmediate = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialSelectedService;
    _loadCategories();
    _ensureLocation();
  }

  Future<void> _ensureLocation() async {
    if (_locationService.liveLocation.value == null) {
      await _locationService.acquireLiveLocation();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await _api.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoadingServices = false;
        if (_selectedService == null && cats.isNotEmpty && cats.first.services.isNotEmpty) {
          _selectedService = cats.first.services.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  List<ServiceItem> get _filteredServices {
    if (_categories.isEmpty) return [];
    if (_selectedCategoryIndex == 0) {
      // All services
      return _categories.expand((c) => c.services).toList();
    }
    final cat = _categories[_selectedCategoryIndex - 1];
    return cat.services;
  }

  List<String> get _quickTagsForCurrentService {
    final name = _selectedService?.name.toLowerCase() ?? '';
    if (name.contains('electr')) {
      return ['Switchboard Sparking', 'MCB Tripping', 'Ceiling Fan Noise', 'Wiring Short Circuit'];
    } else if (name.contains('plumb')) {
      return ['Pipe Leakage', 'Tap Repair', 'Drainage Block', 'Water Tank Overflow'];
    } else if (name.contains('carpenter')) {
      return ['Door Lock Jammed', 'Cabinet Hinge', 'Furniture Assembly', 'Window Latch'];
    } else if (name.contains('ac') || name.contains('appliance')) {
      return ['No Cooling', 'Water Dripping', 'Gas Refill Check', 'Filter Deep Clean'];
    } else if (name.contains('clean')) {
      return ['Full House Deep Clean', 'Kitchen Degreasing', 'Bathroom Sanitization', 'Balcony Wash'];
    }
    return ['Inspection Needed', 'Emergency Repair', 'Routine Maintenance', 'Installation'];
  }

  Future<void> _handleBookOrder() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service trade to continue')),
      );
      return;
    }

    // Check location
    var loc = _locationService.liveLocation.value;
    loc ??= await _locationService.acquireLiveLocation(forceRefresh: true);

    if (loc == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable GPS location to dispatch nearby verified tradespeople.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    String description = _descController.text.trim();
    if (description.isEmpty) {
      description = 'Service request for ${_selectedService!.name}';
    }

    try {
      final order = await _api.createOrder(
        serviceId: _selectedService!.id,
        description: description,
        scheduledType: _isImmediate ? 'immediate' : 'scheduled',
        customerLat: loc.lat,
        customerLng: loc.lng,
        addressText: loc.fullAddress,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchingScreen(
              order: order,
              serviceName: _selectedService!.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit booking: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Book a Service', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(
              'Government Verified Tradespeople at Fixed Fair Rates',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: _isLoadingServices
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLiveGpsCard(),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  _buildServiceSelector(),
                  const SizedBox(height: 20),
                  _buildPricingBreakdownCard(),
                  const SizedBox(height: 20),
                  _buildScheduleSelector(),
                  const SizedBox(height: 20),
                  _buildProblemDescription(),
                  const SizedBox(height: 24),
                  _buildDispatchButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildLiveGpsCard() {
    return ValueListenableBuilder<LocationState?>(
      valueListenable: _locationService.liveLocation,
      builder: (context, loc, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _locationService.isLocating,
          builder: (context, locating, _) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Device Location',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc != null ? loc.shortAddress : (locating ? 'Acquiring device GPS...' : 'Location unavailable'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: locating ? null : () => _locationService.acquireLiveLocation(forceRefresh: true),
                        icon: locating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                        label: Text(
                          locating ? 'Locating' : 'Refresh',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  if (loc != null) ...[
                    const Divider(height: 16, thickness: 0.5),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 14, color: AppColors.emerald),
                        const SizedBox(width: 4),
                        Text(
                          'GPS accuracy: ${loc.accuracyLabel}',
                          style: const TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          loc.locality,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Trade Category',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final isSelected = _selectedCategoryIndex == idx;
              final label = idx == 0 ? 'All Trades (${_filteredServices.length})' : _categories[idx - 1].name;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategoryIndex = idx);
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSelector() {
    final services = _filteredServices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Services',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              '${services.length} options',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemCount: services.length,
          itemBuilder: (context, idx) {
            final svc = services[idx];
            final isSelected = _selectedService?.id == svc.id;

            IconData iconData = Icons.build_rounded;
            if (svc.slug.contains('electric')) iconData = Icons.bolt_rounded;
            if (svc.slug.contains('plumb')) iconData = Icons.water_drop_rounded;
            if (svc.slug.contains('carpenter')) iconData = Icons.carpenter_rounded;
            if (svc.slug.contains('paint')) iconData = Icons.format_paint_rounded;
            if (svc.slug.contains('ac')) iconData = Icons.ac_unit_rounded;
            if (svc.slug.contains('clean')) iconData = Icons.cleaning_services_rounded;
            if (svc.slug.contains('mason')) iconData = Icons.foundation_rounded;

            return InkWell(
              onTap: () {
                setState(() => _selectedService = svc);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            iconData,
                            size: 18,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          svc.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (svc.nameTa != null)
                          Text(
                            svc.nameTa!,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'From ₹${svc.baseDiagnosticFee.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
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
        ),
      ],
    );
  }

  Widget _buildPricingBreakdownCard() {
    if (_selectedService == null) return const SizedBox.shrink();

    final base = _selectedService!.baseDiagnosticFee;
    final plat = _selectedService!.platformFee;
    final total = base + plat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Estimate (${_selectedService!.name})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emeraldContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FIXED RATE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.onEmeraldContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Diagnostic Fee (Direct to Worker)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('₹${base.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Civic Platform & Insurance Fee', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('₹${plat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Upfront Deposit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '✓ Escrow-protected. Payout released only after your digital signoff upon completion.',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dispatch Urgency',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isImmediate = true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _isImmediate ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isImmediate ? AppColors.primary : AppColors.outline,
                      width: _isImmediate ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, size: 18, color: _isImmediate ? AppColors.primary : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Immediate (15m)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isImmediate ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isImmediate = false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: !_isImmediate ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isImmediate ? AppColors.primary : AppColors.outline,
                      width: !_isImmediate ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 18, color: !_isImmediate ? AppColors.primary : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Schedule Later',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: !_isImmediate ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProblemDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe the Issue',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _quickTagsForCurrentService.map((tag) {
            return ActionChip(
              label: Text(tag, style: const TextStyle(fontSize: 11)),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.outline),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onPressed: () {
                setState(() {
                  _descController.text = tag;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Living room switchboard sparking when AC turned on...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            fillColor: AppColors.surface,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDispatchButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleBookOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Dispatch ${_selectedService?.name ?? 'Tradesperson'}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}
