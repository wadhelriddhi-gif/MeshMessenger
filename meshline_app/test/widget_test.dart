import 'package:flutter_test/flutter_test.dart';
import 'package:meshline_app/main.dart';

void main() {
  testWidgets('App starts and shows the Setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MeshlineApp());
    expect(find.text('Meshline'), findsOneWidget);
  });
}