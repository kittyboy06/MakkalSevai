import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../models/order_models.dart';
import '../tracking/tracking_screen.dart';

class ActivityTabScreen extends StatefulWidget {
  final VoidCallback? onGoToBooking;

  const ActivityTabScreen({super.key, this.onGoToBooking});

  @override
  State<ActivityTabScreen> createState() => _ActivityTabScreenState();
}

class _ActivityTabScreenState extends State<ActivityTabScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  List<OrderModel> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _api.getOrdersMe();
    if (mounted) {
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> get _activeOrders {
    return _allOrders.where((o) =>
      o.status == 'matching' ||
      o.status == 'offered' ||
      o.status == 'accepted' ||
      o.status == 'worker_enroute' ||
      o.status == 'in_progress'
    ).toList();
  }

  List<OrderModel> get _pastOrders {
    return _allOrders.where((o) =>
      o.status == 'completed' ||
      o.status == 'cancelled'
    ).toList();
  }

  void _showRatingDialog(OrderModel order) {
    int selectedStars = 5;
    final textController = TextEditingController(text: 'Prompt, professional, and courteous service.');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.star_rounded, color: AppColors.secondary, size: 28),
                SizedBox(width: 8),
                Text('Rate Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How was the work by ${order.matchedWorker?.fullName ?? 'the assigned worker'} for ${order.serviceName ?? 'this service'}?',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppColors.secondary,
                            size: 34,
                          ),
                          onPressed: () {
                            setDialogState(() => selectedStars = starValue);
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Share feedback on punctuality, safety & skill...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '✓ Your rating dynamically updates the worker\'s Digital Skill Passport.',
                    style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogCtx);
                  await _api.submitRating(
                    orderId: order.id,
                    stars: selectedStars,
                    reviewText: textController.text.trim(),
                  );
                  if (!mounted) return;
                  _loadOrders();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Rating recorded on worker Skill Passport.'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Submit Rating'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInvoiceDialog(OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dateStr = order.createdAt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal())
            : 'Recent';
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Service Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Text('Order ID: ${order.id}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text('Date: $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.serviceName ?? 'Diagnostic Service', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('₹${order.workerPayout.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Civic Platform & Safety Levy', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('₹25.00', style: TextStyle(fontSize: 13)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount Paid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('₹${order.finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emeraldContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: AppColors.onEmeraldContainer, size: 18),
                    SizedBox(width: 8),
                    Text('Payment Verified & Settled via Razorpay Test Escrow', style: TextStyle(fontSize: 11, color: AppColors.onEmeraldContainer, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity & Orders', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Active (${_activeOrders.length})'),
            Tab(text: 'History (${_pastOrders.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadOrders,
              color: AppColors.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveOrdersView(),
                  _buildPastOrdersView(),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveOrdersView() {
    final active = _activeOrders;
    if (active.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Active Service Requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'When you request a verified tradesperson, live updates and dispatch progress will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onGoToBooking,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Book a Service Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, idx) {
        final order = active[idx];
        return _buildActiveOrderCard(order);
      },
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    Color statusColor = AppColors.secondary;
    String statusLabel = 'MATCHING';
    if (order.status == 'accepted') {
      statusColor = AppColors.primary;
      statusLabel = 'TRADESPERSON ACCEPTED';
    } else if (order.status == 'worker_enroute') {
      statusColor = Colors.orange.shade800;
      statusLabel = 'WORKER EN ROUTE';
    } else if (order.status == 'in_progress') {
      statusColor = AppColors.emerald;
      statusLabel = 'JOB IN PROGRESS';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${order.finalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.serviceName ?? 'Service Request',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.scheduledType.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
                if (order.description != null && order.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.description!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),

                // Matched Worker Card
                if (order.matchedWorker != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            order.matchedWorker!.fullName.substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order.matchedWorker!.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.emerald),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 13, color: AppColors.secondary),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${order.matchedWorker!.ratingAvg} (${order.matchedWorker!.jobsCompleted} jobs)',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${order.matchedWorker!.fullName} (${order.matchedWorker!.phone ?? '+919876543211'})...')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Single Source of Truth: Button to open TrackingScreen
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackingScreen(
                            order: order,
                            serviceName: order.serviceName ?? 'Service',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Track Live on Map', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrdersView() {
    final past = _pastOrders;
    if (past.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No Past Orders',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              SizedBox(height: 4),
              Text(
                'Completed service invoices and ratings will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: past.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final order = past[idx];
        final isCompleted = order.status == 'completed';
        final dateStr = order.createdAt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!.toLocal())
            : 'Recent';

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.emerald.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCompleted ? AppColors.emerald : Colors.red,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.serviceName ?? 'Completed Service',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '₹${order.finalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    order.matchedWorker != null
                        ? 'Served by ${order.matchedWorker!.fullName}'
                        : 'Completed by Verified Tradesperson',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showInvoiceDialog(order),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const Divider(height: 12),
              // Rating row
              if (order.ratingStars != null && order.ratingStars! > 0) ...[
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < order.ratingStars! ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${order.ratingStars}.0 Rated',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ] else if (isCompleted) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRatingDialog(order),
                    icon: const Icon(Icons.star_outline_rounded, size: 16, color: AppColors.secondary),
                    label: const Text('Rate This Service', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
