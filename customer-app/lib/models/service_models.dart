class ServiceItem {
  final int id;
  final int categoryId;
  final String name;
  final String? nameTa;
  final String slug;
  final String? icon;
  final double baseDiagnosticFee;
  final double platformFee;
  final bool isActive;

  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.nameTa,
    required this.slug,
    this.icon,
    required this.baseDiagnosticFee,
    required this.platformFee,
    required this.isActive,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      nameTa: json['name_ta'] as String?,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      baseDiagnosticFee: (json['base_diagnostic_fee'] as num?)?.toDouble() ?? 250.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 25.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  double get totalEstimate => baseDiagnosticFee + platformFee;
}

class ServiceCategory {
  final int id;
  final String name;
  final String? nameTa;
  final String slug;
  final String? icon;
  final List<ServiceItem> services;

  ServiceCategory({
    required this.id,
    required this.name,
    this.nameTa,
    required this.slug,
    this.icon,
    required this.services,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'] as List<dynamic>? ?? [];
    return ServiceCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      nameTa: json['name_ta'] as String?,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      services: rawServices.map((s) => ServiceItem.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}
