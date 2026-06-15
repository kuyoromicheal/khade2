import 'package:flutter_test/flutter_test.dart';
import 'package:khade_app/main.dart';

void main() {
  testWidgets('App launches splash screen', (tester) async {
    await tester.pumpWidget(const KhadeApp());
    expect(find.text('khade'), findsOneWidget);
  });
}
