import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/worker_models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../job/active_job_screen.dart';

class WorkerJobsTabScreen extends StatefulWidget {
  final WorkerProfileModel worker;

  const WorkerJobsTabScreen({
    super.key,
    required this.worker,
  });

  @override
  State<WorkerJobsTabScreen> createState() => _WorkerJobsTabScreenState();
}

class _WorkerJobsTabScreenState extends State<WorkerJobsTabScreen> {
  final ApiClient _apiClient = ApiClient();
  List<WorkerJobItemModel> _jobs = [];
  bool _isLoading = true;
  String _selectedFilter = 'Active'; // 'Active', 'Completed', 'All'

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final jobs = await _apiClient.getWorkerJobsMe();
    if (mounted) {
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    }
  }

  List<WorkerJobItemModel> get _filteredJobs {
    if (_selectedFilter == 'Active') {
      return _jobs.where((j) => j.isActive).toList();
    } else if (_selectedFilter == 'Completed') {
      return _jobs.where((j) => j.isCompleted).toList();
    }
    return _jobs;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.slateCanvas,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'My Jobs & Dispatches',
          style: textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.slateNavy),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadJobs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Filter Chips Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('Active', _jobs.where((j) => j.isActive).length),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', _jobs.where((j) => j.isCompleted).length),
                const SizedBox(width: 8),
                _buildFilterChip('All', _jobs.length),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.slateBorder),

          // 2. Jobs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldOnline))
                : RefreshIndicator(
                    onRefresh: _loadJobs,
                    color: AppTheme.emeraldOnline,
                    child: _filteredJobs.isEmpty
                        ? _buildEmptyState(textTheme)
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredJobs.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final job = _filteredJobs[idx];
                              return job.isActive
                                  ? _buildActiveJobCard(textTheme, job)
                                  : _buildCompletedJobCard(textTheme, job);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, int count) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text('$filter ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
      selectedColor: AppTheme.slateNavy,
      backgroundColor: AppTheme.slateLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.slateNavy,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          _selectedFilter == 'Active' ? Icons.check_circle_outline : Icons.assignment_outlined,
          size: 64,
          color: AppTheme.slateMuted,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            _selectedFilter == 'Active' ? 'No active dispatches right now' : 'No jobs found',
            style: textTheme.labelLarge?.copyWith(fontSize: 16, color: AppTheme.slateNavy),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _selectedFilter == 'Active'
                ? 'Stay online on Dashboard to receive nearby radar requests.'
                : 'Completed jobs will appear here with ratings and settlements.',
            style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveJobCard(TextTheme textTheme, WorkerJobItemModel job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.emeraldDark.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emeraldOnline.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar, color: AppTheme.emeraldDark, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      job.status.toUpperCase().replaceAll('_', ' '),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppTheme.emeraldDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '₹${job.workerPayout.toStringAsFixed(0)}',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppTheme.emeraldDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job.serviceName,
            style: textTheme.labelLarge?.copyWith(fontSize: 16, color: AppTheme.slateNavy),
          ),
          if (job.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              job.description,
              style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.slateBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppTheme.slateMuted),
              const SizedBox(width: 6),
              Text(job.customerName, style: textTheme.labelMedium?.copyWith(color: AppTheme.slateNavy)),
              const Spacer(),
              Text(
                job.customerPhone,
                style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.slateMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job.addressText,
                  style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                final offer = JobOfferModel(
                  orderId: job.id,
                  serviceId: job.serviceId ?? 1,
                  serviceName: job.serviceName,
                  serviceNameTa: job.serviceNameTa ?? 'மின்சார பணியாளர்',
                  customerName: job.customerName,
                  customerPhone: job.customerPhone,
                  addressText: job.addressText,
                  customerLat: job.customerLat ?? 13.0418,
                  customerLng: job.customerLng ?? 80.2341,
                  description: job.description,
                  status: job.status,
                  totalAmount: job.finalAmount,
                  platformCommission: 25.0,
                  workerPayout: job.workerPayout,
                  distanceKm: 1.8,
                  etaMinutes: 7,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => ActiveJobScreen(
                      offer: offer,
                      worker: widget.worker,
                    ),
                  ),
                ).then((_) => _loadJobs());
              },
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Resume Active Job Screen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.slateNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobCard(TextTheme textTheme, WorkerJobItemModel job) {
    final dateStr = DateFormat('dd MMM yyyy • hh:mm a').format(job.completedAt ?? job.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slateBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.emeraldDark, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceName,
                      style: textTheme.labelLarge?.copyWith(fontSize: 14, color: AppTheme.slateNavy),
                    ),
                    Text(
                      dateStr,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${job.workerPayout.toStringAsFixed(0)}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emeraldDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.slateLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SETTLED',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppTheme.slateNavy,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            job.description,
            style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateNavy),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.slateBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: AppTheme.slateMuted),
              const SizedBox(width: 4),
              Text(
                job.customerName,
                style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.slateMuted),
              ),
              const Spacer(),
              if (job.rating != null) ...[
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      Icons.star,
                      size: 14,
                      color: i < job.rating! ? Colors.amber : AppTheme.slateLight,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${job.rating}.0',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slateNavy,
                  ),
                ),
              ],
            ],
          ),
          if (job.reviewText != null && job.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.slateLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.format_quote, size: 14, color: AppTheme.slateMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.reviewText!,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
