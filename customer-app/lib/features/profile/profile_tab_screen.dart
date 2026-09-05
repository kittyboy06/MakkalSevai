import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_service.dart';
import '../../models/customer_models.dart';
import '../auth/login_screen.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  final ApiClient _api = ApiClient();
  final LocationService _locationService = LocationService();

  CustomerProfileModel? _profile;
  bool _isLoading = true;
  bool _showTechCoords = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final prof = await _api.getCustomerProfileMe();
    if (mounted) {
      setState(() {
        _profile = prof;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSaveCurrentLocation() async {
    final loc = _locationService.liveLocation.value;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please acquire GPS location first')),
      );
      return;
    }

    final labelController = TextEditingController(text: 'Current Location');
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Device Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save this address to your profile for faster checkout:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Text(loc.fullAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Address Label (e.g. Home, Office)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save to DB'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      final updated = await _api.saveAddressMe(
        label: labelController.text.trim().isEmpty ? 'Saved Address' : labelController.text.trim(),
        address: loc.fullAddress,
        lat: loc.lat,
        lng: loc.lng,
        isDefault: false,
      );

      if (mounted) {
        if (updated != null) {
          setState(() => _profile = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address saved to your PostgreSQL profile!'),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Citizen Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityHeader(),
                    const SizedBox(height: 16),
                    _buildLiveGpsSection(),
                    const SizedBox(height: 16),
                    _buildStatisticsSection(),
                    const SizedBox(height: 16),
                    _buildSavedAddressesSection(),
                    const SizedBox(height: 16),
                    _buildCivicSettings(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIdentityHeader() {
    final name = (_profile?.fullName != null && _profile!.fullName.trim().isNotEmpty)
        ? _profile!.fullName.trim()
        : (ApiClient.currentFullName ?? (_profile?.email ?? ApiClient.currentEmail ?? 'Citizen'));
    final phone = (_profile?.phone != null && _profile!.phone.trim().isNotEmpty)
        ? _profile!.phone.trim()
        : 'Registered Citizen';
    final email = (_profile?.email != null && _profile!.email!.trim().isNotEmpty)
        ? _profile!.email!.trim()
        : (ApiClient.currentEmail ?? '');

    String initial = 'C';
    if (name.isNotEmpty && name != 'Citizen') {
      initial = name[0].toUpperCase();
    } else if (email.isNotEmpty) {
      initial = email[0].toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VERIFIED CITIZEN',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.onEmeraldContainer),
                      ),
                    ),
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveGpsSection() {
    return ValueListenableBuilder<LocationState?>(
      valueListenable: _locationService.liveLocation,
      builder: (context, loc, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _locationService.isLocating,
          builder: (context, locating, _) {
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.gps_fixed_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Current Device Location',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: locating ? null : () => _locationService.acquireLiveLocation(forceRefresh: true),
                        icon: locating
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.refresh_rounded, size: 14),
                        label: Text(locating ? 'Locating...' : 'Refresh GPS', style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (loc != null) ...[
                    Text(
                      loc.fullAddress,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 14, color: AppColors.emerald),
                        const SizedBox(width: 4),
                        Text(
                          'Accuracy: ${loc.accuracyLabel}',
                          style: const TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _showTechCoords = !_showTechCoords),
                          child: Text(
                            _showTechCoords ? 'Hide Lat/Lng' : 'Show Lat/Lng',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (_showTechCoords) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Coordinates: ${loc.coordinatesDisplay}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handleSaveCurrentLocation,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: const Text('Save Current Location as Saved Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      locating ? 'Detecting device hardware GPS coordinates...' : 'GPS location currently unavailable.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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

  Widget _buildStatisticsSection() {
    final stats = _profile?.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Platform Activity',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                icon: Icons.calendar_today_rounded,
                label: 'Total Bookings',
                value: '${stats?.totalBookings ?? 0}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatTile(
                icon: Icons.done_all_rounded,
                label: 'Completed Jobs',
                value: '${stats?.completedBookings ?? 0}',
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatTile(
                icon: Icons.currency_rupee_rounded,
                label: 'Total Spent',
                value: '₹${stats?.totalSpent.toInt() ?? 0}',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesSection() {
    final addresses = _profile?.savedAddresses ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved Addresses',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              '${addresses.length} saved',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline),
            ),
            child: const Text('No saved addresses. Save your current GPS location above.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final addr = addresses[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(addr.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              if (addr.isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('DEFAULT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.onEmeraldContainer)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(addr.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCivicSettings() {
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
          const Text('Civic Settings & Assistance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.translate_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Language / மொழி', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'Tamil', child: Text('தமிழ் (Tamil)', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLanguage = val);
                },
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Labour Board Citizen Helpline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Toll-Free: 1800-425-7825 (Tamil Nadu)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 18, color: AppColors.emerald),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All services covered under TN Gig Workers Welfare Charter & 100% Escrow Guarantee.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ApiClient.clearSession();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.red),
              label: const Text('Sign Out / Switch Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
