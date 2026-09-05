import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'MakkalSevai';
  static const String tagline = 'Government Verified Local Skill Gig Marketplace';
  static const String taglineTa = 'அரசு சரிபார்க்கப்பட்ட நம்பகமான உள்ளூர் திறன்கள்';

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

  // Supabase Direct (for public read / realtime data)
  static const String supabaseUrl = 'https://ulplesjbvblspibdpspr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVscGxlc2pidmJsc3BpYmRwc3ByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1MTk3MzYsImV4cCI6MjEwNDA5NTczNn0.Z1bpUbgf8uJtGepPe74zpjB42PHujzXvnLLCe-D5W7U';

  // Demo Customer Location: Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai
  static const double defaultLat = 13.0418;
  static const double defaultLng = 80.2341;
  static const String defaultAddress = 'Flat 4B, Shanti Nilayam, 12th Cross St, T. Nagar, Chennai - 600017';
  static const String defaultLocationPill = 'T. Nagar, Chennai • Flat 4B';
  static const String defaultCustomerPhone = '+919876543210';
  static const String defaultCustomerName = 'Senthil Nathan';
}
