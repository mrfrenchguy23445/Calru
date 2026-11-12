import 'package:calru/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches the Calru overview', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CalruApp());
    await tester.pumpAndSettle();

    expect(find.text('Financial overview'), findsOneWidget);
    expect(find.text('CALRU'), findsOneWidget);
    expect(find.text('No financial records yet. Add a calculation to start tracking.'), findsOneWidget);
  });
}
