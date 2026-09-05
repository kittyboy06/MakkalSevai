import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/worker_models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../earnings/completion_payout_screen.dart';

class ActiveJobScreen extends StatefulWidget {
  final JobOfferModel offer;
  final WorkerProfileModel worker;

  const ActiveJobScreen({
    super.key,
    required this.offer,
    required this.worker,
  });

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();

  // Order State Machine: 'accepted' -> 'worker_enroute' -> 'in_progress' -> 'completed'
  // Per Decision W-D08: 'arrived' is handled as an interactive client UI sub-state
  String _orderState = 'accepted';
  bool _hasArrivedAtLocation = false;
  bool _isProcessingAction = false;
  int _elapsedWorkSeconds = 0;
  Timer? _workTimer;

  // Route coordinates between Worker and Customer in T. Nagar
  late final LatLng _workerPos;
  late final LatLng _customerPos;
  late final List<LatLng> _routePoints;

  @override
  void initState() {
    super.initState();
    _workerPos = LatLng(widget.worker.currentLat, widget.worker.currentLng);
    _customerPos = LatLng(widget.offer.customerLat, widget.offer.customerLng);

    // Realistic road trajectory through T. Nagar streets
    _routePoints = [
      _workerPos,
      LatLng(13.0442, 80.2372),
      LatLng(13.0435, 80.2360),
      LatLng(13.0425, 80.2350),
      _customerPos,
    ];
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    super.dispose();
  }

  void _startWorkTimer() {
    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedWorkSeconds++;
        });
      }
    });
  }

  String _formatTimer(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _handlePrimaryAction() async {
    setState(() {
      _isProcessingAction = true;
    });

    try {
      if (_orderState == 'accepted') {
        // Step 1: Worker marks enroute -> broadcasts to Customer App
        await _apiClient.markEnroute(widget.offer.orderId);
        if (mounted) {
          setState(() {
            _orderState = 'worker_enroute';
            _isProcessingAction = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enroute! Customer notified with live map location.'),
              backgroundColor: AppTheme.slateNavy,
            ),
          );
        }
      } else if (_orderState == 'worker_enroute' && !_hasArrivedAtLocation) {
        // Step 2: Worker arrives at location (Decision W-D08: Client UI state event)
        setState(() {
          _hasArrivedAtLocation = true;
          _isProcessingAction = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrived at customer flat. Verify doorstep OTP to start.'),
            backgroundColor: AppTheme.emeraldDark,
          ),
        );
      } else if (_hasArrivedAtLocation && _orderState == 'worker_enroute') {
        // Step 3: Start work -> triggers backend in_progress
        await _apiClient.startOrder(widget.offer.orderId);
        _startWorkTimer();
        if (mounted) {
          setState(() {
            _orderState = 'in_progress';
            _isProcessingAction = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Work started! Timer running. Stay safe.'),
              backgroundColor: AppTheme.emeraldDark,
            ),
          );
        }
      } else if (_orderState == 'in_progress') {
        // Step 4: Complete Job -> triggers payment & Skill Passport increment
        _workTimer?.cancel();
        await _apiClient.completeOrder(widget.offer.orderId);
        if (mounted) {
          setState(() {
            _orderState = 'completed';
            _isProcessingAction = false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => CompletionPayoutScreen(
                offer: widget.offer,
                worker: widget.worker,
                workDurationText: _formatTimer(_elapsedWorkSeconds),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Action error: $e');
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  void _callCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling customer ${widget.offer.customerName} (${widget.offer.customerPhone})...'),
        backgroundColor: AppTheme.emeraldDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen OpenStreetMap view
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                (_workerPos.latitude + _customerPos.latitude) / 2,
                (_workerPos.longitude + _customerPos.longitude) / 2,
              ),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.makkalsevai.worker_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: AppTheme.slateNavy,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Worker Marker
                  Marker(
                    point: _workerPos,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.slateNavy,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
                    ),
                  ),
                  // Customer Destination Marker
                  Marker(
                    point: _customerPos,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.crimsonAlert,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Bar: Customer Card + Call Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.slateBorder, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.slateLight,
                          child: const Icon(Icons.person, color: AppTheme.slateNavy),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.offer.customerName,
                                  style: textTheme.labelLarge?.copyWith(fontSize: 15, color: AppTheme.slateNavy)),
                              Text(widget.offer.addressText,
                                  style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _callCustomer,
                          icon: const Icon(Icons.call, color: AppTheme.emeraldDark),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.emeraldSurface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Navigation Instruction Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.slateNavy,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.turn_left, color: AppTheme.saffronUrgency, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasArrivedAtLocation
                                ? '📍 Arrived at Flat 4B, Shanti Nilayam'
                                : 'In 400m, turn left on 12th Cross St',
                            style: textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        Text(
                          _hasArrivedAtLocation ? 'AT DOOR' : '6m (1.8km)',
                          style: textTheme.labelSmall?.copyWith(color: AppTheme.saffronUrgency),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Action Sheet (Thumb Zone)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppTheme.slateBorder, width: 2),
                  left: BorderSide(color: AppTheme.slateBorder, width: 1.5),
                  right: BorderSide(color: AppTheme.slateBorder, width: 1.5),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // State status pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _orderState == 'in_progress' ? AppTheme.emeraldSurface : AppTheme.slateLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _orderState == 'in_progress'
                              ? '⚡ WORK IN PROGRESS • ${_formatTimer(_elapsedWorkSeconds)}'
                              : _hasArrivedAtLocation
                                  ? 'DOORSTEP ARRIVAL'
                                  : _orderState == 'worker_enroute'
                                      ? 'ON THE WAY'
                                      : 'JOB ACCEPTED',
                          style: textTheme.labelSmall?.copyWith(
                            color: _orderState == 'in_progress' ? AppTheme.emeraldDark : AppTheme.slateNavy,
                          ),
                        ),
                      ),
                      Text(
                        'Payout: ₹${widget.offer.workerPayout.toStringAsFixed(0)}',
                        style: textTheme.labelLarge?.copyWith(color: AppTheme.emeraldDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Problem snippet
                  Text(
                    'Problem: ${widget.offer.description}',
                    style: textTheme.bodyLarge?.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  if (_hasArrivedAtLocation && _orderState != 'in_progress')
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.saffronSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.saffronUrgency.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pin, color: AppTheme.saffronUrgency, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Doorstep OTP verification matched with customer. Ready to inspect switchboard.',
                              style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateNavy),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Dominant State Action Button (56px minimum worksite height)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessingAction ? null : _handlePrimaryAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orderState == 'in_progress'
                            ? AppTheme.slateNavy
                            : AppTheme.emeraldOnline,
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessingAction
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _orderState == 'accepted'
                                      ? Icons.navigation
                                      : _orderState == 'worker_enroute' && !_hasArrivedAtLocation
                                          ? Icons.location_on
                                          : _hasArrivedAtLocation && _orderState != 'in_progress'
                                              ? Icons.play_arrow
                                              : Icons.task_alt,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _orderState == 'accepted'
                                      ? 'MARK ENROUTE TO CUSTOMER'
                                      : _orderState == 'worker_enroute' && !_hasArrivedAtLocation
                                          ? 'I HAVE ARRIVED AT LOCATION'
                                          : _hasArrivedAtLocation && _orderState != 'in_progress'
                                              ? 'START ELECTRICAL WORK'
                                              : 'COMPLETE JOB & GENERATE INVOICE',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
