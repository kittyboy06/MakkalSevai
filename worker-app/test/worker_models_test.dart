import 'package:flutter_test/flutter_test.dart';
import 'package:worker_app/core/models/worker_models.dart';

void main() {
  group('Worker Models Test Suite', () {
    test('WorkerJobItemModel parses JSON correctly with active/completed status', () {
      final jsonActive = {
        'id': 'ord-test-001',
        'service_id': 1,
        'service_name': 'Electrician',
        'service_name_ta': 'மின்சார பணியாளர்',
        'customer_name': 'Priya S.',
        'customer_phone': '+919876543210',
        'address_text': '14, North Usman Rd, T. Nagar, Chennai',
        'customer_lat': 13.0418,
        'customer_lng': 80.2341,
        'description': 'Main breaker tripping constantly',
        'status': 'in_progress',
        'final_amount': 350.0,
        'worker_payout': 325.0,
        'payment_status': 'paid',
        'created_at': '2026-09-05T10:00:00Z',
      };

      final job = WorkerJobItemModel.fromJson(jsonActive);
      expect(job.id, 'ord-test-001');
      expect(job.isActive, isTrue);
      expect(job.isCompleted, isFalse);
      expect(job.workerPayout, 325.0);

      final jsonCompleted = {
        'id': 'ord-test-002',
        'service_name': 'Plumber',
        'customer_name': 'Karthik N.',
        'customer_phone': '+919876543212',
        'address_text': '22 Venkatnarayana Rd, Chennai',
        'description': 'Tap leak repair',
        'status': 'completed',
        'final_amount': 250.0,
        'worker_payout': 225.0,
        'rating': 5,
        'review_text': 'Very prompt and polite service.',
        'created_at': '2026-09-05T09:00:00Z',
      };

      final completedJob = WorkerJobItemModel.fromJson(jsonCompleted);
      expect(completedJob.isActive, isFalse);
      expect(completedJob.isCompleted, isTrue);
      expect(completedJob.rating, 5);
      expect(completedJob.reviewText, contains('prompt'));
    });

    test('WorkerWalletModel and WorkerBankAccountModel parse correctly', () {
      final jsonWallet = {
        'worker_id': 'w-rajesh-01',
        'available_balance': 1250.0,
        'today_earnings': 750.0,
        'this_week_earnings': 4200.0,
        'total_life_earnings': 48500.0,
        'welfare_cess_total': 485.0,
        'payout_bank': {
          'bank_name': 'State Bank of India',
          'account_number_masked': '•••• •••• 4892',
          'ifsc': 'SBIN0000800',
          'account_holder': 'Rajesh Kumar',
          'status_label': 'Demo Linked Account',
        },
        'transactions': [
          {
            'id': 'tx-001',
            'type': 'JOB_PAYOUT',
            'amount': 250.0,
            'status': 'completed',
            'description': 'Direct settlement for Ceiling Fan Repair',
            'created_at': '2026-09-05T11:00:00Z',
          },
          {
            'id': 'tx-002',
            'type': 'BANK_TRANSFER',
            'amount': 500.0,
            'status': 'completed',
            'description': 'Instant Payout to SBI •••• 4892',
            'created_at': '2026-09-05T08:00:00Z',
          },
          {
            'id': 'tx-003',
            'type': 'WELFARE_CESS',
            'amount': 2.5,
            'status': 'completed',
            'description': '1% TN Gig Worker Welfare Board contribution',
            'created_at': '2026-09-05T11:00:00Z',
          },
        ],
      };

      final wallet = WorkerWalletModel.fromJson(jsonWallet);
      expect(wallet.workerId, 'w-rajesh-01');
      expect(wallet.availableBalance, 1250.0);
      expect(wallet.weekEarnings, 4200.0);
      expect(wallet.lifetimeEarnings, 48500.0);
      expect(wallet.welfareCessTotal, 485.0);
      expect(wallet.bankAccount.bankName, 'State Bank of India');
      expect(wallet.bankAccount.ifscCode, 'SBIN0000800');
      expect(wallet.transactions.length, 3);
      expect(wallet.transactions[0].type, 'JOB_PAYOUT');
      expect(wallet.transactions[1].type, 'BANK_TRANSFER');
      expect(wallet.transactions[2].type, 'WELFARE_CESS');
    });
  });
}
