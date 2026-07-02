import 'dart:io';

class Env {
  Env({
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.jwtSecret,
    required this.apiPort,
  });

  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final String jwtSecret;
  final int apiPort;

  static Env load() {
    final fileValues = _readDotEnv();
    String value(String key, [String fallback = '']) =>
        Platform.environment[key] ?? fileValues[key] ?? fallback;

    return Env(
      dbHost: value('DB_HOST', 'localhost'),
      dbPort: int.parse(value('DB_PORT', '3306')),
      dbName: value('DB_NAME', 'sga_db'),
      dbUser: value('DB_USER', 'sga_user'),
      dbPassword: value('DB_PASSWORD', 'sga_password'),
      jwtSecret: value('JWT_SECRET_KEY', 'alterar_esta_chave'),
      apiPort: int.parse(value('API_PORT', '8080')),
    );
  }

  static Map<String, String> _readDotEnv() {
    final file = File('.env');
    if (!file.existsSync()) return {};

    final values = <String, String>{};
    for (final line in file.readAsLinesSync()) {
      final clean = line.trim();
      if (clean.isEmpty || clean.startsWith('#') || !clean.contains('=')) {
        continue;
      }
      final index = clean.indexOf('=');
      values[clean.substring(0, index)] = clean.substring(index + 1);
    }
    return values;
  }
}
