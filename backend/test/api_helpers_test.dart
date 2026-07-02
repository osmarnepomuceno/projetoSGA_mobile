import 'package:sga_backend/api_helpers.dart';
import 'package:test/test.dart';

void main() {
  test('hashPassword gera hash deterministico para admin123', () {
    expect(
      hashPassword('admin123'),
      '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
    );
  });
}
