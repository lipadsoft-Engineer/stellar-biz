import 'package:flutter_test/flutter_test.dart';
import 'package:sole_proprietor/app/app.dart';

void main() {
  testWidgets('dashboard shows profit and main navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SoleNoteApp());

    expect(find.text('Your business, at a glance'), findsOneWidget);
    expect(find.text('NET PROFIT TODAY'), findsOneWidget);
    expect(find.text('KES 4,860'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });
}
