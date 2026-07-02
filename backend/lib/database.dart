import 'package:mysql_client/mysql_client.dart';

import 'env.dart';

class Database {
  Database(this.env);

  final Env env;
  late final MySQLConnection _conn;

  Future<void> connect() async {
    _conn = await MySQLConnection.createConnection(
      host: env.dbHost,
      port: env.dbPort,
      userName: env.dbUser,
      password: env.dbPassword,
      databaseName: env.dbName,
      secure: true,
    );
    await _conn.connect();
  }

  Future<IResultSet> execute(
    String sql, [
    Map<String, dynamic> params = const {},
  ]) {
    return _conn.execute(sql, params);
  }

  Future<void> close() => _conn.close();
}
