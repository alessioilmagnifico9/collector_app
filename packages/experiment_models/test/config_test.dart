import 'package:flutter_test/flutter_test.dart';
import 'package:experiment_models/client_config.dart';

void main() {
  test('blank credentials permit explicit offline development', () {
    final config = ClientConfig.fromEnvironment({
      'APP_ENV': 'development',
    }, allowOffline: true);
    expect(config.supabaseUrl, isNull);
  });
  test('live configuration requires explicit public values', () {
    expect(() => ClientConfig.fromEnvironment({}), throwsFormatException);
    expect(
      () => ClientConfig.fromEnvironment({
        'ENABLE_DEBUG_TOOLS': 'true',
      }, allowOffline: true),
      throwsFormatException,
    );
  });
  test('rejects insecure remote endpoints even in development', () {
    expect(
      () => ClientConfig.fromEnvironment({
        'APP_ENV': 'development',
        'SUPABASE_URL': 'http://example.org',
      }, allowOffline: true),
      throwsFormatException,
    );
  });
}
