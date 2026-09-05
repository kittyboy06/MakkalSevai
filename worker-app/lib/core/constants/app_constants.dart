import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'MakkalSevai Worker';
  static const String tagline = 'Verified Tradesperson Partner App';
  static const String taglineTa = 'சரிபார்க்கப்பட்ட உள்ளூர் தொழிலாளர் செயலி';

  // FastAPI Backend URL candidates:
  // 1. LAN IP for physical Android phones on the same WiFi (192.168.1.2)
  // 2. 10.0.2.2 for Android Studio Emulator
  // 3. localhost for Web / Windows
  static const String lanHost = '192.168.1.2';

  static List<String> get candidateUrls => [
    'http://$lanHost:8001',
    if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:8001',
    'http://localhost:8001',
  ];

  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:8001';
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://$lanHost:8001';
    }
    return 'http://localhost:8001';
  }

  // Supabase Direct (for public realtime channel updates)
  static const String supabaseUrl = 'https://ulplesjbvblspibdpspr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVscGxlc2pidmJsc3BpYmRwc3ByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1MTk3MzYsImV4cCI6MjEwNDA5NTczNn0.Z1bpUbgf8uJtGepPe74zpjB42PHujzXvnLLCe-D5W7U';

  // Demo Worker Persona: Rajesh Kumar (Senior Electrician, T. Nagar)
  static const String defaultWorkerName = 'Rajesh Kumar';
  static const String defaultWorkerPhone = '+919876543211';
  static const String defaultTrade = 'Electrician';
  static const String defaultTradeTa = 'மின்சார பணியாளர்';
  static const String defaultUan = 'UAN-TN-2026-88392';
  static const String defaultWorkerEmail = 'rajesh.kumar@example.com';
  static const double defaultWorkerLat = 13.0450;
  static const double defaultWorkerLng = 80.2380;

  // Demo Customer Coordinates: Senthil Nathan (Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar)
  static const String defaultCustomerName = 'Senthil Nathan';
  static const String defaultCustomerPhone = '+919876543210';
  static const String defaultCustomerAddress =
      'Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai - 600017';
  static const double defaultCustomerLat = 13.0418;
  static const double defaultCustomerLng = 80.2341;

  // Honest Prototype Labels (Decision W-D13)
  static const String welfareBoardLabel = 'Worker Welfare Contribution (Prototype calculation: 1%)';
  static const String welfareBoardLabelTa = 'தொழிலாளர் நல நிதி பங்களிப்பு (மாதிரி கணக்கீடு: 1%)';
  static const String defaultBankAccount = 'State Bank of India •••• 4892';
  static const String defaultBankLabel = 'Demo Linked Account';
}
