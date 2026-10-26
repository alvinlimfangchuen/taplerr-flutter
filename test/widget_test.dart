import 'package:flutter_test/flutter_test.dart';

import 'package:taplerr/main.dart';

void main() {
  testWidgets('App launches to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
