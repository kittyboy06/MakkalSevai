import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/worker_models.dart';

class ApiClient {
  final String baseUrl;
  RealtimeChannel? _orderSubscription;
  Timer? _pollingTimer;

  static String? _cachedToken;
  static String? _cachedEmail;
  static String? _cachedWorkerId;
  static String? _cachedFullName;
  static String? _cachedPhone;

  ApiClient({String? customBaseUrl})
      : baseUrl = customBaseUrl ?? AppConstants.apiBaseUrl;

  static bool get hasActiveSession => _cachedToken != null;
  static String? get currentEmail => _cachedEmail;
  static String? get currentWorkerId => _cachedWorkerId;
  static String? get currentFullName => _cachedFullName;
  static String? get currentPhone => _cachedPhone;

  /// Clear the active worker session on sign out.
  static void clearSession() {
    _cachedToken = null;
    _cachedEmail = null;
    _cachedWorkerId = null;
    _cachedFullName = null;
    _cachedPhone = null;
  }

  /// Authenticate worker using Email and Password (or dev OTP).
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    String? password,
    String? otp,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final candidateHosts = AppConstants.candidateUrls;

    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('$host/api/v1/auth/email/login');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': cleanEmail,
            if (password != null && password.isNotEmpty) 'password': password,
            'otp': otp?.trim() ?? '123456',
          }),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _cachedToken = data['access_token'] as String?;
          _cachedEmail = data['email'] as String? ?? cleanEmail;
          _cachedFullName = data['full_name'] as String?;
          _cachedWorkerId = data['user_id'] as String?;
          _cachedPhone = data['phone'] as String?;
          return data;
        }
      } catch (e) {
        debugPrint('[ApiClient] Tried $host/login: $e');
      }
    }

    // Graceful offline fallback for physical devices running on 5G/cellular
    debugPrint('[ApiClient] Local backend unreachable, establishing offline worker session.');
    final isDemoRajesh = cleanEmail == 'rajesh.kumar@example.com';
    _cachedToken = 'tn-worker-token-${DateTime.now().millisecondsSinceEpoch}';
    _cachedEmail = cleanEmail;
    _cachedFullName = isDemoRajesh ? AppConstants.defaultWorkerName : cleanEmail.split('@')[0].toUpperCase();
    _cachedWorkerId = isDemoRajesh ? 'd9b3a0b1-4c12-4c28-98e3-0d6e8e883921' : 'worker-${cleanEmail.hashCode.abs()}';
    _cachedPhone = isDemoRajesh ? AppConstants.defaultWorkerPhone : '+919876543211';

    return {
      'access_token': _cachedToken,
      'token_type': 'bearer',
      'user_id': _cachedWorkerId,
      'email': _cachedEmail,
      'full_name': _cachedFullName,
      'role': 'worker',
      'phone': _cachedPhone,
    };
  }

  /// Authenticate worker using Mobile Phone and OTP (Decision W-D10)
  Future<Map<String, dynamic>> loginWithOtp({
    required String phone,
    required String otp,
  }) async {
    final cleanPhone = phone.trim();
    final candidateHosts = AppConstants.candidateUrls;

    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('$host/api/v1/auth/otp/verify');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'phone': cleanPhone,
            'otp': otp.trim(),
            'role': 'worker',
          }),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _cachedToken = data['access_token'] as String?;
          _cachedEmail = data['email'] as String? ?? AppConstants.defaultWorkerEmail;
          _cachedFullName = data['full_name'] as String? ?? AppConstants.defaultWorkerName;
          _cachedWorkerId = data['user_id'] as String?;
          _cachedPhone = data['phone'] as String? ?? cleanPhone;
          return data;
        }
      } catch (e) {
        debugPrint('[ApiClient] Tried $host/otp/verify: $e');
      }
    }

    // Offline fallback
    _cachedToken = 'tn-worker-token-${DateTime.now().millisecondsSinceEpoch}';
    _cachedEmail = AppConstants.defaultWorkerEmail;
    _cachedFullName = AppConstants.defaultWorkerName;
    _cachedWorkerId = 'd9b3a0b1-4c12-4c28-98e3-0d6e8e883921';
    _cachedPhone = cleanPhone;

    return {
      'access_token': _cachedToken,
      'token_type': 'bearer',
      'user_id': _cachedWorkerId,
      'email': _cachedEmail,
      'full_name': _cachedFullName,
      'role': 'worker',
      'phone': _cachedPhone,
    };
  }

  /// Register trade partner account
  Future<Map<String, dynamic>> signupWithEmail({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();
    final candidateHosts = AppConstants.candidateUrls;

    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('$host/api/v1/auth/email/signup');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': cleanName,
            'email': cleanEmail,
            'password': password,
            if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
            'role': 'worker',
          }),
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          _cachedToken = data['access_token'] as String?;
          _cachedEmail = data['email'] as String? ?? cleanEmail;
          _cachedFullName = data['full_name'] as String? ?? cleanName;
          _cachedWorkerId = data['user_id'] as String?;
          _cachedPhone = data['phone'] as String?;
          return data;
        } else if (res.statusCode == 400) {
          final err = jsonDecode(res.body);
          throw Exception(err['detail'] ?? 'Registration failed');
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('already exists')) rethrow;
        debugPrint('[ApiClient] Tried $host/signup: $e');
      }
    }

    _cachedToken = 'tn-worker-token-${DateTime.now().millisecondsSinceEpoch}';
    _cachedEmail = cleanEmail;
    _cachedFullName = cleanName;
    _cachedWorkerId = 'worker-${cleanEmail.hashCode.abs()}';
    _cachedPhone = phone ?? '+919876543211';

    return {
      'access_token': _cachedToken,
      'token_type': 'bearer',
      'user_id': _cachedWorkerId,
      'email': _cachedEmail,
      'full_name': _cachedFullName,
      'role': 'worker',
      'phone': _cachedPhone,
    };
  }

  /// Ensure JWT token is present
  Future<String?> ensureAuthenticated() async {
    if (_cachedToken != null) return _cachedToken;
    try {
      final res = await loginWithEmail(email: AppConstants.defaultWorkerEmail);
      return res['access_token'] as String?;
    } catch (e) {
      debugPrint('[ApiClient] ensureAuthenticated error: $e');
    }
    return null;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await ensureAuthenticated();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Fetch all active & completed jobs assigned to this worker (Decision W-D09)
  Future<List<WorkerJobItemModel>> getWorkerJobsMe() async {
    final candidateHosts = AppConstants.candidateUrls;
    for (final host in candidateHosts) {
      try {
        final headers = await _authHeaders();
        final uri = Uri.parse('$host/api/v1/workers/me/jobs');
        final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          return data.map((j) => WorkerJobItemModel.fromJson(j as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('[ApiClient] getWorkerJobsMe error on $host: $e');
      }
    }
    return _fallbackWorkerJobs();
  }

  /// Fetch live wallet metrics and transaction ledger (Decision W-D11)
  Future<WorkerWalletModel> getWorkerWalletMe() async {
    final candidateHosts = AppConstants.candidateUrls;
    for (final host in candidateHosts) {
      try {
        final headers = await _authHeaders();
        final uri = Uri.parse('$host/api/v1/workers/me/wallet');
        final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          return WorkerWalletModel.fromJson(jsonDecode(res.body));
        }
      } catch (e) {
        debugPrint('[ApiClient] getWorkerWalletMe error on $host: $e');
      }
    }
    return _fallbackWorkerWallet();
  }

  /// Request instant bank payout (test mode)
  Future<WorkerWalletModel> requestPayoutMe(double amount) async {
    final candidateHosts = AppConstants.candidateUrls;
    for (final host in candidateHosts) {
      try {
        final headers = await _authHeaders();
        final uri = Uri.parse('$host/api/v1/workers/me/wallet/payout');
        final res = await http.post(
          uri,
          headers: headers,
          body: jsonEncode({'amount': amount}),
        ).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          return WorkerWalletModel.fromJson(jsonDecode(res.body));
        }
      } catch (e) {
        debugPrint('[ApiClient] requestPayoutMe error on $host: $e');
      }
    }
    // Fallback simulation
    final current = _fallbackWorkerWallet();
    return WorkerWalletModel(
      workerId: current.workerId,
      availableBalance: (current.availableBalance - amount).clamp(0.0, 99999.0),
      todayEarnings: current.todayEarnings,
      thisWeekEarnings: current.thisWeekEarnings,
      totalLifeEarnings: current.totalLifeEarnings,
      welfareCessTotal: current.welfareCessTotal,
      payoutBank: current.payoutBank,
      transactions: [
        WorkerTransactionModel(
          id: 'txn-${DateTime.now().millisecondsSinceEpoch}',
          type: 'BANK_TRANSFER',
          amount: amount,
          status: 'completed',
          reference: 'IMPS-TN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          description: 'Instant Settlement to State Bank of India •••• 4892 (Demo)',
          createdAt: DateTime.now(),
        ),
        ...current.transactions,
      ],
    );
  }

  /// Fetch live Digital Skill Passport for authenticated worker (Decision W-D09)
  Future<WorkerProfileModel> getProfileMe() async {
    final candidateHosts = AppConstants.candidateUrls;
    for (final host in candidateHosts) {
      try {
        final headers = await _authHeaders();
        final uri = Uri.parse('$host/api/v1/workers/me/passport');
        final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          return WorkerProfileModel.fromJson(jsonDecode(res.body));
        }
      } catch (e) {
        debugPrint('[ApiClient] getProfileMe error on $host: $e');
      }
    }
    return getRajeshProfile();
  }

  /// Update worker GPS coordinates in PostGIS (Decision W-D12)
  Future<bool> updateLocationMe(double lat, double lng) async {
    final candidateHosts = AppConstants.candidateUrls;
    for (final host in candidateHosts) {
      try {
        final headers = await _authHeaders();
        final uri = Uri.parse('$host/api/v1/workers/me/location');
        final res = await http.post(
          uri,
          headers: headers,
          body: jsonEncode({'lat': lat, 'lng': lng}),
        ).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) return true;
      } catch (e) {
        debugPrint('[ApiClient] updateLocationMe error on $host: $e');
      }
    }
    return true;
  }

  /// Toggle online/offline availability for authenticated worker
  Future<bool> toggleAvailabilityMe(bool isAvailable) async {
    final candidateHosts = AppConstants.candidateUrls;
    for (final host in candidateHosts) {
      try {
        final headers = await _authHeaders();
        final uri = Uri.parse('$host/api/v1/workers/me/availability?is_available=$isAvailable');
        final res = await http.post(uri, headers: headers).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) return true;
      } catch (e) {
        debugPrint('[ApiClient] toggleAvailabilityMe error on $host: $e');
      }
    }
    return true;
  }

  /// Fetch Rajesh Kumar's live profile & Digital Skill Passport from FastAPI
  Future<WorkerProfileModel> getRajeshProfile() async {
    final candidateHosts = AppConstants.candidateUrls;
    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('$host/api/v1/workers/profile/rajesh');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          return WorkerProfileModel.fromJson(jsonDecode(res.body));
        }
      } catch (e) {
        debugPrint('[ApiClient] getRajeshProfile error on $host: $e');
      }
    }
    return _defaultRajeshProfile();
  }

  /// Toggle availability state in DB
  Future<bool> toggleAvailability(String workerId, bool isAvailable) async {
    final uri = Uri.parse('$baseUrl/api/v1/workers/$workerId/availability?is_available=$isAvailable');
    try {
      final res = await http.post(uri).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiClient.toggleAvailability error: $e');
      return true; // Optimistic update for demo reliability
    }
  }

  /// Accept an incoming job offer
  Future<bool> acceptOrder(String orderId) async {
    final uri = Uri.parse('$baseUrl/api/v1/orders/$orderId/accept');
    try {
      final res = await http.post(uri).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiClient.acceptOrder error: $e');
      return true;
    }
  }

  /// Mark worker is traveling to customer (worker_enroute)
  Future<bool> markEnroute(String orderId) async {
    final uri = Uri.parse('$baseUrl/api/v1/orders/$orderId/enroute');
    try {
      final res = await http.post(uri).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiClient.markEnroute error: $e');
      return true;
    }
  }

  /// Mark electrical inspection started (in_progress)
  Future<bool> startOrder(String orderId) async {
    final uri = Uri.parse('$baseUrl/api/v1/orders/$orderId/start');
    try {
      final res = await http.post(uri).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiClient.startOrder error: $e');
      return true;
    }
  }

  /// Complete job & trigger wallet credit
  Future<bool> completeOrder(String orderId) async {
    final uri = Uri.parse('$baseUrl/api/v1/orders/$orderId/complete');
    try {
      final res = await http.post(uri).timeout(const Duration(seconds: 6));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiClient.completeOrder error: $e');
      return true;
    }
  }

  /// Check active order for worker
  Future<JobOfferModel?> getWorkerActiveOrder(String workerId) async {
    final uri = Uri.parse('$baseUrl/api/v1/orders/worker/$workerId/active');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final data = jsonDecode(res.body);
        if (data != null) {
          return JobOfferModel.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('ApiClient.getWorkerActiveOrder error: $e');
    }
    return null;
  }

  /// Initialize Supabase Realtime channel subscription (Decision W-D07)
  void subscribeToRealtimeOffers({
    required String workerId,
    required Function(JobOfferModel) onNewOffer,
    required Function(String orderId, String status) onStatusUpdate,
  }) {
    try {
      final client = Supabase.instance.client;
      _orderSubscription = client
          .channel('public:orders:worker:$workerId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                final status = newRecord['status'] as String?;
                final orderId = newRecord['id'] as String? ?? '';
                final assignedWorker = newRecord['worker_id'] as String?;

                // Check if this is an incoming offer for Rajesh
                if ((assignedWorker == workerId || assignedWorker == null) &&
                    (status == 'matching' || status == 'offered' || status == 'accepted')) {
                  final offer = JobOfferModel(
                    orderId: orderId,
                    serviceId: newRecord['service_id'] as int? ?? 1,
                    serviceName: 'Electrician',
                    serviceNameTa: 'மின்சார பணியாளர்',
                    customerName: AppConstants.defaultCustomerName,
                    customerPhone: AppConstants.defaultCustomerPhone,
                    addressText: AppConstants.defaultCustomerAddress,
                    customerLat: AppConstants.defaultCustomerLat,
                    customerLng: AppConstants.defaultCustomerLng,
                    description: newRecord['description'] ??
                        'Switchboard sparking in living room when ceiling fan is turned on.',
                    status: status ?? 'offered',
                    totalAmount: (newRecord['final_amount'] as num?)?.toDouble() ?? 275.0,
                    platformCommission:
                        (newRecord['platform_commission'] as num?)?.toDouble() ?? 25.0,
                    workerPayout: (newRecord['worker_payout'] as num?)?.toDouble() ?? 250.0,
                    distanceKm: 1.8,
                    etaMinutes: 7,
                  );
                  onNewOffer(offer);
                }

                if (status != null) {
                  onStatusUpdate(orderId, status);
                }
              }
            },
          )
          .subscribe();
      debugPrint('Realtime channel subscribed on public:orders');
    } catch (e) {
      debugPrint('Supabase realtime init error: $e');
    }

    // Fallback polling every 4 seconds in case Realtime is blocked in local development
    _startFallbackPolling(workerId, onNewOffer);
  }

  void _startFallbackPolling(String workerId, Function(JobOfferModel) onNewOffer) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final active = await getWorkerActiveOrder(workerId);
      if (active != null && (active.status == 'offered' || active.status == 'accepted')) {
        onNewOffer(active);
      }
    });
  }

  void dispose() {
    _pollingTimer?.cancel();
    _orderSubscription?.unsubscribe();
  }

  WorkerProfileModel _defaultRajeshProfile() {
    return WorkerProfileModel(
      id: 'd9b3a0b1-4c12-4c28-98e3-0d6e8e883921',
      fullName: AppConstants.defaultWorkerName,
      phone: AppConstants.defaultWorkerPhone,
      kycStatus: 'verified',
      uan: AppConstants.defaultUan,
      primarySkillName: AppConstants.defaultTrade,
      primarySkillTa: AppConstants.defaultTradeTa,
      ratingAvg: 4.9,
      ratingCount: 142,
      reliabilityScore: 0.98,
      reliabilityPercentage: 98,
      jobsCompleted: 142,
      experienceYears: 3.2,
      earningsTotal: 54200.0,
      currentLat: AppConstants.defaultWorkerLat,
      currentLng: AppConstants.defaultWorkerLng,
      isAvailable: true,
      email: AppConstants.defaultWorkerEmail,
      secondarySkills: const ['AC Repair', 'Inverter Servicing'],
    );
  }

  List<WorkerJobItemModel> _fallbackWorkerJobs() {
    final now = DateTime.now();
    return [
      WorkerJobItemModel(
        id: 'ord-fallback-101',
        serviceName: 'Electrician',
        serviceNameTa: 'மின்சார பணியாளர்',
        customerName: 'Senthil Nathan',
        customerPhone: '+919876543210',
        addressText: 'Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai - 600017',
        customerLat: 13.0418,
        customerLng: 80.2341,
        description: 'Kitchen power socket sparking when microwave is turned on. Grounding wire check.',
        status: 'completed',
        scheduledType: 'immediate',
        finalAmount: 275.0,
        workerPayout: 250.0,
        paymentStatus: 'paid',
        rating: 5,
        reviewText: 'Arrived promptly in 8 minutes. Clean replacement and tested MCB trip threshold.',
        createdAt: now.subtract(const Duration(hours: 1)),
        completedAt: now.subtract(const Duration(minutes: 20)),
      ),
      WorkerJobItemModel(
        id: 'ord-fallback-102',
        serviceName: 'Electrician',
        serviceNameTa: 'மின்சார பணியாளர்',
        customerName: 'Meenakshi Sundaram',
        customerPhone: '+919876543290',
        addressText: '14, Venkatnarayana Rd, T. Nagar, Chennai - 600017',
        customerLat: 13.0402,
        customerLng: 80.2325,
        description: 'MCB main switch frequent tripping during peak AC load in master bedroom.',
        status: 'completed',
        scheduledType: 'immediate',
        finalAmount: 385.0,
        workerPayout: 350.0,
        paymentStatus: 'paid',
        rating: 5,
        reviewText: 'Identified loose busbar connection quickly and resolved heating issue.',
        createdAt: now.subtract(const Duration(hours: 3)),
        completedAt: now.subtract(const Duration(hours: 2)),
      ),
      WorkerJobItemModel(
        id: 'ord-fallback-103',
        serviceName: 'Electrician',
        serviceNameTa: 'மின்சார பணியாளர்',
        customerName: 'Anand Kumar',
        customerPhone: '+919876543288',
        addressText: '88, Eldams Rd, Alwarpet, Chennai - 600018',
        customerLat: 13.0335,
        customerLng: 80.2512,
        description: 'Living room chandelier and ceiling fan regulator installation.',
        status: 'completed',
        scheduledType: 'immediate',
        finalAmount: 385.0,
        workerPayout: 350.0,
        paymentStatus: 'paid',
        rating: 5,
        reviewText: 'Very experienced electrician. Clean installation with zero wall damage.',
        createdAt: now.subtract(const Duration(hours: 5)),
        completedAt: now.subtract(const Duration(hours: 4)),
      ),
      WorkerJobItemModel(
        id: 'ord-fallback-104',
        serviceName: 'Electrician',
        serviceNameTa: 'மின்சார பணியாளர்',
        customerName: 'Kavitha Raman',
        customerPhone: '+919876543277',
        addressText: '22, Burkit Rd, T. Nagar, Chennai - 600017',
        customerLat: 13.0380,
        customerLng: 80.2360,
        description: 'Ceiling fan bearing noise and speed drop capacitor replacement.',
        status: 'completed',
        scheduledType: 'immediate',
        finalAmount: 330.0,
        workerPayout: 300.0,
        paymentStatus: 'paid',
        rating: 4,
        reviewText: 'Fast replacement, fan runs silently at full speed now.',
        createdAt: now.subtract(const Duration(hours: 7)),
        completedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  WorkerWalletModel _fallbackWorkerWallet() {
    final now = DateTime.now();
    return WorkerWalletModel(
      workerId: _cachedWorkerId ?? 'd9b3a0b1-4c12-4c28-98e3-0d6e8e883921',
      availableBalance: 1450.0,
      todayEarnings: 1250.0,
      thisWeekEarnings: 6800.0,
      totalLifeEarnings: 54200.0,
      welfareCessTotal: 542.0, // 1% prototype contribution
      payoutBank: WorkerBankAccountModel(
        bankName: 'State Bank of India',
        accountNumberMasked: '•••• •••• 4892',
        ifsc: 'SBIN0000800',
        accountHolder: _cachedFullName ?? AppConstants.defaultWorkerName,
        statusLabel: 'Demo Linked Account',
      ),
      transactions: [
        WorkerTransactionModel(
          id: 'txn-001',
          type: 'JOB_PAYOUT',
          amount: 250.0,
          status: 'completed',
          reference: 'TXN-ORD-TN-774',
          description: 'Kitchen Power Socket & Earthing (T. Nagar)',
          createdAt: now.subtract(const Duration(minutes: 45)),
        ),
        WorkerTransactionModel(
          id: 'txn-002',
          type: 'JOB_PAYOUT',
          amount: 350.0,
          status: 'completed',
          reference: 'TXN-ORD-TN-773',
          description: 'Living Room Rewiring Inspection (Alwarpet)',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        WorkerTransactionModel(
          id: 'txn-003',
          type: 'JOB_PAYOUT',
          amount: 350.0,
          status: 'completed',
          reference: 'TXN-ORD-TN-772',
          description: 'MCB Main Switch Trip & Breaker Fix (T. Nagar)',
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
        WorkerTransactionModel(
          id: 'txn-004',
          type: 'JOB_PAYOUT',
          amount: 300.0,
          status: 'completed',
          reference: 'TXN-ORD-TN-771',
          description: 'Ceiling Fan Installation & Wiring (T. Nagar)',
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
        WorkerTransactionModel(
          id: 'txn-005',
          type: 'BANK_TRANSFER',
          amount: 1000.0,
          status: 'completed',
          reference: 'IMPS-TN-9821034',
          description: 'Instant Settlement to State Bank of India •••• 4892 (Demo)',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        WorkerTransactionModel(
          id: 'txn-006',
          type: 'JOB_PAYOUT',
          amount: 1200.0,
          status: 'completed',
          reference: 'TXN-ORD-TN-750',
          description: 'Weekly Cumulative Settlements (Batch #41)',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
  }
}
