import 'package:flutter_test/flutter_test.dart';
import 'package:owadan/app.dart';

void main() {
  testWidgets('Owadan app starts', (tester) async {
    await tester.pumpWidget(const OwadanApp());
    expect(find.text('Owadan'), findsOneWidget);
  });
}
