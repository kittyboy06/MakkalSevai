import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/features/home/home_screen.dart';
import 'package:customer_app/features/booking/booking_tab_screen.dart';
import 'package:customer_app/features/activity/activity_tab_screen.dart';
import 'package:customer_app/features/profile/profile_tab_screen.dart';
import 'package:customer_app/features/auth/login_screen.dart';
import 'package:customer_app/core/theme/app_theme.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );
  }

  group('Phase 4 Customer App Tabs Tests', () {
    testWidgets('HomeScreen renders 4 navigation tabs and switches between them', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const HomeScreen()));
      await tester.pump();

      // Verify 4 bottom navigation items
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Bookings tab (index 1)
      await tester.tap(find.text('Bookings'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BookingTabScreen), findsOneWidget);

      // Tap on Activity tab (index 2)
      await tester.tap(find.text('Activity'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ActivityTabScreen), findsOneWidget);

      // Tap on Profile tab (index 3)
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ProfileTabScreen), findsOneWidget);
    });

    testWidgets('BookingTabScreen renders GPS card, trade categories, and dispatch controls', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const BookingTabScreen()));
      await tester.pump();

      expect(find.text('Book a Service'), findsOneWidget);
      expect(find.text('Current Device Location'), findsOneWidget);
      expect(find.text('Select Trade Category'), findsOneWidget);
      expect(find.text('Dispatch Urgency'), findsOneWidget);
      expect(find.text('Describe the Issue'), findsOneWidget);
    });

    testWidgets('ActivityTabScreen renders active and history tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ActivityTabScreen()));
      await tester.pump();

      expect(find.text('Activity & Orders'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('ProfileTabScreen renders verified citizen badge and civic settings', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const ProfileTabScreen()));
      await tester.pump();

      expect(find.text('Citizen Profile'), findsOneWidget);
      expect(find.text('Current Device Location'), findsOneWidget);
      expect(find.text('Your Platform Activity'), findsOneWidget);
      expect(find.text('Saved Addresses'), findsOneWidget);
      expect(find.text('Civic Settings & Assistance'), findsOneWidget);
      expect(find.textContaining('1800-425-7825'), findsOneWidget);
      expect(find.text('Sign Out / Switch Account'), findsOneWidget);
    });

    testWidgets('LoginScreen renders email input, password, and sign-in button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pump();

      expect(find.text('Citizen Sign In'), findsOneWidget);
      expect(find.text('Email Address *'), findsOneWidget);
      expect(find.text('Password *'), findsOneWidget);
      expect(find.text('Demo: senthil.nathan@example.com'), findsOneWidget);
      expect(find.text('Sign In'), findsNWidgets(2)); // Tab + Button
      expect(find.text('Sign Up'), findsOneWidget); // Tab
      expect(find.text('GOVERNMENT OF TAMIL NADU VERIFIED PLATFORM'), findsOneWidget);

      // Switch to Sign Up tab
      await tester.tap(find.text('Sign Up'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Create Citizen Account'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Confirm Password *'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });
}
