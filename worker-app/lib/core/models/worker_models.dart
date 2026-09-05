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
  final String? email;
  final List<String> secondarySkills;

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
    this.email,
    this.secondarySkills = const ['AC Repair', 'Inverter Servicing'],
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    final relScore = (json['reliability_score'] as num?)?.toDouble() ?? 0.98;
    final rawSec = json['secondary_skills'] as List<dynamic>?;
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
      email: json['email'] as String? ?? 'rajesh.kumar@example.com',
      secondarySkills: rawSec != null ? rawSec.map((e) => e.toString()).toList() : const ['AC Repair', 'Inverter Servicing'],
    );
  }

  WorkerProfileModel copyWith({
    bool? isAvailable,
    int? jobsCompleted,
    double? earningsTotal,
    int? ratingCount,
    double? currentLat,
    double? currentLng,
    String? email,
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
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      isAvailable: isAvailable ?? this.isAvailable,
      email: email ?? this.email,
      secondarySkills: secondarySkills,
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

class WorkerJobItemModel {
  final String id;
  final int? serviceId;
  final String serviceName;
  final String? serviceNameTa;
  final String customerName;
  final String customerPhone;
  final String addressText;
  final double? customerLat;
  final double? customerLng;
  final String description;
  final String status;
  final String scheduledType;
  final double finalAmount;
  final double workerPayout;
  final String paymentStatus;
  final int? rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  WorkerJobItemModel({
    required this.id,
    this.serviceId,
    required this.serviceName,
    this.serviceNameTa,
    required this.customerName,
    required this.customerPhone,
    required this.addressText,
    this.customerLat,
    this.customerLng,
    required this.description,
    required this.status,
    this.scheduledType = 'immediate',
    required this.finalAmount,
    required this.workerPayout,
    this.paymentStatus = 'paid',
    this.rating,
    this.reviewText,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  bool get isActive =>
      ['matching', 'offered', 'accepted', 'worker_enroute', 'arrived', 'in_progress'].contains(status);
  bool get isCompleted => status == 'completed';

  factory WorkerJobItemModel.fromJson(Map<String, dynamic> json) {
    return WorkerJobItemModel(
      id: json['id'] ?? '',
      serviceId: json['service_id'] as int?,
      serviceName: json['service_name'] ?? 'Electrician',
      serviceNameTa: json['service_name_ta'] ?? 'மின்சார பணியாளர்',
      customerName: json['customer_name'] ?? 'Citizen Customer',
      customerPhone: json['customer_phone'] ?? '+919876543210',
      addressText: json['address_text'] ?? 'Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai',
      customerLat: (json['customer_lat'] as num?)?.toDouble(),
      customerLng: (json['customer_lng'] as num?)?.toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'completed',
      scheduledType: json['scheduled_type'] ?? 'immediate',
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 275.0,
      workerPayout: (json['worker_payout'] as num?)?.toDouble() ?? 250.0,
      paymentStatus: json['payment_status'] ?? 'paid',
      rating: json['rating'] as int?,
      reviewText: json['review_text'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null ? DateTime.tryParse(json['accepted_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at']) : null,
    );
  }
}

class WorkerTransactionModel {
  final String id;
  final String type; // 'JOB_PAYOUT', 'BANK_TRANSFER', 'WELFARE_CESS', 'REFUND_ADJUSTMENT'
  final double amount;
  final String status;
  final String? reference;
  final String? description;
  final DateTime createdAt;

  WorkerTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.reference,
    this.description,
    required this.createdAt,
  });

  factory WorkerTransactionModel.fromJson(Map<String, dynamic> json) {
    return WorkerTransactionModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'JOB_PAYOUT',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'completed',
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WorkerBankAccountModel {
  final String bankName;
  final String accountNumberMasked;
  final String ifsc;
  final String accountHolder;
  final String statusLabel;

  WorkerBankAccountModel({
    required this.bankName,
    required this.accountNumberMasked,
    required this.ifsc,
    required this.accountHolder,
    required this.statusLabel,
  });

  String get ifscCode => ifsc;

  factory WorkerBankAccountModel.fromJson(Map<String, dynamic> json) {
    return WorkerBankAccountModel(
      bankName: json['bank_name'] ?? 'State Bank of India',
      accountNumberMasked: json['account_number_masked'] ?? '•••• •••• 4892',
      ifsc: json['ifsc'] ?? 'SBIN0000800',
      accountHolder: json['account_holder'] ?? 'Rajesh Kumar',
      statusLabel: json['status_label'] ?? 'Demo Linked Account',
    );
  }
}

class WorkerWalletModel {
  final String workerId;
  final double availableBalance;
  final double todayEarnings;
  final double thisWeekEarnings;
  final double totalLifeEarnings;
  final double welfareCessTotal;
  final WorkerBankAccountModel payoutBank;
  final List<WorkerTransactionModel> transactions;

  WorkerBankAccountModel get bankAccount => payoutBank;
  double get weekEarnings => thisWeekEarnings;
  double get lifetimeEarnings => totalLifeEarnings;

  WorkerWalletModel({
    required this.workerId,
    required this.availableBalance,
    required this.todayEarnings,
    required this.thisWeekEarnings,
    required this.totalLifeEarnings,
    required this.welfareCessTotal,
    required this.payoutBank,
    required this.transactions,
  });

  factory WorkerWalletModel.fromJson(Map<String, dynamic> json) {
    final rawBank = json['payout_bank'] as Map<String, dynamic>? ?? {};
    final rawTxList = json['transactions'] as List<dynamic>? ?? [];
    return WorkerWalletModel(
      workerId: json['worker_id'] ?? '',
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0.0,
      thisWeekEarnings: (json['this_week_earnings'] as num?)?.toDouble() ?? 0.0,
      totalLifeEarnings: (json['total_life_earnings'] as num?)?.toDouble() ?? 0.0,
      welfareCessTotal: (json['welfare_cess_total'] as num?)?.toDouble() ?? 0.0,
      payoutBank: WorkerBankAccountModel.fromJson(rawBank),
      transactions: rawTxList
          .map((t) => WorkerTransactionModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
