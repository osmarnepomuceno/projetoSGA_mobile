import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/api_helpers.dart';
import '../lib/database.dart';
import '../lib/env.dart';

Future<void> main() async {
  final env = Env.load();
  final db = Database(env);
  await db.connect();

  final router = Router();

  router.options('/<ignored|.*>', (Request request) {
    return Response.ok('', headers: corsHeaders);
  });

  router.post('/auth/login', (Request request) async {
    final body = await readJson(request);
    final email = '${body['email'] ?? ''}'.trim();
    final senha = '${body['senha'] ?? ''}';
    if (email.isEmpty || senha.isEmpty) {
      return errorResponse(400, 'Email e senha sao obrigatorios');
    }

    final result = await db.execute(
      'SELECT * FROM tb_usuario WHERE email = :email LIMIT 1',
      {'email': email},
    );
    if (result.rows.isEmpty) return errorResponse(401, 'Credenciais invalidas');

    final usuario = rowToMap(result.rows.first);
    if (usuario['ativo'] != '1') return errorResponse(403, 'Usuario inativo');
    if (usuario['senha_hash'] != hashPassword(senha)) {
      return errorResponse(401, 'Credenciais invalidas');
    }

    final token = JWT({
      'usuarioId': usuario['id'],
      'email': usuario['email'],
      'perfil': usuario['perfil'],
    }).sign(SecretKey(env.jwtSecret), expiresIn: const Duration(hours: 8));

    usuario.remove('senha_hash');
    return jsonResponse({'token': token, 'usuario': usuario});
  });

  router.get('/usuarios', (Request request) async {
    final blocked = requireAdmin(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final result = await db.execute(
      'SELECT id, nome, email, perfil, ativo, criado_em, atualizado_em '
      'FROM tb_usuario ORDER BY nome',
    );
    return jsonResponse(rowsToList(result));
  });

  router.post('/usuarios', (Request request) async {
    final blocked = requireAdmin(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final body = await readJson(request);
    final nome = '${body['nome'] ?? ''}'.trim();
    final email = '${body['email'] ?? ''}'.trim();
    final senha = '${body['senha'] ?? ''}';
    final perfil = '${body['perfil'] ?? 'ATENDENTE'}';
    if (nome.isEmpty || !email.contains('@') || senha.length < 4) {
      return errorResponse(400, 'Nome, email valido e senha sao obrigatorios');
    }
    if (!['ADMINISTRADOR', 'ATENDENTE'].contains(perfil)) {
      return errorResponse(400, 'Perfil invalido');
    }

    await db.execute(
      'INSERT INTO tb_usuario (nome, email, senha_hash, perfil, ativo) '
      'VALUES (:nome, :email, :senha, :perfil, TRUE)',
      {
        'nome': nome,
        'email': email,
        'senha': hashPassword(senha),
        'perfil': perfil,
      },
    );
    return jsonResponse({'mensagem': 'Usuario criado'}, status: 201);
  });

  router.put('/usuarios/<id>', (Request request, String id) async {
    final blocked = requireAdmin(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final body = await readJson(request);
    await db.execute(
      'UPDATE tb_usuario SET nome = :nome, email = :email, perfil = :perfil, '
      'ativo = :ativo, atualizado_em = NOW() WHERE id = :id',
      {
        'id': parseId(id),
        'nome': body['nome'],
        'email': body['email'],
        'perfil': body['perfil'],
        'ativo': body['ativo'] == false ? 0 : 1,
      },
    );
    return jsonResponse({'mensagem': 'Usuario atualizado'});
  });

  router.patch('/usuarios/<id>/inativar', (Request request, String id) async {
    final blocked = requireAdmin(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final user = currentUser(request, env.jwtSecret)!;
    if ('${user['usuarioId']}' == id) {
      return errorResponse(
        400,
        'Administrador nao pode inativar a propria conta',
      );
    }
    await db.execute(
      'UPDATE tb_usuario SET ativo = FALSE, atualizado_em = NOW() WHERE id = :id',
      {'id': parseId(id)},
    );
    return jsonResponse({'mensagem': 'Usuario inativado'});
  });

  router.get('/associacao', (Request request) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final result = await db.execute(
      'SELECT * FROM tb_associacao ORDER BY id LIMIT 1',
    );
    return jsonResponse(result.rows.isEmpty ? {} : rowToMap(result.rows.first));
  });

  router.put('/associacao', (Request request) async {
    final blocked = requireAdmin(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final body = await readJson(request);
    final nome = '${body['nome'] ?? ''}'.trim();
    if (nome.isEmpty) return errorResponse(400, 'Nome e obrigatorio');

    await db.execute(
      'UPDATE tb_associacao SET nome = :nome, cnpj = :cnpj, endereco = :endereco, '
      'telefone = :telefone, email = :email, atualizado_em = NOW() WHERE id = '
      '(SELECT id FROM (SELECT id FROM tb_associacao ORDER BY id LIMIT 1) x)',
      {
        'nome': nome,
        'cnpj': body['cnpj'],
        'endereco': body['endereco'],
        'telefone': body['telefone'],
        'email': body['email'],
      },
    );
    return jsonResponse({'mensagem': 'Associacao atualizada'});
  });

  router.get('/associados', (Request request) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final q = request.url.queryParameters;
    final nome = '%${q['nome'] ?? ''}%';
    final cpf = '%${q['cpf'] ?? ''}%';
    final status = q['status'];
    final result = await db.execute(
      'SELECT * FROM tb_associado '
      'WHERE nome LIKE :nome AND cpf LIKE :cpf '
      'AND (:status IS NULL OR status = :status) ORDER BY nome',
      {'nome': nome, 'cpf': cpf, 'status': status},
    );
    return jsonResponse(rowsToList(result));
  });

  router.get('/associados/<id>', (Request request, String id) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final result = await db.execute(
      'SELECT * FROM tb_associado WHERE id = :id',
      {'id': parseId(id)},
    );
    if (result.rows.isEmpty)
      return errorResponse(404, 'Associado nao encontrado');
    return jsonResponse(rowToMap(result.rows.first));
  });

  router.post('/associados', (Request request) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final body = await readJson(request);
    final nome = '${body['nome'] ?? ''}'.trim();
    final cpf = '${body['cpf'] ?? ''}'.trim();
    if (nome.isEmpty || cpf.isEmpty) {
      return errorResponse(400, 'Nome e CPF sao obrigatorios');
    }

    await db.execute(
      'INSERT INTO tb_associado '
      '(nome, cpf, telefone, email, endereco, data_filiacao, status) '
      'VALUES (:nome, :cpf, :telefone, :email, :endereco, :data, :status)',
      {
        'nome': nome,
        'cpf': cpf,
        'telefone': body['telefone'],
        'email': body['email'],
        'endereco': body['endereco'],
        'data':
            body['dataFiliacao'] ??
            DateTime.now().toIso8601String().substring(0, 10),
        'status': body['status'] ?? 'ATIVO',
      },
    );
    return jsonResponse({'mensagem': 'Associado criado'}, status: 201);
  });

  router.put('/associados/<id>', (Request request, String id) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final body = await readJson(request);
    await db.execute(
      'UPDATE tb_associado SET nome = :nome, cpf = :cpf, telefone = :telefone, '
      'email = :email, endereco = :endereco, data_filiacao = :data, '
      'status = :status, atualizado_em = NOW() WHERE id = :id',
      {
        'id': parseId(id),
        'nome': body['nome'],
        'cpf': body['cpf'],
        'telefone': body['telefone'],
        'email': body['email'],
        'endereco': body['endereco'],
        'data': body['dataFiliacao'],
        'status': body['status'] ?? 'ATIVO',
      },
    );
    return jsonResponse({'mensagem': 'Associado atualizado'});
  });

  router.patch('/associados/<id>/inativar', (Request request, String id) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    await db.execute(
      'UPDATE tb_associado SET status = "INATIVO", atualizado_em = NOW() WHERE id = :id',
      {'id': parseId(id)},
    );
    return jsonResponse({'mensagem': 'Associado inativado'});
  });

  router.get('/cobrancas', (Request request) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final associadoId = request.url.queryParameters['associadoId'];
    final filtroAssociado =
        associadoId != null && associadoId.trim().isNotEmpty;
    final result = await db.execute(
      'SELECT c.*, a.nome AS associado_nome FROM tb_cobranca c '
      'JOIN tb_associado a ON a.id = c.associado_id '
      '${filtroAssociado ? 'WHERE c.associado_id = :associadoId ' : ''}'
      'ORDER BY c.data_vencimento DESC',
      filtroAssociado ? {'associadoId': parseId(associadoId)} : {},
    );
    return jsonResponse(rowsToList(result));
  });

  router.get('/cobrancas/<id>/boleto.pdf', (Request request, String id) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final result = await db.execute(
      'SELECT c.*, a.nome AS associado_nome, a.cpf AS associado_cpf '
      'FROM tb_cobranca c '
      'JOIN tb_associado a ON a.id = c.associado_id '
      'WHERE c.id = :id '
      'LIMIT 1',
      {'id': parseId(id)},
    );
    if (result.rows.isEmpty)
      return errorResponse(404, 'Cobranca nao encontrada');

    final boleto = rowToMap(result.rows.first);
    final pdf = boletoPdf(boleto);
    return Response.ok(
      pdf,
      headers: {
        'content-type': 'application/pdf',
        'content-disposition':
            'attachment; filename="boleto-${boleto['id']}.pdf"',
      },
    );
  });

  router.post('/cobrancas', (Request request) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final body = await readJson(request);
    final valor = double.tryParse('${body['valor'] ?? ''}') ?? 0;
    if (valor <= 0) return errorResponse(400, 'Valor deve ser maior que zero');

    await db.execute(
      'INSERT INTO tb_cobranca (associado_id, valor, data_vencimento, status) '
      'VALUES (:associadoId, :valor, :vencimento, "ABERTA")',
      {
        'associadoId': body['associadoId'],
        'valor': valor,
        'vencimento': body['dataVencimento'],
      },
    );
    return jsonResponse({'mensagem': 'Cobranca criada'}, status: 201);
  });

  router.patch('/cobrancas/<id>/pagar', (Request request, String id) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    await db.execute(
      'UPDATE tb_cobranca SET status = "PAGA", data_pagamento = CURDATE(), '
      'atualizado_em = NOW() WHERE id = :id AND status IN ("ABERTA", "VENCIDA")',
      {'id': parseId(id)},
    );
    return jsonResponse({'mensagem': 'Cobranca marcada como paga'});
  });

  router.get('/carteirinhas/<associadoId>', (
    Request request,
    String associadoId,
  ) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    final result = await db.execute(
      'SELECT * FROM tb_carteirinha WHERE associado_id = :id ORDER BY id DESC LIMIT 1',
      {'id': parseId(associadoId)},
    );
    if (result.rows.isEmpty)
      return errorResponse(404, 'Carteirinha nao encontrada');
    return jsonResponse(rowToMap(result.rows.first));
  });

  router.post('/carteirinhas/<associadoId>', (
    Request request,
    String associadoId,
  ) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    await db.execute(
      'INSERT INTO tb_carteirinha '
      '(associado_id, data_emissao, data_validade, arquivo_url) '
      'VALUES (:id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 YEAR), :url)',
      {'id': parseId(associadoId), 'url': '/carteirinhas/$associadoId.pdf'},
    );
    return jsonResponse({'mensagem': 'Carteirinha gerada'}, status: 201);
  });

  router.get('/relatorios/dashboard', (Request request) async {
    final blocked = requireAuth(request, env.jwtSecret);
    if (blocked != null) return blocked;

    Future<String> scalar(String sql) async {
      final result = await db.execute(sql);
      return result.rows.first.assoc().values.first ?? '0';
    }

    return jsonResponse({
      'associadosAtivos': await scalar(
        'SELECT COUNT(*) FROM tb_associado WHERE status = "ATIVO"',
      ),
      'associadosInativos': await scalar(
        'SELECT COUNT(*) FROM tb_associado WHERE status = "INATIVO"',
      ),
      'associadosInadimplentes': await scalar(
        'SELECT COUNT(*) FROM tb_associado WHERE status = "INADIMPLENTE"',
      ),
      'cobrancasAbertas': await scalar(
        'SELECT COUNT(*) FROM tb_cobranca WHERE status = "ABERTA"',
      ),
      'cobrancasPagas': await scalar(
        'SELECT COUNT(*) FROM tb_cobranca WHERE status = "PAGA"',
      ),
      'valorPagoMesAtual': await scalar(
        'SELECT COALESCE(SUM(valor), 0) FROM tb_cobranca '
        'WHERE status = "PAGA" AND MONTH(data_pagamento) = MONTH(CURDATE()) '
        'AND YEAR(data_pagamento) = YEAR(CURDATE())',
      ),
      'valorEmAberto': await scalar(
        'SELECT COALESCE(SUM(valor), 0) FROM tb_cobranca WHERE status = "ABERTA"',
      ),
    });
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        (inner) => (request) async {
          final response = await inner(request);
          return response.change(headers: corsHeaders);
        },
      )
      .addHandler(router.call);

  final server = await serve(handler, InternetAddress.anyIPv4, env.apiPort);
  print('SGA backend rodando em http://${server.address.host}:${server.port}');
}

List<int> boletoPdf(Map<String, dynamic> boleto) {
  final lines = [
    'Sistema de Gerenciamento de Associacao',
    'Boleto de cobranca',
    'Numero: ${boleto['id']}',
    'Associado: ${boleto['associado_nome']}',
    'CPF: ${boleto['associado_cpf']}',
    'Valor: R\$ ${boleto['valor']}',
    'Vencimento: ${boleto['data_vencimento']}',
    'Status: ${boleto['status']}',
    'Linha digitavel: ${linhaDigitavel(boleto)}',
  ];

  final content = StringBuffer()
    ..writeln('BT')
    ..writeln('/F1 18 Tf')
    ..writeln('72 760 Td')
    ..writeln('(${escapePdf(lines.first)}) Tj')
    ..writeln('/F1 12 Tf');
  for (final line in lines.skip(1)) {
    content
      ..writeln('0 -28 Td')
      ..writeln('(${escapePdf(line)}) Tj');
  }
  content.writeln('ET');

  final stream = content.toString();
  final objects = <String>[
    '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
    '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
    '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n',
    '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
    '5 0 obj\n<< /Length ${latin1.encode(stream).length} >>\nstream\n$stream'
        'endstream\nendobj\n',
  ];

  final buffer = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[0];
  var length = latin1.encode(buffer.toString()).length;
  for (final object in objects) {
    offsets.add(length);
    buffer.write(object);
    length += latin1.encode(object).length;
  }

  final xrefOffset = length;
  buffer
    ..writeln('xref')
    ..writeln('0 ${objects.length + 1}')
    ..writeln('0000000000 65535 f ');
  for (final offset in offsets.skip(1)) {
    buffer.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
  }
  buffer
    ..writeln('trailer')
    ..writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>')
    ..writeln('startxref')
    ..writeln(xrefOffset)
    ..writeln('%%EOF');

  return latin1.encode(buffer.toString());
}

String linhaDigitavel(Map<String, dynamic> boleto) {
  final id = '${boleto['id']}'.padLeft(8, '0');
  final associadoId = '${boleto['associado_id']}'.padLeft(8, '0');
  final vencimento = '${boleto['data_vencimento']}'.replaceAll('-', '');
  final valor = '${boleto['valor']}'
      .replaceAll(RegExp(r'[^0-9]'), '')
      .padLeft(10, '0');
  return '23790.$id $associadoId.$vencimento $valor.0';
}

String escapePdf(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
}
