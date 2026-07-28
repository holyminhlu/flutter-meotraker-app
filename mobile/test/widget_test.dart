import 'package:flutter_test/flutter_test.dart';
import 'package:meo_traker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders login when logged out', (tester) async {
    await tester.pumpWidget(const MeoTrakerApp());
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
