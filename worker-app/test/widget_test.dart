import 'package:flutter_test/flutter_test.dart';
import 'package:worker_app/main.dart';

void main() {
  testWidgets('Worker App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MakkalSevaiWorkerApp());
    expect(find.byType(MakkalSevaiWorkerApp), findsOneWidget);
  });
}
