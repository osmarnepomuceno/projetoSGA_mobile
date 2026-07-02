import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SgaApp());
}

class SgaApp extends StatefulWidget {
  const SgaApp({super.key});

  @override
  State<SgaApp> createState() => _SgaAppState();
}

class _SgaAppState extends State<SgaApp> {
  final storage = const FlutterSecureStorage();
  ApiClient? api;
  Map<String, dynamic>? usuario;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final token = await storage.read(key: 'jwt_token');
    final userJson = await storage.read(key: 'usuario');
    setState(() {
      api = ApiClient(token: token);
      usuario = userJson == null ? null : jsonDecode(userJson);
      loading = false;
    });
  }

  Future<void> _onLogin(String token, Map<String, dynamic> user) async {
    await storage.write(key: 'jwt_token', value: token);
    await storage.write(key: 'usuario', value: jsonEncode(user));
    setState(() {
      api = ApiClient(token: token);
      usuario = user;
    });
  }

  Future<void> _logout() async {
    await storage.deleteAll();
    setState(() {
      api = ApiClient();
      usuario = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SGA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff276749)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : usuario == null
          ? LoginPage(onLogin: _onLogin)
          : HomePage(api: api!, usuario: usuario!, onLogout: _logout),
    );
  }
}

class ApiClient {
  ApiClient({this.token});

  static const timeout = Duration(seconds: 20);
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final String? token;

  Map<String, String> get headers => {
    'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  Future<dynamic> get(String path) async {
    return _send(http.get(Uri.parse('$baseUrl$path'), headers: headers));
  }

  Future<Uint8List> getBytes(String path) async {
    final response = await http
        .get(Uri.parse('$baseUrl$path'), headers: headers)
        .timeout(
          timeout,
          onTimeout: () =>
              throw TimeoutException('Tempo esgotado ao comunicar com a API'),
        );
    if (response.statusCode >= 400) {
      final body = response.body.isEmpty ? null : jsonDecode(response.body);
      final message = body is Map
          ? body['erro'] ?? body['message']
          : 'Erro na requisicao';
      throw Exception(message);
    }
    return response.bodyBytes;
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    return _send(
      http.post(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    return _send(
      http.put(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    return _send(
      http.patch(
        Uri.parse('$baseUrl$path'),
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<dynamic> _send(Future<http.Response> call) async {
    final response = await call.timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException('Tempo esgotado ao comunicar com a API'),
    );
    final data = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = data is Map
          ? data['erro'] ?? data['message']
          : 'Erro na requisicao';
      throw Exception(message);
    }
    return data;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.onLogin, super.key});

  final Future<void> Function(String token, Map<String, dynamic> usuario)
  onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(text: 'admin@sga.com');
  final senha = TextEditingController(text: 'admin123');
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      final data = await ApiClient().post('/auth/login', {
        'email': email.text,
        'senha': senha.text,
      });
      await widget.onLogin(
        data['token'],
        Map<String, dynamic>.from(data['usuario']),
      );
    } catch (error) {
      if (mounted) showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.groups_2, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Sistema de Gerenciamento de Associacao',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: senha,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: loading ? null : _login,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    required this.api,
    required this.usuario,
    required this.onLogout,
    super.key,
  });

  final ApiClient api;
  final Map<String, dynamic> usuario;
  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  bool get admin => widget.usuario['perfil'] == 'ADMINISTRADOR';

  @override
  Widget build(BuildContext context) {
    final pages = [
      AppPage('Dashboard', Icons.dashboard, DashboardView(api: widget.api)),
      AppPage('Associados', Icons.badge, AssociadosView(api: widget.api)),
      AppPage('Cobrancas', Icons.payments, CobrancasView(api: widget.api)),
      AppPage(
        'Carteirinhas',
        Icons.credit_card,
        CarteirinhasView(api: widget.api),
      ),
      if (admin)
        AppPage(
          'Usuarios',
          Icons.admin_panel_settings,
          UsuariosView(api: widget.api),
        ),
      if (admin)
        AppPage('Associacao', Icons.business, AssociacaoView(api: widget.api)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pages[index].title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text('${widget.usuario['nome']}')),
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: pages[index].child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          for (final page in pages)
            NavigationDestination(icon: Icon(page.icon), label: page.title),
        ],
      ),
    );
  }
}

class AppPage {
  AppPage(this.title, this.icon, this.child);
  final String title;
  final IconData icon;
  final Widget child;
}

class DashboardView extends StatelessWidget {
  const DashboardView({required this.api, super.key});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return FuturePanel(
      loader: () => api.get('/relatorios/dashboard'),
      builder: (data, reload) {
        final map = Map<String, dynamic>.from(data);
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            metric('Ativos', map['associadosAtivos'], Icons.check_circle),
            metric('Inativos', map['associadosInativos'], Icons.block),
            metric(
              'Inadimplentes',
              map['associadosInadimplentes'],
              Icons.warning,
            ),
            metric('Abertas', map['cobrancasAbertas'], Icons.pending_actions),
            metric('Pagas', map['cobrancasPagas'], Icons.task_alt),
            metric('Pago no mes', map['valorPagoMesAtual'], Icons.trending_up),
            metric(
              'Em aberto',
              map['valorEmAberto'],
              Icons.account_balance_wallet,
            ),
          ],
        );
      },
    );
  }

  Widget metric(String label, Object? value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              '$value',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class AssociadosView extends StatefulWidget {
  const AssociadosView({required this.api, super.key});
  final ApiClient api;

  @override
  State<AssociadosView> createState() => _AssociadosViewState();
}

class _AssociadosViewState extends State<AssociadosView> {
  int refresh = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FuturePanel(
          key: ValueKey(refresh),
          loader: () => widget.api.get('/associados'),
          builder: (data, reload) {
            final items = List<Map<String, dynamic>>.from(
              data.map((e) => Map<String, dynamic>.from(e)),
            );
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.badge),
                    title: Text('${item['nome']}'),
                    subtitle: Text('CPF ${item['cpf']} - ${item['status']}'),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openForm(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.block),
                          onPressed: () => _inativar(item['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openForm(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AssociadoDialog(api: widget.api, item: item),
    );
    if (saved == true) setState(() => refresh++);
  }

  Future<void> _inativar(Object? id) async {
    await guarded(context, () => widget.api.patch('/associados/$id/inativar'));
    setState(() => refresh++);
  }
}

class AssociadoDialog extends StatefulWidget {
  const AssociadoDialog({required this.api, this.item, super.key});
  final ApiClient api;
  final Map<String, dynamic>? item;

  @override
  State<AssociadoDialog> createState() => _AssociadoDialogState();
}

class _AssociadoDialogState extends State<AssociadoDialog> {
  late final nome = TextEditingController(
    text: '${widget.item?['nome'] ?? ''}',
  );
  late final cpf = TextEditingController(text: '${widget.item?['cpf'] ?? ''}');
  late final telefone = TextEditingController(
    text: '${widget.item?['telefone'] ?? ''}',
  );
  late final email = TextEditingController(
    text: '${widget.item?['email'] ?? ''}',
  );
  late final endereco = TextEditingController(
    text: '${widget.item?['endereco'] ?? ''}',
  );
  late final data = TextEditingController(
    text:
        '${widget.item?['data_filiacao'] ?? DateTime.now().toIso8601String().substring(0, 10)}',
  );
  String status = 'ATIVO';

  Future<void> _save() async {
    final body = {
      'nome': nome.text,
      'cpf': cpf.text,
      'telefone': telefone.text,
      'email': email.text,
      'endereco': endereco.text,
      'dataFiliacao': data.text,
      'status': status,
    };
    if (widget.item == null) {
      await widget.api.post('/associados', body);
    } else {
      await widget.api.put('/associados/${widget.item!['id']}', body);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.item == null ? 'Novo associado' : 'Editar associado',
      onSave: _save,
      children: [
        TextField(
          controller: nome,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        TextField(
          controller: cpf,
          decoration: const InputDecoration(labelText: 'CPF'),
        ),
        TextField(
          controller: telefone,
          decoration: const InputDecoration(labelText: 'Telefone'),
        ),
        TextField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: endereco,
          decoration: const InputDecoration(labelText: 'Endereco'),
        ),
        TextField(
          controller: data,
          decoration: const InputDecoration(labelText: 'Data filiacao'),
        ),
        DropdownButtonFormField(
          initialValue: status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: 'ATIVO', child: Text('ATIVO')),
            DropdownMenuItem(value: 'INATIVO', child: Text('INATIVO')),
            DropdownMenuItem(
              value: 'INADIMPLENTE',
              child: Text('INADIMPLENTE'),
            ),
          ],
          onChanged: (value) => status = value!,
        ),
      ],
    );
  }
}

class CobrancasView extends StatefulWidget {
  const CobrancasView({required this.api, super.key});
  final ApiClient api;

  @override
  State<CobrancasView> createState() => _CobrancasViewState();
}

class _CobrancasViewState extends State<CobrancasView> {
  int refresh = 0;
  int? associadoId;
  int? pdfLoadingId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FuturePanel(
          key: ValueKey('$refresh-$associadoId'),
          loader: () async {
            final associados = await widget.api.get('/associados');
            final cobrancas = associadoId == null
                ? <dynamic>[]
                : await widget.api.get('/cobrancas?associadoId=$associadoId');
            return {'associados': associados, 'cobrancas': cobrancas};
          },
          builder: (data, reload) {
            final map = Map<String, dynamic>.from(data);
            final associados = List<Map<String, dynamic>>.from(
              map['associados'].map((e) => Map<String, dynamic>.from(e)),
            );
            final items = List<Map<String, dynamic>>.from(
              map['cobrancas'].map((e) => Map<String, dynamic>.from(e)),
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: associadoId,
                  decoration: const InputDecoration(
                    labelText: 'Selecione o associado',
                  ),
                  items: [
                    for (final associado in associados)
                      DropdownMenuItem<int>(
                        value: int.parse('${associado['id']}'),
                        child: Text(
                          '${associado['nome']} - ${associado['cpf']}',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      associadoId = value;
                      refresh++;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (associadoId == null)
                  const EmptyStateCard(
                    icon: Icons.person_search,
                    title: 'Selecione um associado',
                    message:
                        'Os boletos do associado selecionado serao listados aqui.',
                  )
                else if (items.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.receipt_long,
                    title: 'Nenhum boleto encontrado',
                    message:
                        'Este associado ainda nao possui cobrancas cadastradas.',
                  ),
                for (final item in items)
                  BoletoCard(
                    item: item,
                    gerandoPdf: pdfLoadingId == int.parse('${item['id']}'),
                    onGerarPdf: () => _gerarPdf(item),
                    onPagar: () => _marcarComoPago(item),
                  ),
              ],
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => CobrancaDialog(
                  api: widget.api,
                  associadoIdInicial: associadoId,
                ),
              );
              if (ok == true) setState(() => refresh++);
            },
            tooltip: 'Nova cobranca',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _gerarPdf(Map<String, dynamic> item) async {
    final id = int.parse('${item['id']}');
    setState(() => pdfLoadingId = id);
    try {
      final bytes = await widget.api.getBytes(
        '/cobrancas/${item['id']}/boleto.pdf',
      );
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}boleto_${item['id']}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      showSnack(context, 'PDF gerado: ${file.path}');
    } catch (error) {
      if (mounted) showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => pdfLoadingId = null);
    }
  }

  Future<void> _marcarComoPago(Map<String, dynamic> item) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar boleto como pago?'),
        content: Text('Boleto ${item['id']} - R\$ ${item['valor']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    if (!mounted) return;

    await guarded(
      context,
      () => widget.api.patch('/cobrancas/${item['id']}/pagar'),
    );
    if (mounted) setState(() => refresh++);
  }
}

class BoletoCard extends StatelessWidget {
  const BoletoCard({
    required this.item,
    required this.gerandoPdf,
    required this.onGerarPdf,
    required this.onPagar,
    super.key,
  });

  final Map<String, dynamic> item;
  final bool gerandoPdf;
  final VoidCallback onGerarPdf;
  final VoidCallback onPagar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('Boleto ${item['id']} - R\$ ${item['valor']}'),
              subtitle: Text(
                'Vence em ${item['data_vencimento']} - ${item['status']}',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 4,
                overflowSpacing: 4,
                children: [
                  Semantics(
                    label: 'Gerar PDF do boleto ${item['id']}',
                    button: true,
                    child: IconButton(
                      icon: gerandoPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      tooltip: 'Gerar PDF do boleto',
                      onPressed: gerandoPdf ? null : onGerarPdf,
                    ),
                  ),
                  Semantics(
                    label: 'Marcar boleto ${item['id']} como pago',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.task_alt),
                      tooltip: 'Marcar como pago',
                      onPressed: onPagar,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CobrancaDialog extends StatefulWidget {
  const CobrancaDialog({required this.api, this.associadoIdInicial, super.key});
  final ApiClient api;
  final int? associadoIdInicial;

  @override
  State<CobrancaDialog> createState() => _CobrancaDialogState();
}

class _CobrancaDialogState extends State<CobrancaDialog> {
  final valor = TextEditingController();
  final vencimento = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  int? associadoId;
  String? associadoErro;
  String? valorErro;
  String? vencimentoErro;

  @override
  void initState() {
    super.initState();
    associadoId = widget.associadoIdInicial;
  }

  @override
  Widget build(BuildContext context) {
    return FuturePanel(
      loader: () => widget.api.get('/associados'),
      builder: (data, reload) {
        final associados = List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)),
        );
        return FormDialog(
          title: 'Nova cobranca',
          onSave: () async {
            if (!_validar()) return;

            await widget.api.post('/cobrancas', {
              'associadoId': associadoId,
              'valor': valor.text,
              'dataVencimento': vencimento.text,
            });
            if (!context.mounted) return;
            Navigator.pop(context, true);
          },
          children: [
            DropdownButtonFormField<int>(
              initialValue: associadoId,
              decoration: InputDecoration(
                labelText: 'Associado',
                errorText: associadoErro,
              ),
              items: [
                for (final associado in associados)
                  DropdownMenuItem<int>(
                    value: int.parse('${associado['id']}'),
                    child: Text('${associado['nome']} - ${associado['cpf']}'),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  associadoId = value;
                  associadoErro = null;
                });
              },
            ),
            TextField(
              controller: valor,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor',
                errorText: valorErro,
              ),
              onChanged: (_) {
                if (valorErro != null) setState(() => valorErro = null);
              },
            ),
            TextField(
              controller: vencimento,
              decoration: InputDecoration(
                labelText: 'Data vencimento',
                errorText: vencimentoErro,
              ),
              onChanged: (_) {
                if (vencimentoErro != null) {
                  setState(() => vencimentoErro = null);
                }
              },
            ),
          ],
        );
      },
    );
  }

  bool _validar() {
    final valorNumerico = double.tryParse(valor.text.replaceAll(',', '.'));
    setState(() {
      associadoErro = associadoId == null ? 'Selecione um associado' : null;
      valorErro = valorNumerico == null || valorNumerico <= 0
          ? 'Informe um valor maior que zero'
          : null;
      vencimentoErro = vencimento.text.trim().isEmpty
          ? 'Informe a data de vencimento'
          : null;
    });
    return associadoErro == null && valorErro == null && vencimentoErro == null;
  }
}

class CarteirinhasView extends StatefulWidget {
  const CarteirinhasView({required this.api, super.key});
  final ApiClient api;

  @override
  State<CarteirinhasView> createState() => _CarteirinhasViewState();
}

class _CarteirinhasViewState extends State<CarteirinhasView> {
  final associadoId = TextEditingController();
  Map<String, dynamic>? item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: associadoId,
            decoration: const InputDecoration(labelText: 'ID do associado'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _buscar,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _gerar,
                icon: const Icon(Icons.add_card),
                label: const Text('Gerar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (item != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card),
                title: Text('Carteirinha ${item!['id']}'),
                subtitle: Text(
                  'Emissao ${item!['data_emissao']} - Validade ${item!['data_validade']}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _buscar() async {
    await guarded(context, () async {
      final data = await widget.api.get('/carteirinhas/${associadoId.text}');
      setState(() => item = Map<String, dynamic>.from(data));
    });
  }

  Future<void> _gerar() async {
    await guarded(
      context,
      () => widget.api.post('/carteirinhas/${associadoId.text}', {}),
    );
    await _buscar();
  }
}

class UsuariosView extends StatefulWidget {
  const UsuariosView({required this.api, super.key});
  final ApiClient api;

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  int refresh = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FuturePanel(
          key: ValueKey(refresh),
          loader: () => widget.api.get('/usuarios'),
          builder: (data, reload) {
            final items = List<Map<String, dynamic>>.from(
              data.map((e) => Map<String, dynamic>.from(e)),
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in items)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('${item['nome']}'),
                      subtitle: Text('${item['email']} - ${item['perfil']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.block),
                        onPressed: () async {
                          await guarded(
                            context,
                            () => widget.api.patch(
                              '/usuarios/${item['id']}/inativar',
                            ),
                          );
                          setState(() => refresh++);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => UsuarioDialog(api: widget.api),
              );
              if (ok == true) setState(() => refresh++);
            },
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }
}

class UsuarioDialog extends StatefulWidget {
  const UsuarioDialog({required this.api, super.key});
  final ApiClient api;

  @override
  State<UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<UsuarioDialog> {
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  String perfil = 'ATENDENTE';

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Novo usuario',
      onSave: () async {
        await widget.api.post('/usuarios', {
          'nome': nome.text,
          'email': email.text,
          'senha': senha.text,
          'perfil': perfil,
        });
        if (!context.mounted) return;
        Navigator.pop(context, true);
      },
      children: [
        TextField(
          controller: nome,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        TextField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: senha,
          decoration: const InputDecoration(labelText: 'Senha'),
        ),
        DropdownButtonFormField(
          initialValue: perfil,
          decoration: const InputDecoration(labelText: 'Perfil'),
          items: const [
            DropdownMenuItem(value: 'ATENDENTE', child: Text('ATENDENTE')),
            DropdownMenuItem(
              value: 'ADMINISTRADOR',
              child: Text('ADMINISTRADOR'),
            ),
          ],
          onChanged: (value) => perfil = value!,
        ),
      ],
    );
  }
}

class AssociacaoView extends StatefulWidget {
  const AssociacaoView({required this.api, super.key});
  final ApiClient api;

  @override
  State<AssociacaoView> createState() => _AssociacaoViewState();
}

class _AssociacaoViewState extends State<AssociacaoView> {
  final nome = TextEditingController();
  final cnpj = TextEditingController();
  final endereco = TextEditingController();
  final telefone = TextEditingController();
  final email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FuturePanel(
      loader: () async {
        final data = await widget.api.get('/associacao');
        nome.text = '${data['nome'] ?? ''}';
        cnpj.text = '${data['cnpj'] ?? ''}';
        endereco.text = '${data['endereco'] ?? ''}';
        telefone.text = '${data['telefone'] ?? ''}';
        email.text = '${data['email'] ?? ''}';
        return data;
      },
      builder: (_, reload) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nome,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cnpj,
              decoration: const InputDecoration(labelText: 'CNPJ'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endereco,
              decoration: const InputDecoration(labelText: 'Endereco'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await guarded(
                  context,
                  () => widget.api.put('/associacao', {
                    'nome': nome.text,
                    'cnpj': cnpj.text,
                    'endereco': endereco.text,
                    'telefone': telefone.text,
                    'email': email.text,
                  }),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

class FuturePanel extends StatefulWidget {
  const FuturePanel({required this.loader, required this.builder, super.key});
  final Future<dynamic> Function() loader;
  final Widget Function(dynamic data, VoidCallback reload) builder;

  @override
  State<FuturePanel> createState() => _FuturePanelState();
}

class _FuturePanelState extends State<FuturePanel> {
  late Future<dynamic> future = widget.loader();

  void reload() {
    setState(() {
      future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Semantics(
              label: 'Carregando dados',
              liveRegion: true,
              child: const CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }
        return widget.builder(snapshot.data, reload);
      },
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(message),
      ),
    );
  }
}

class FormDialog extends StatefulWidget {
  const FormDialog({
    required this.title,
    required this.children,
    required this.onSave,
    super.key,
  });
  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  bool loading = false;

  Future<void> save() async {
    setState(() => loading = true);
    try {
      await widget.onSave();
    } catch (error) {
      if (mounted) showSnack(context, error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in widget.children) ...[
                child,
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: loading ? null : save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

Future<void> guarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    if (context.mounted) showSnack(context, 'Operacao concluida');
  } catch (error) {
    if (context.mounted) showSnack(context, error.toString());
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
  );
}
