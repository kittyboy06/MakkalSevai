class SavedAddress {
  final String label;
  final String address;
  final double lat;
  final double lng;
  final bool isDefault;

  SavedAddress({
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      label: json['label'] as String? ?? 'Saved Address',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 13.0418,
      lng: (json['lng'] as num?)?.toDouble() ?? 80.2341,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class CustomerStatsModel {
  final int totalBookings;
  final int completedBookings;
  final int activeBookings;
  final double totalSpent;

  CustomerStatsModel({
    required this.totalBookings,
    required this.completedBookings,
    required this.activeBookings,
    required this.totalSpent,
  });

  factory CustomerStatsModel.fromJson(Map<String, dynamic> json) {
    return CustomerStatsModel(
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
      activeBookings: (json['active_bookings'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomerProfileModel {
  final String id;
  final String phone;
  final String fullName;
  final String? email;
  final String role;
  final List<SavedAddress> savedAddresses;
  final CustomerStatsModel stats;

  CustomerProfileModel({
    required this.id,
    required this.phone,
    required this.fullName,
    this.email,
    required this.role,
    required this.savedAddresses,
    required this.stats,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    final rawAddresses = json['saved_addresses'] as List<dynamic>? ?? [];
    return CustomerProfileModel(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'customer',
      savedAddresses: rawAddresses
          .map((a) => SavedAddress.fromJson(a as Map<String, dynamic>))
          .toList(),
      stats: CustomerStatsModel.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
    );
  }
}
