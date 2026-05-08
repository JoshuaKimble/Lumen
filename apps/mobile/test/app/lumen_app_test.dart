import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';

void main() {
  testWidgets('renders the journal home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumenApp()));
    await tester.pumpAndSettle();

    expect(find.text('Lumen'), findsOneWidget);
    expect(find.text('Welcome to Lumen'), findsOneWidget);
    expect(find.text('A quiet place for daily reflection.'), findsOneWidget);
  });
}
