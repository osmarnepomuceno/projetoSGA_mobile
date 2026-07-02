import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sga_mobile/main.dart';

void main() {
  testWidgets('exibe tela de login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(onLogin: (_, _) async {})),
    );

    expect(find.text('Sistema de Gerenciamento de Associacao'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets(
    'cobrancas orienta selecionar associado antes de listar boletos',
    (tester) async {
      final api = FakeApiClient();

      await tester.pumpWidget(appScaffold(CobrancasView(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('Selecione um associado'), findsOneWidget);
      expect(
        find.text('Os boletos do associado selecionado serao listados aqui.'),
        findsOneWidget,
      );
      expect(api.calls, contains('GET /associados'));
      expect(api.calls, isNot(contains('GET /cobrancas?associadoId=1')));
    },
  );

  testWidgets('selecionar associado lista boletos filtrados', (tester) async {
    final api = FakeApiClient();

    await tester.pumpWidget(appScaffold(CobrancasView(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Silva - 123').last);
    await tester.pumpAndSettle();

    expect(api.calls, contains('GET /cobrancas?associadoId=1'));
    expect(find.text('Boleto 9 - R\$ 150.00'), findsOneWidget);
    expect(find.text('Vence em 2026-07-10 - ABERTA'), findsOneWidget);
  });

  testWidgets('botao de PDF chama endpoint do boleto', (tester) async {
    final api = FakeApiClient();

    await tester.pumpWidget(appScaffold(CobrancasView(api: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Silva - 123').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Gerar PDF do boleto'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(api.calls, contains('GET_BYTES /cobrancas/9/boleto.pdf'));
  });

  testWidgets('dialogo de cobranca exibe validacoes visuais', (tester) async {
    final api = FakeApiClient();

    await tester.pumpWidget(MaterialApp(home: CobrancaDialog(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecione um associado'), findsOneWidget);
    expect(find.text('Informe um valor maior que zero'), findsOneWidget);
  });
}

Widget appScaffold(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

class FakeApiClient extends ApiClient {
  final calls = <String>[];

  @override
  Future<dynamic> get(String path) async {
    calls.add('GET $path');
    if (path == '/associados') {
      return [
        {'id': '1', 'nome': 'Ana Silva', 'cpf': '123'},
      ];
    }
    if (path == '/cobrancas?associadoId=1') {
      return [
        {
          'id': '9',
          'valor': '150.00',
          'data_vencimento': '2026-07-10',
          'status': 'ABERTA',
        },
      ];
    }
    return [];
  }

  @override
  Future<Uint8List> getBytes(String path) async {
    calls.add('GET_BYTES $path');
    return Uint8List.fromList([37, 80, 68, 70]);
  }
}
