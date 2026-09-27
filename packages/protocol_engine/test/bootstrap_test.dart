import 'package:flutter_test/flutter_test.dart';
import 'package:protocol_engine/protocol_engine.dart';

void main() {
  test('shared contract loads', () {
    expect(packageSchemaVersion, 1);
  });
}
