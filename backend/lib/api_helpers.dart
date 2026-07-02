import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

Response jsonResponse(Object data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(data),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...corsHeaders,
    },
  );
}

Response errorResponse(int status, String message) {
  return jsonResponse({'erro': message}, status: status);
}

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers': 'Origin, Content-Type, Authorization',
};

Future<Map<String, dynamic>> readJson(Request request) async {
  final body = await request.readAsString();
  if (body.trim().isEmpty) return {};
  return jsonDecode(body) as Map<String, dynamic>;
}

Map<String, dynamic> rowToMap(ResultSetRow row) {
  return row.assoc().map((key, value) => MapEntry(key, value));
}

List<Map<String, dynamic>> rowsToList(IResultSet result) {
  return result.rows.map(rowToMap).toList();
}

Map<String, dynamic>? currentUser(Request request, String secret) {
  final header = request.headers['authorization'];
  if (header == null || !header.startsWith('Bearer ')) return null;

  try {
    final token = header.substring('Bearer '.length);
    final jwt = JWT.verify(token, SecretKey(secret));
    return Map<String, dynamic>.from(jwt.payload as Map);
  } catch (_) {
    return null;
  }
}

Response? requireAuth(Request request, String secret) {
  return currentUser(request, secret) == null
      ? errorResponse(401, 'Token ausente ou invalido')
      : null;
}

Response? requireAdmin(Request request, String secret) {
  final user = currentUser(request, secret);
  if (user == null) return errorResponse(401, 'Token ausente ou invalido');
  if (user['perfil'] != 'ADMINISTRADOR') {
    return errorResponse(403, 'Acesso restrito ao administrador');
  }
  return null;
}

int parseId(String value) => int.tryParse(value) ?? 0;
