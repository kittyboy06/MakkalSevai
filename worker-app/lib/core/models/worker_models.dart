class WorkerProfileModel {
  final String id;
  final String fullName;
  final String phone;
  final String kycStatus;
  final String uan;
  final String primarySkillName;
  final String primarySkillTa;
  final double ratingAvg;
  final int ratingCount;
  final double reliabilityScore;
  final int reliabilityPercentage;
  final int jobsCompleted;
  final double experienceYears;
  final double earningsTotal;
  final double currentLat;
  final double currentLng;
  final bool isAvailable;

  WorkerProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.kycStatus,
    required this.uan,
    required this.primarySkillName,
    required this.primarySkillTa,
    required this.ratingAvg,
    required this.ratingCount,
    required this.reliabilityScore,
    required this.reliabilityPercentage,
    required this.jobsCompleted,
    required this.experienceYears,
    required this.earningsTotal,
    required this.currentLat,
    required this.currentLng,
    this.isAvailable = true,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    final relScore = (json['reliability_score'] as num?)?.toDouble() ?? 0.98;
    return WorkerProfileModel(
      id: json['worker_id'] ?? json['id'] ?? '',
      fullName: json['full_name'] ?? 'Rajesh Kumar',
      phone: json['phone'] ?? '+919876543211',
      kycStatus: json['kyc_status'] ?? 'verified',
      uan: json['uan'] ?? 'UAN-TN-2026-88392',
      primarySkillName: json['primary_skill_name'] ?? 'Electrician',
      primarySkillTa: json['primary_skill_ta'] ?? 'மின்சார பணியாளர்',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.9,
      ratingCount: json['rating_count'] as int? ?? 142,
      reliabilityScore: relScore,
      reliabilityPercentage: json['reliability_percentage'] as int? ?? (relScore * 100).round(),
      jobsCompleted: json['jobs_completed'] as int? ?? 142,
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 3.2,
      earningsTotal: (json['earnings_total'] as num?)?.toDouble() ?? 54200.0,
      currentLat: (json['current_lat'] as num?)?.toDouble() ?? 13.0450,
      currentLng: (json['current_lng'] as num?)?.toDouble() ?? 80.2380,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  WorkerProfileModel copyWith({
    bool? isAvailable,
    int? jobsCompleted,
    double? earningsTotal,
    int? ratingCount,
  }) {
    return WorkerProfileModel(
      id: id,
      fullName: fullName,
      phone: phone,
      kycStatus: kycStatus,
      uan: uan,
      primarySkillName: primarySkillName,
      primarySkillTa: primarySkillTa,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      reliabilityScore: reliabilityScore,
      reliabilityPercentage: reliabilityPercentage,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      experienceYears: experienceYears,
      earningsTotal: earningsTotal ?? this.earningsTotal,
      currentLat: currentLat,
      currentLng: currentLng,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class JobOfferModel {
  final String orderId;
  final int serviceId;
  final String serviceName;
  final String serviceNameTa;
  final String customerName;
  final String customerPhone;
  final String addressText;
  final double customerLat;
  final double customerLng;
  final String description;
  final String status;
  final double totalAmount;
  final double platformCommission;
  final double workerPayout;
  final double distanceKm;
  final int etaMinutes;

  JobOfferModel({
    required this.orderId,
    required this.serviceId,
    required this.serviceName,
    required this.serviceNameTa,
    required this.customerName,
    required this.customerPhone,
    required this.addressText,
    required this.customerLat,
    required this.customerLng,
    required this.description,
    required this.status,
    required this.totalAmount,
    required this.platformCommission,
    required this.workerPayout,
    required this.distanceKm,
    required this.etaMinutes,
  });

  factory JobOfferModel.fromJson(Map<String, dynamic> json) {
    return JobOfferModel(
      orderId: json['id'] ?? '',
      serviceId: json['service_id'] as int? ?? 1,
      serviceName: json['service_name'] ?? 'Electrician',
      serviceNameTa: json['service_name_ta'] ?? 'மின்சார பணியாளர்',
      customerName: json['customer_name'] ?? 'Senthil Nathan',
      customerPhone: json['customer_phone'] ?? '+919876543210',
      addressText: json['address_text'] ??
          'Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai - 600017',
      customerLat: (json['customer_lat'] as num?)?.toDouble() ?? 13.0418,
      customerLng: (json['customer_lng'] as num?)?.toDouble() ?? 80.2341,
      description: json['description'] ??
          'Switchboard sparking in living room when ceiling fan is turned on. Need urgent inspection.',
      status: json['status'] ?? 'offered',
      totalAmount: (json['final_amount'] as num?)?.toDouble() ?? 275.0,
      platformCommission: (json['platform_commission'] as num?)?.toDouble() ?? 25.0,
      workerPayout: (json['worker_payout'] as num?)?.toDouble() ?? 250.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.8,
      etaMinutes: json['eta_minutes'] as int? ?? 7,
    );
  }
}
