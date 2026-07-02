# Inspecao Superficial de Ciberseguranca

Projeto inspecionado: `E:\desenvolvimento_mobile\projetoSGA`

Escopo considerado:

- `backend/bin/server.dart`
- `backend/lib/api_helpers.dart`
- `backend/lib/env.dart`
- `backend/lib/database.dart`
- `docker-compose.yml`
- `docker/init.sql`
- `mobile/lib/main.dart`
- `mobile/android/app/build.gradle.kts`
- `mobile/android/app/src/main/AndroidManifest.xml`
- `README.md`

Referenciais usados:

- OWASP Top 10: A01, A02, A03, A04, A05, A06, A07, A08, A09, A10
- CWE quando aplicavel
- CVE: nao foram identificadas CVEs especificas nesta inspecao superficial

## Resumo executivo

| Severidade | Quantidade |
|---|---:|
| Critica | 0 |
| Alta | 6 |
| Media | 6 |
| Baixa | 2 |

Total de achados: 14

## 5 acoes mais urgentes

1. Remover segredos e credenciais padrao do codigo/configuracao e exigir variaveis de ambiente obrigatorias.
2. Substituir SHA-256 puro por algoritmo de senha com salt e custo, como Argon2id, bcrypt ou PBKDF2.
3. Restringir autorizacao por perfil nas rotas sensiveis e validar posse/escopo dos recursos acessados por ID.
4. Desabilitar trafego HTTP claro em builds nao locais e exigir HTTPS/TLS.
5. Restringir CORS e adicionar cabecalhos HTTP de seguranca.

---

## SEC-001 - JWT possui segredo padrao fraco

Severidade: Alta

OWASP: A02 Security Misconfiguration, A04 Cryptographic Failures

CWE: CWE-798 Use of Hard-coded Credentials, CWE-321 Use of Hard-coded Cryptographic Key

Localizacao:

- Arquivo: `backend/lib/env.dart`
- Funcao: `Env.load`
- Linha: 33

Evidencia:

```dart
jwtSecret: value('JWT_SECRET_KEY', 'alterar_esta_chave'),
```

Descricao:

O backend aceita um segredo JWT padrao quando `JWT_SECRET_KEY` nao esta configurado. Se o ambiente subir sem variavel segura, tokens podem ser assinados ou forjados por qualquer pessoa que conheca o fallback.

Impacto potencial:

Forja de tokens JWT, elevacao de privilegios e acesso nao autorizado a rotas protegidas.

Recomendacao:

Falhar a inicializacao quando o segredo nao existir ou for fraco.

```dart
final jwtSecret = value('JWT_SECRET_KEY');
if (jwtSecret.length < 32) {
  throw StateError('JWT_SECRET_KEY deve ter pelo menos 32 caracteres');
}
```

---

## SEC-002 - Credenciais de banco hardcoded

Severidade: Alta

OWASP: A02 Security Misconfiguration, A04 Cryptographic Failures

CWE: CWE-798 Use of Hard-coded Credentials

Localizacao:

- Arquivo: `backend/lib/env.dart`
- Funcao: `Env.load`
- Linhas: 31-32
- Arquivo: `docker-compose.yml`
- Linhas: 8-10

Evidencia:

```dart
dbUser: value('DB_USER', 'sga_user'),
dbPassword: value('DB_PASSWORD', 'sga_password'),
```

```yaml
MYSQL_ROOT_PASSWORD: rootpassword
MYSQL_USER: sga_user
MYSQL_PASSWORD: sga_password
```

Descricao:

O projeto contem credenciais previsiveis e reutilizaveis para o banco de dados. Mesmo em ambiente local, esses valores tendem a ser copiados para ambientes reais.

Impacto potencial:

Comprometimento do banco, acesso indevido a dados pessoais de associados e alteracao de cobrancas.

Recomendacao:

Usar `.env` nao versionado ou secrets do ambiente e remover fallbacks sensiveis.

```dart
String requiredValue(String key) {
  final current = Platform.environment[key] ?? fileValues[key];
  if (current == null || current.isEmpty) {
    throw StateError('$key nao configurado');
  }
  return current;
}
```

---

## SEC-003 - Senhas armazenadas com SHA-256 sem salt/custo

Severidade: Alta

OWASP: A04 Cryptographic Failures, A07 Identification and Authentication Failures

CWE: CWE-916 Use of Password Hash With Insufficient Computational Effort

Localizacao:

- Arquivo: `backend/lib/api_helpers.dart`
- Funcao: `hashPassword`
- Linhas: 8-10
- Arquivo: `backend/bin/server.dart`
- Funcao: login e criacao de usuario
- Linhas: 40 e 87

Evidencia:

```dart
String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}
```

Descricao:

SHA-256 puro e rapido demais para armazenamento de senhas e nao usa salt unico por usuario. Isso facilita ataques offline com dicionario ou rainbow tables caso a base seja vazada.

Impacto potencial:

Quebra de senhas de usuarios e tomada de contas administrativas.

Recomendacao:

Usar Argon2id, bcrypt ou PBKDF2 com salt unico e fator de custo.

Exemplo conceitual:

```dart
final hash = passwordHasher.hash(password); // bcrypt/argon2id com salt
final valid = passwordHasher.verify(password, storedHash);
```

---

## SEC-004 - Credenciais administrativas padrao expostas

Severidade: Alta

OWASP: A02 Security Misconfiguration, A07 Identification and Authentication Failures

CWE: CWE-798 Use of Hard-coded Credentials, CWE-521 Weak Password Requirements

Localizacao:

- Arquivo: `mobile/lib/main.dart`
- Classe: `_LoginPageState`
- Linhas: 177-178
- Arquivo: `docker/init.sql`
- Linhas: 72-76
- Arquivo: `README.md`
- Linhas: 23-25

Evidencia:

```dart
final email = TextEditingController(text: 'admin@sga.com');
final senha = TextEditingController(text: 'admin123');
```

```sql
SELECT 'Administrador Inicial', 'admin@sga.com',
       '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
       'ADMINISTRADOR', TRUE
```

Descricao:

O app preenche credenciais administrativas na tela de login, e o seed cria administrador inicial conhecido. A documentacao tambem publica o par usuario/senha.

Impacto potencial:

Login administrativo por qualquer pessoa que acesse o ambiente em que as credenciais padrao nao foram alteradas.

Recomendacao:

Remover preenchimento automatico no app, gerar senha inicial aleatoria no provisionamento e exigir troca no primeiro acesso.

```dart
final email = TextEditingController();
final senha = TextEditingController();
```

---

## SEC-005 - CORS aberto para qualquer origem

Severidade: Media

OWASP: A02 Security Misconfiguration

CWE: CWE-942 Permissive Cross-domain Policy with Untrusted Domains

Localizacao:

- Arquivo: `backend/lib/api_helpers.dart`
- Constante: `corsHeaders`
- Linhas: 27-31
- Arquivo: `backend/bin/server.dart`
- Middleware CORS
- Linhas: 402-408

Evidencia:

```dart
const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers': 'Origin, Content-Type, Authorization',
};
```

Descricao:

A API permite chamadas de qualquer origem. Embora use bearer token, CORS irrestrito aumenta superficie para abuso por frontends nao confiaveis e dificulta controle de exposicao.

Impacto potencial:

Uso indevido da API por origens arbitrarias e maior risco em caso de vazamento de token.

Recomendacao:

Parametrizar origens permitidas por ambiente.

```dart
final allowedOrigin = env.allowedOrigin;
'access-control-allow-origin': allowedOrigin,
```

---

## SEC-006 - Ausencia de cabecalhos HTTP de seguranca

Severidade: Media

OWASP: A02 Security Misconfiguration

CWE: CWE-693 Protection Mechanism Failure

Localizacao:

- Arquivo: `backend/lib/api_helpers.dart`
- Funcao: `jsonResponse`
- Linhas: 12-20
- Arquivo: `backend/bin/server.dart`
- Middleware de resposta
- Linhas: 402-408

Evidencia:

```dart
headers: {
  'content-type': 'application/json; charset=utf-8',
  ...corsHeaders,
},
```

Descricao:

As respostas nao incluem cabecalhos como `X-Content-Type-Options`, `Referrer-Policy`, `Content-Security-Policy` ou `Strict-Transport-Security`.

Impacto potencial:

Maior exposicao a sniffing de conteudo, abuso de navegadores e configuracoes inseguras quando a API for usada por clientes web.

Recomendacao:

Adicionar middleware de headers seguros.

```dart
const securityHeaders = {
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'no-referrer',
  'content-security-policy': "default-src 'none'; frame-ancestors 'none'",
};
```

---

## SEC-007 - Trafego HTTP claro permitido no app Android

Severidade: Alta

OWASP: A02 Security Misconfiguration, A04 Cryptographic Failures

CWE: CWE-319 Cleartext Transmission of Sensitive Information

Localizacao:

- Arquivo: `mobile/android/app/src/main/AndroidManifest.xml`
- Linha: 8
- Arquivo: `mobile/lib/main.dart`
- Classe: `ApiClient`
- Linhas: 85-88

Evidencia:

```xml
android:usesCleartextTraffic="true"
```

```dart
defaultValue: 'http://10.0.2.2:8080',
```

Descricao:

O app permite trafego sem TLS e usa URL HTTP por padrao. Tokens bearer e dados pessoais trafegam sem protecao criptografica em redes nao confiaveis.

Impacto potencial:

Interceptacao de credenciais, tokens JWT e dados de associados por ataque man-in-the-middle.

Recomendacao:

Manter HTTP apenas em build/debug local e usar HTTPS em producao.

```xml
android:usesCleartextTraffic="false"
```

```dart
defaultValue: 'https://api.exemplo.com',
```

---

## SEC-008 - Controles de autorizacao amplos em dados sensiveis

Severidade: Alta

OWASP: A01 Broken Access Control

CWE: CWE-862 Missing Authorization, CWE-639 Authorization Bypass Through User-Controlled Key

Localizacao:

- Arquivo: `backend/bin/server.dart`
- Funcoes/rotas: associados, cobrancas, boletos, carteirinhas
- Linhas: 164-255, 258-331, 334-363

Evidencia:

```dart
router.get('/associados', (Request request) async {
  final blocked = requireAuth(request, env.jwtSecret);
```

```dart
router.get('/cobrancas/<id>/boleto.pdf', (Request request, String id) async {
  final blocked = requireAuth(request, env.jwtSecret);
```

Descricao:

Rotas que manipulam associados, cobrancas, boletos e carteirinhas exigem apenas autenticacao. Nao ha restricao por perfil nem verificacao de escopo/posse do recurso por ID.

Impacto potencial:

Um usuario autenticado com baixo privilegio pode consultar, editar ou gerar documentos de qualquer associado/cobranca, dependendo das regras reais esperadas.

Recomendacao:

Aplicar autorizacao por perfil e escopo em cada rota sensivel.

```dart
final blocked = requireAdmin(request, env.jwtSecret);
if (blocked != null) return blocked;
```

Quando houver usuarios nao administradores, validar explicitamente se o recurso pertence ao escopo permitido.

---

## SEC-009 - Ausencia de protecao contra brute force no login

Severidade: Alta

OWASP: A07 Identification and Authentication Failures

CWE: CWE-307 Improper Restriction of Excessive Authentication Attempts

Localizacao:

- Arquivo: `backend/bin/server.dart`
- Rota: `POST /auth/login`
- Linhas: 24-51

Evidencia:

```dart
router.post('/auth/login', (Request request) async {
  final body = await readJson(request);
```

Descricao:

Nao ha rate limiting, lockout temporario, atraso progressivo, captcha ou alerta para multiplas tentativas de login.

Impacto potencial:

Ataques de forca bruta ou credential stuffing contra contas administrativas.

Recomendacao:

Adicionar limitacao por IP/email e auditoria de falhas.

```dart
if (await rateLimiter.exceeded(email, request.context['ip'])) {
  return errorResponse(429, 'Muitas tentativas. Tente novamente mais tarde.');
}
```

---

## SEC-010 - MySQL exposto na interface do host

Severidade: Media

OWASP: A02 Security Misconfiguration

CWE: CWE-668 Exposure of Resource to Wrong Sphere

Localizacao:

- Arquivo: `docker-compose.yml`
- Linhas: 11-12

Evidencia:

```yaml
ports:
  - "3306:3306"
```

Descricao:

O banco MySQL e publicado na porta do host. Em maquinas com firewall permissivo, isso pode expor o banco para a rede.

Impacto potencial:

Tentativas externas de autenticacao no banco e exposicao direta do servico de dados.

Recomendacao:

Evitar publicar a porta quando apenas o backend precisa acessar o banco, ou limitar ao loopback.

```yaml
ports:
  - "127.0.0.1:3306:3306"
```

Ou remover `ports` e usar apenas rede interna do Docker.

---

## SEC-011 - Build release assinado com chave debug

Severidade: Alta

OWASP: A08 Software and Data Integrity Failures

CWE: CWE-321 Use of Hard-coded Cryptographic Key

Localizacao:

- Arquivo: `mobile/android/app/build.gradle.kts`
- Bloco: `buildTypes.release`
- Linhas: 28-33

Evidencia:

```kotlin
release {
    // TODO: Add your own signing config for the release build.
    // Signing with the debug keys for now, so `flutter run --release` works.
    signingConfig = signingConfigs.getByName("debug")
}
```

Descricao:

Builds release usam a chave debug. Essa chave nao e adequada para distribuicao e compromete a integridade da cadeia de publicacao.

Impacto potencial:

Distribuicao de APKs assinados com material previsivel ou inadequado, dificultando garantia de origem do app.

Recomendacao:

Criar signing config de release com keystore protegido por secrets fora do repositorio.

```kotlin
release {
    signingConfig = signingConfigs.getByName("release")
}
```

---

## SEC-012 - Validacao insuficiente de entradas em rotas de escrita

Severidade: Media

OWASP: A05 Injection, A10 Mishandling of Exceptional Conditions

CWE: CWE-20 Improper Input Validation

Localizacao:

- Arquivo: `backend/bin/server.dart`
- Rotas: usuarios, associacao, associados, cobrancas
- Linhas: 69-79, 98-108, 145-159, 198-219, 228-242, 306-317

Evidencia:

```dart
'status': body['status'] ?? 'ATIVO',
```

```dart
'vencimento': body['dataVencimento'],
```

Descricao:

Algumas entradas sao repassadas ao banco sem validacao rigorosa de formato, enum, tamanho, data ou email. O uso de parametros reduz risco de SQL injection, mas nao elimina falhas de integridade e abuso de dados.

Impacto potencial:

Dados invalidos, erros 500, estados inconsistentes e maior superficie para ataques de entrada malformada.

Recomendacao:

Centralizar validacoes por campo antes de executar SQL.

```dart
const statusPermitidos = {'ATIVO', 'INATIVO', 'INADIMPLENTE'};
if (!statusPermitidos.contains(status)) {
  return errorResponse(400, 'Status invalido');
}
```

---

## SEC-013 - Falta de auditoria de eventos sensiveis

Severidade: Media

OWASP: A09 Security Logging and Monitoring Failures

CWE: CWE-778 Insufficient Logging

Localizacao:

- Arquivo: `docker/init.sql`
- Tabela: `tb_auditoria`
- Linhas: 61-70
- Arquivo: `backend/bin/server.dart`
- Rotas sensiveis sem escrita de auditoria
- Linhas: 24-51, 65-129, 194-255, 302-331

Evidencia:

```sql
CREATE TABLE IF NOT EXISTS tb_auditoria (
```

Nao foram identificados inserts em `tb_auditoria` no backend.

Descricao:

Existe tabela de auditoria, mas o backend nao registra login, falha de login, criacao/alteracao/inativacao de usuarios, associados ou cobrancas.

Impacto potencial:

Dificuldade para detectar incidentes, investigar abuso de privilegio e rastrear alteracoes indevidas.

Recomendacao:

Registrar eventos sensiveis com usuario, acao, entidade, ID e detalhes minimos.

```dart
await db.execute(
  'INSERT INTO tb_auditoria (usuario_id, acao, entidade, entidade_id, detalhes) '
  'VALUES (:usuarioId, :acao, :entidade, :entidadeId, :detalhes)',
  params,
);
```

---

## SEC-014 - Excecoes de JSON e banco podem virar erro nao tratado

Severidade: Baixa

OWASP: A10 Mishandling of Exceptional Conditions

CWE: CWE-248 Uncaught Exception

Localizacao:

- Arquivo: `backend/lib/api_helpers.dart`
- Funcao: `readJson`
- Linhas: 33-37
- Arquivo: `backend/bin/server.dart`
- Rotas sem tratamento local de excecao
- Linhas: 24-413

Evidencia:

```dart
return jsonDecode(body) as Map<String, dynamic>;
```

Descricao:

JSON invalido, tipos inesperados ou falhas do banco podem disparar excecoes nao convertidas para respostas controladas. Isso pode gerar 500 generico e comportamento inconsistente.

Impacto potencial:

Negacao de servico pontual, falhas de experiencia e logs ruidosos; dependendo da configuracao, pode expor detalhes internos.

Recomendacao:

Tratar JSON invalido e criar middleware global de erro.

```dart
try {
  return jsonDecode(body) as Map<String, dynamic>;
} catch (_) {
  throw BadRequestException('JSON invalido');
}
```

---

## Observacoes positivas

- As consultas SQL revisadas usam parametros em chamadas como `db.execute(sql, params)`, reduzindo risco direto de SQL injection.
- O app usa `flutter_secure_storage` para persistir token JWT, o que e mais adequado do que armazenamento simples em texto.
- Tokens JWT possuem expiracao de 8 horas.

## Fora do escopo desta inspecao superficial

- Analise SAST automatizada completa.
- Teste dinamico de intrusao.
- Verificacao de vulnerabilidades conhecidas de dependencias contra bases CVE.
- Revisao criptografica profunda do formato de PDF gerado.
