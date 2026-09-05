class MatchedWorker {
  final String workerId;
  final String fullName;
  final String? phone;
  final String? uan;
  final double ratingAvg;
  final int ratingCount;
  final double reliabilityScore;
  final int jobsCompleted;
  final double distanceKm;
  final double score;
  final double lat;
  final double lng;
  final String experienceYears;

  MatchedWorker({
    required this.workerId,
    required this.fullName,
    this.phone,
    this.uan,
    required this.ratingAvg,
    required this.ratingCount,
    required this.reliabilityScore,
    required this.jobsCompleted,
    required this.distanceKm,
    required this.score,
    required this.lat,
    required this.lng,
    this.experienceYears = '3.2 yrs exp',
  });

  factory MatchedWorker.fromJson(Map<String, dynamic> json) {
    return MatchedWorker(
      workerId: (json['worker_id'] ?? json['id'] ?? '').toString(),
      fullName: json['full_name'] as String? ?? 'Rajesh Kumar',
      phone: json['phone'] as String? ?? '+919876543211',
      uan: json['uan'] as String? ?? 'UAN-TN-2026-88392',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.9,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 142,
      reliabilityScore: (json['reliability_score'] as num?)?.toDouble() ?? 0.98,
      jobsCompleted: (json['jobs_completed'] as num?)?.toInt() ?? 142,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.8,
      score: (json['score'] as num?)?.toDouble() ?? 0.94,
      lat: (json['lat'] as num?)?.toDouble() ?? 13.0450,
      lng: (json['lng'] as num?)?.toDouble() ?? 80.2380,
      experienceYears: json['experience_years'] as String? ?? '3.2 yrs exp',
    );
  }
}

class OrderModel {
  final String id;
  final int serviceId;
  final String? serviceName;
  final String? description;
  final String status;
  final String scheduledType;
  final double customerLat;
  final double customerLng;
  final String? addressText;
  final double finalAmount;
  final double platformCommission;
  final double workerPayout;
  final String paymentStatus;
  final MatchedWorker? matchedWorker;
  final String? razorpayOrderId;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final int? ratingStars;
  final String? reviewText;

  OrderModel({
    required this.id,
    required this.serviceId,
    this.serviceName,
    this.description,
    required this.status,
    this.scheduledType = 'immediate',
    required this.customerLat,
    required this.customerLng,
    this.addressText,
    this.finalAmount = 275.0,
    this.platformCommission = 25.0,
    this.workerPayout = 250.0,
    this.paymentStatus = 'pending',
    this.matchedWorker,
    this.razorpayOrderId,
    this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.ratingStars,
    this.reviewText,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    MatchedWorker? worker;
    if (json['matched_worker'] != null && json['matched_worker'] is Map<String, dynamic>) {
      worker = MatchedWorker.fromJson(json['matched_worker'] as Map<String, dynamic>);
    }

    DateTime? parseDt(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return OrderModel(
      id: json['id'] as String,
      serviceId: (json['service_id'] as num?)?.toInt() ?? 1,
      serviceName: json['service_name'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'requested',
      scheduledType: json['scheduled_type'] as String? ?? 'immediate',
      customerLat: (json['customer_lat'] as num?)?.toDouble() ?? 13.0418,
      customerLng: (json['customer_lng'] as num?)?.toDouble() ?? 80.2341,
      addressText: json['address_text'] as String?,
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 275.0,
      platformCommission: (json['platform_commission'] as num?)?.toDouble() ?? 25.0,
      workerPayout: (json['worker_payout'] as num?)?.toDouble() ?? 250.0,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      matchedWorker: worker,
      razorpayOrderId: json['razorpay_order_id'] as String?,
      createdAt: parseDt(json['created_at']),
      acceptedAt: parseDt(json['accepted_at']),
      completedAt: parseDt(json['completed_at']),
      ratingStars: (json['rating_stars'] as num?)?.toInt() ?? (json['rating']?['stars'] as num?)?.toInt(),
      reviewText: json['review_text'] as String? ?? json['rating']?['review_text'] as String?,
    );
  }
}
