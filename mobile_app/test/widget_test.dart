import 'package:finpat_mobile/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows setup screen when config is missing', (tester) async {
    await tester.pumpWidget(const FinPatApp(isConfigured: false));
    expect(find.text('FinPat Setup'), findsOneWidget);
  });
}
