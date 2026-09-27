import 'package:flutter_test/flutter_test.dart';
import 'package:experiment_models/experiment_models.dart';

void main() {
  test('shared contract loads', () {
    expect(packageSchemaVersion, 1);
  });
}
