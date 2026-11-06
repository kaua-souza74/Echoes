import 'package:flutter_test/flutter_test.dart';
import 'package:echoes/app/supabase_config.dart';

void main() {
  test('default environment config is ready for flutter run', () {
    final config = SupabaseConfig.environment();

    expect(config.url, 'https://jkxucvortrhssfesswmx.supabase.co');
    expect(config.key, isNotEmpty);
    expect(config.validate, returnsNormally);
  });
}
