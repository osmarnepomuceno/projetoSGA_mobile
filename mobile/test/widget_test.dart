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
}
