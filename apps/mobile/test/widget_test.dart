import 'package:flutter_test/flutter_test.dart';
import 'package:collector_mobile/main.dart';

void main() {
  testWidgets('application starts and imports shared schema', (tester) async {
    await tester.pumpWidget(const CollectorApp());
    expect(find.text('Dataset Collector'), findsOneWidget);
    expect(supportedSchemaVersion, 1);
  });
}
