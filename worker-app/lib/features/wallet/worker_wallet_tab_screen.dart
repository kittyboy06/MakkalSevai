import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/worker_models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';

class WorkerWalletTabScreen extends StatefulWidget {
  final WorkerProfileModel worker;

  const WorkerWalletTabScreen({
    super.key,
    required this.worker,
  });

  @override
  State<WorkerWalletTabScreen> createState() => _WorkerWalletTabScreenState();
}

class _WorkerWalletTabScreenState extends State<WorkerWalletTabScreen> {
  final ApiClient _apiClient = ApiClient();
  WorkerWalletModel? _wallet;
  bool _isLoading = true;
  bool _isPayoutLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final wallet = await _apiClient.getWorkerWalletMe();
    if (mounted) {
      setState(() {
        _wallet = wallet;
        _isLoading = false;
      });
    }
  }

  void _showPayoutDialog() {
    if (_wallet == null || _wallet!.availableBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance to request bank transfer.'),
          backgroundColor: AppTheme.crimsonAlert,
        ),
      );
      return;
    }

    final amountController = TextEditingController(
      text: _wallet!.availableBalance.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance, color: AppTheme.emeraldDark, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Bank Transfer',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.slateNavy),
                        ),
                        Text(
                          'Transfer to ',
                          style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.slateLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.slateNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Instant payout processed via IMPS. Max available: ₹${_wallet!.availableBalance.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.slateNavy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount in INR (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final entered = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (entered <= 0 || entered > _wallet!.availableBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an amount within available balance.'),
                          backgroundColor: AppTheme.crimsonAlert,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isPayoutLoading = true);
                    final updated = await _apiClient.requestPayoutMe(entered);
                    if (mounted) {
                      setState(() {
                        _wallet = updated;
                        _isPayoutLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('₹${entered.toStringAsFixed(0)} successfully transferred to ${_wallet!.bankAccount.bankName}!'),
                          backgroundColor: AppTheme.emeraldDark,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm Instant Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          'Wallet & Settlements',
          style: textTheme.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.slateNavy),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadWallet();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emeraldOnline))
          : RefreshIndicator(
              onRefresh: _loadWallet,
              color: AppTheme.emeraldOnline,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Available Balance Hero Card
                    _buildBalanceCard(textTheme),
                    const SizedBox(height: 16),

                    // 2. Earnings Breakdown Metrics
                    _buildMetricsRow(textTheme),
                    const SizedBox(height: 16),

                    // 3. Tamil Nadu Welfare Board Transparency Card (Decision W-D13)
                    _buildWelfareCard(textTheme),
                    const SizedBox(height: 16),

                    // 4. Linked Bank Account Card (Decision W-D13)
                    _buildBankCard(textTheme),
                    const SizedBox(height: 16),

                    // 5. Transaction History Ledger
                    _buildTransactionsSection(textTheme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.slateNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.slateNavy.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldOnline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: AppTheme.emeraldOnline, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      'Ready to Transfer',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppTheme.emeraldOnline,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${_wallet?.availableBalance.toStringAsFixed(0) ?? "0"}',
            style: textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isPayoutLoading ? null : _showPayoutDialog,
              icon: _isPayoutLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.account_balance, color: AppTheme.slateNavy),
              label: Text(
                _isPayoutLoading ? 'Processing...' : 'Request Bank Transfer',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.slateNavy),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricBox(
            textTheme,
            'TODAY',
            '₹${_wallet?.todayEarnings.toStringAsFixed(0) ?? "0"}',
            Icons.today,
            AppTheme.emeraldDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricBox(
            textTheme,
            'THIS WEEK',
            '₹${_wallet?.weekEarnings.toStringAsFixed(0) ?? "0"}',
            Icons.date_range,
            AppTheme.slateNavy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricBox(
            textTheme,
            'LIFETIME',
            '₹${((_wallet?.lifetimeEarnings ?? 0) / 1000).toStringAsFixed(1)}k',
            Icons.military_tech,
            AppTheme.saffronUrgency,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox(TextTheme textTheme, String title, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
              Text(
                title,
                style: textTheme.labelSmall?.copyWith(fontSize: 10, color: AppTheme.slateMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slateNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildWelfareCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.saffronSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.saffronUrgency.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.saffronUrgency, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.welfareBoardLabel,
                  style: textTheme.labelLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slateNavy),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cumulative Welfare Fund Track: ₹${_wallet?.welfareCessTotal.toStringAsFixed(2) ?? "0.00"}',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(TextTheme textTheme) {
    final bank = _wallet?.payoutBank;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.slateLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance, color: AppTheme.slateNavy, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bank?.bankName ?? 'State Bank of India',
                      style: textTheme.labelLarge?.copyWith(fontSize: 13, color: AppTheme.slateNavy),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.slateLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bank?.statusLabel ?? AppConstants.defaultBankLabel,
                        style: const TextStyle(fontSize: 9, color: AppTheme.slateNavy, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${bank?.accountNumberMasked ?? "•••• 4892"} • IFSC: ${bank?.ifscCode ?? "SBIN0000800"}',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(TextTheme textTheme) {
    final txs = _wallet?.transactions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRANSACTION LEDGER',
              style: textTheme.labelSmall?.copyWith(letterSpacing: 0.8, color: AppTheme.slateMuted),
            ),
            Text(
              '${txs.length} entries',
              style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTheme.slateMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (txs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slateBorder),
            ),
            child: const Center(
              child: Text('No transactions recorded yet.', style: TextStyle(color: AppTheme.slateMuted)),
            ),
          )
        else
          ...txs.map((t) => _buildTransactionRow(textTheme, t)),
      ],
    );
  }

  Widget _buildTransactionRow(TextTheme textTheme, WorkerTransactionModel t) {
    final isPayout = t.type == 'JOB_PAYOUT';
    final isBank = t.type == 'BANK_TRANSFER';
    final sign = isPayout ? '+' : '-';
    final color = isPayout ? AppTheme.emeraldDark : (isBank ? AppTheme.slateNavy : AppTheme.saffronUrgency);
    final icon = isPayout ? Icons.arrow_downward : (isBank ? Icons.arrow_upward : Icons.shield);
    final dateStr = DateFormat('dd MMM, hh:mm a').format(t.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slateBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description ?? (isPayout ? 'Job Completed Payout' : 'Bank Transfer'),
                  style: textTheme.labelLarge?.copyWith(fontSize: 12, color: AppTheme.slateNavy),
                ),
                Text(
                  '$dateStr • ${t.status}',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 10, color: AppTheme.slateMuted),
                ),
              ],
            ),
          ),
          Text(
            '$sign₹${t.amount.toStringAsFixed(0)}',
            style: textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
