# Plano de Testes - TDD First

Projeto: **Sistema de Gerenciamento de Associação**

Base de referência: `E:\desenvolvimento_mobile\projetoSGA\especificacao.md`

Tecnologias previstas:

- Backend: Dart
- Frontend: Flutter
- Banco de dados: MySQL
- Testes automatizados: Dart Test, Flutter Test e mocks

---

## 1. Objetivo

Este plano define a estratégia de testes do Sistema de Gerenciamento de Associação com foco em **TDD First**. Cada funcionalidade deve iniciar por um teste automatizado falhando, seguido da implementação mínima necessária para aprovação e posterior refatoração segura.

O objetivo é validar regras críticas do sistema e impedir regressões durante alterações no backend Dart, no aplicativo Flutter e na integração com banco de dados MySQL.

---

## 2. Estratégia TDD First

Para cada funcionalidade, aplicar obrigatoriamente o ciclo:

```text
1. RED
   Escrever um teste automatizado para o comportamento esperado.
   Executar o teste.
   Confirmar que o teste falha pelo motivo esperado.

2. GREEN
   Implementar o menor código possível para o teste passar.
   Executar a suíte de testes.
   Confirmar que o teste passa.

3. REFACTOR
   Melhorar organização, nomes, duplicações e clareza do código.
   Executar novamente toda a suíte.
   Confirmar que nenhuma regressão foi introduzida.
```

Nenhuma funcionalidade crítica deve ser considerada concluída sem teste automatizado correspondente.

---

## 3. Dependências necessárias para testes

### Backend Dart

Arquivo: `E:\desenvolvimento_mobile\projetoSGA\backend\pubspec.yaml`

Dependências recomendadas:

```yaml
dev_dependencies:
  test: any
  mocktail: any
  lints: any
```

Dependências opcionais, conforme implementação:

```yaml
dev_dependencies:
  shelf_test_handler: any
```

Uso:

- `test`: execução dos testes unitários e de integração do backend.
- `mocktail`: criação de mocks para repositories, services e dependências externas.
- `lints`: padronização estática do código.
- `shelf_test_handler`: teste de handlers HTTP quando o backend usar Shelf.

### Frontend Flutter

Arquivo: `E:\desenvolvimento_mobile\projetoSGA\mobile\pubspec.yaml`

Dependências recomendadas:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: any
  flutter_lints: any
```

Dependências opcionais, conforme implementação:

```yaml
dev_dependencies:
  http_mock_adapter: any
  build_runner: any
```

Uso:

- `flutter_test`: testes de widget, controller e integração básica do app.
- `mocktail`: mocks de serviços, controllers, repositories e storage.
- `http_mock_adapter`: simulação de respostas HTTP quando o app usar Dio.
- `build_runner`: geração de código, caso sejam usados modelos anotados.
- `flutter_lints`: padronização estática do código Flutter.

---

## 4. Convenções da suíte de testes

### Backend

Os testes do backend devem seguir a estrutura:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\
├── services\
├── repositories\
├── controllers\
├── middlewares\
└── fixtures\
```

Padrão de nome:

```text
<classe_ou_funcionalidade>_test.dart
```

Exemplos:

```text
auth_service_test.dart
associado_service_test.dart
cobranca_controller_test.dart
```

### Frontend Flutter

Os testes do mobile devem seguir a estrutura:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\
├── features\
├── core\
├── shared\
└── fixtures\
```

Padrão de nome:

```text
<tela_ou_controller>_test.dart
```

Exemplos:

```text
login_page_test.dart
auth_controller_test.dart
associado_form_page_test.dart
```

---

## 5. Estratégia de mocks

Mocks devem ser usados sempre que a dependência real dificultar o teste determinístico.

### Dependências que devem ser mockadas

| Dependência | Motivo | Exemplo de mock |
|---|---|---|
| MySQL | Evitar banco real em testes unitários | `MockDatabase`, `MockUsuarioRepository` |
| Repositories | Isolar regras de negócio dos services | `MockAssociadoRepository` |
| JWT | Validar comportamento sem depender de chave real | `FakeJwtProvider` |
| Hash de senha | Evitar custo e variação de BCrypt em teste unitário | `FakePasswordHasher` |
| HTTP client no Flutter | Evitar chamadas reais ao backend | `MockApiClient` |
| Flutter Secure Storage | Evitar acesso real ao armazenamento do dispositivo | `MockAuthStorage` |
| Geração de PDF | Evitar arquivo real em teste unitário | `FakeDocumentGenerator` |

### Regra

Testes unitários não devem depender de:

- banco MySQL real;
- servidor HTTP real;
- Android Emulator;
- arquivos PDF reais;
- internet;
- relógio do sistema sem controle.

Quando houver regra baseada em data, usar data fixa por injeção de dependência.

---

## 6. Testes por funcionalidade

## 6.1 Autenticação

Prioridade: **crítica**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\services\auth_service_test.dart
```

Dependências simuladas:

- `UsuarioRepository`
- `PasswordHasher`
- `JwtProvider`

Testes:

```text
TESTE: login com e-mail inexistente deve retornar erro 401
DADO repository sem usuário para o e-mail informado
QUANDO AuthService.login for chamado
ENTÃO deve retornar erro 401

TESTE: login com senha incorreta deve retornar erro 401
DADO usuário ativo existente
E PasswordHasher retornando senha inválida
QUANDO AuthService.login for chamado
ENTÃO deve retornar erro 401

TESTE: login com usuário inativo deve retornar erro 403
DADO usuário existente com ativo = false
QUANDO AuthService.login for chamado
ENTÃO deve retornar erro 403

TESTE: login válido deve retornar JWT e dados públicos do usuário
DADO usuário ativo existente
E senha válida
QUANDO AuthService.login for chamado
ENTÃO deve retornar token
E deve retornar usuário sem senha_hash

TESTE: token gerado deve conter usuarioId, email e perfil
DADO login válido
QUANDO token for gerado
ENTÃO payload deve conter usuarioId, email e perfil
```

---

## 6.2 Autorização por perfil

Prioridade: **crítica**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\middlewares\role_middleware_test.dart
```

Dependências simuladas:

- contexto de requisição autenticada;
- handler HTTP fake.

Testes:

```text
TESTE: administrador deve acessar rota restrita a ADMINISTRADOR
DADO usuário autenticado com perfil ADMINISTRADOR
QUANDO acessar rota protegida por roleMiddleware([ADMINISTRADOR])
ENTÃO requisição deve ser encaminhada ao próximo handler

TESTE: atendente não deve acessar rota restrita a ADMINISTRADOR
DADO usuário autenticado com perfil ATENDENTE
QUANDO acessar rota protegida por roleMiddleware([ADMINISTRADOR])
ENTÃO deve retornar HTTP 403

TESTE: usuário sem perfil no contexto deve ser bloqueado
DADO requisição autenticada sem perfil
QUANDO acessar rota protegida
ENTÃO deve retornar HTTP 403
```

---

## 6.3 Usuários

Prioridade: **crítica**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\services\usuario_service_test.dart
```

Dependências simuladas:

- `UsuarioRepository`
- `AuditoriaService`
- `PasswordHasher`

Testes:

```text
TESTE: atendente não deve criar usuário
DADO usuarioAtual com perfil ATENDENTE
QUANDO criarUsuario for chamado
ENTÃO deve retornar erro 403

TESTE: administrador deve criar usuário com e-mail único
DADO usuarioAtual com perfil ADMINISTRADOR
E e-mail ainda não cadastrado
QUANDO criarUsuario for chamado
ENTÃO repository.create deve ser chamado
E senha deve ser armazenada como hash

TESTE: criação com e-mail duplicado deve falhar
DADO repository encontra usuário existente para o e-mail
QUANDO criarUsuario for chamado
ENTÃO deve retornar erro de conflito

TESTE: administrador não deve inativar o próprio usuário
DADO usuarioAtual.id igual ao id informado
QUANDO inativarUsuario for chamado
ENTÃO deve retornar erro de regra

TESTE: inativação válida deve registrar auditoria
DADO administrador autenticado
E id diferente do usuário atual
QUANDO inativarUsuario for chamado
ENTÃO repository.inativar deve ser chamado
E AuditoriaService deve registrar ação
```

---

## 6.4 Associação

Prioridade: **alta**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\services\associacao_service_test.dart
```

Dependências simuladas:

- `AssociacaoRepository`
- `AuditoriaService`

Testes:

```text
TESTE: consulta deve retornar associação existente
DADO repository com dados cadastrados
QUANDO getAtual for chamado
ENTÃO deve retornar nome, cnpj, endereço, telefone e email

TESTE: atualização com nome vazio deve falhar
DADO dados com nome vazio
QUANDO atualizar for chamado
ENTÃO deve retornar erro de validação

TESTE: atualização válida deve persistir dados
DADO dados válidos
QUANDO atualizar for chamado por ADMINISTRADOR
ENTÃO repository.update deve ser chamado
E auditoria deve ser registrada

TESTE: atendente não deve atualizar associação
DADO usuário com perfil ATENDENTE
QUANDO atualizar for chamado
ENTÃO deve retornar erro 403
```

---

## 6.5 Associados

Prioridade: **crítica**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\services\associado_service_test.dart
```

Dependências simuladas:

- `AssociadoRepository`
- `AuditoriaService`

Testes:

```text
TESTE: criação com nome vazio deve falhar
DADO dados com nome vazio
QUANDO criar for chamado
ENTÃO deve retornar erro de validação

TESTE: criação com CPF vazio deve falhar
DADO dados com CPF vazio
QUANDO criar for chamado
ENTÃO deve retornar erro de validação

TESTE: criação com CPF duplicado deve falhar
DADO repository informa CPF já existente
QUANDO criar for chamado
ENTÃO deve retornar erro de conflito

TESTE: criação válida deve definir status ATIVO quando status não for informado
DADO dados válidos sem status
QUANDO criar for chamado
ENTÃO status deve ser ATIVO
E repository.create deve ser chamado

TESTE: listagem deve validar pagina maior ou igual a 1
DADO pagina igual a 0
QUANDO listar for chamado
ENTÃO deve retornar erro de validação

TESTE: listagem deve limitar tamanhoPagina entre 1 e 100
DADO tamanhoPagina igual a 101
QUANDO listar for chamado
ENTÃO deve retornar erro de validação

TESTE: inativação deve alterar status para INATIVO
DADO associado existente
QUANDO inativar for chamado
ENTÃO repository.inativar deve ser chamado
E auditoria deve ser registrada
```

---

## 6.6 Cobranças

Prioridade: **crítica**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\services\cobranca_service_test.dart
```

Dependências simuladas:

- `CobrancaRepository`
- `AssociadoRepository`
- `AuditoriaService`

Testes:

```text
TESTE: criação com valor zero deve falhar
DADO cobrança com valor = 0
QUANDO criar for chamado
ENTÃO deve retornar erro de validação

TESTE: criação com associado inexistente deve falhar
DADO associado_id sem registro correspondente
QUANDO criar for chamado
ENTÃO deve retornar erro 404

TESTE: criação válida deve salvar cobrança ABERTA
DADO associado existente
E valor maior que zero
E data_vencimento válida
QUANDO criar for chamado
ENTÃO cobrança deve ser salva com status ABERTA

TESTE: marcar cobrança ABERTA como paga deve preencher data_pagamento
DADO cobrança com status ABERTA
QUANDO marcarComoPaga for chamado
ENTÃO status deve ser PAGA
E data_pagamento deve ser preenchida

TESTE: cobrança CANCELADA não deve ser marcada como paga
DADO cobrança com status CANCELADA
QUANDO marcarComoPaga for chamado
ENTÃO deve retornar erro de regra
```

---

## 6.7 Carteirinhas

Prioridade: **alta**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\services\carteirinha_service_test.dart
```

Dependências simuladas:

- `AssociadoRepository`
- `AssociacaoRepository`
- `CarteirinhaRepository`
- `DocumentGenerator`
- relógio fake com data fixa

Testes:

```text
TESTE: gerar carteirinha para associado inexistente deve retornar 404
DADO associadoId sem registro correspondente
QUANDO gerar for chamado
ENTÃO deve retornar erro 404

TESTE: geração válida deve usar dados do associado e associação
DADO associado existente
E associação cadastrada
QUANDO gerar for chamado
ENTÃO DocumentGenerator deve receber nome, CPF, status, associação, emissão e validade

TESTE: geração válida deve salvar registro de carteirinha
DADO geração de documento concluída
QUANDO gerar for chamado
ENTÃO CarteirinhaRepository.create deve ser chamado

TESTE: validade deve ser posterior ou igual à emissão
DADO data de emissão fixa
QUANDO gerar for chamado
ENTÃO data_validade deve ser maior ou igual à data_emissao
```

---

## 6.8 Relatórios e dashboard

Prioridade: **alta**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\services\relatorio_service_test.dart
```

Dependências simuladas:

- `RelatorioRepository`

Testes:

```text
TESTE: dashboard deve retornar todos os indicadores obrigatórios
DADO repository com totais simulados
QUANDO dashboard for chamado
ENTÃO resposta deve conter:
  associadosAtivos
  associadosInativos
  associadosInadimplentes
  cobrancasAbertas
  cobrancasPagas
  valorPagoMesAtual
  valorEmAberto

TESTE: dashboard deve retornar zero quando não houver registros
DADO repository sem dados
QUANDO dashboard for chamado
ENTÃO todos os totais numéricos devem ser 0

TESTE: dashboard não deve retornar campos nulos
DADO qualquer cenário válido
QUANDO dashboard for chamado
ENTÃO nenhum indicador obrigatório deve ser null
```

---

## 6.9 Controllers REST

Prioridade: **alta**

Arquivos alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\backend\test\controllers\auth_controller_test.dart
E:\desenvolvimento_mobile\projetoSGA\backend\test\controllers\associado_controller_test.dart
E:\desenvolvimento_mobile\projetoSGA\backend\test\controllers\cobranca_controller_test.dart
```

Dependências simuladas:

- services correspondentes;
- request/response HTTP fake.

Testes:

```text
TESTE: POST /auth/login sem email deve retornar 400
TESTE: POST /auth/login válido deve retornar 200 e token
TESTE: GET /associados sem token deve retornar 401
TESTE: POST /associados com JSON inválido deve retornar 400
TESTE: GET /associados/{id} inexistente deve retornar 404
TESTE: POST /cobrancas com valor inválido deve retornar 400
TESTE: PATCH /cobrancas/{id}/pagar válido deve retornar 200
```

---

## 6.10 Login no Flutter

Prioridade: **crítica**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\features\login\login_page_test.dart
```

Dependências simuladas:

- `AuthController`
- navegação fake

Testes:

```text
TESTE: tela deve exibir campos email, senha e botão Entrar
DADO LoginPage renderizada
ENTÃO campos email, senha e botão Entrar devem existir

TESTE: submit vazio deve exibir validações obrigatórias
DADO campos vazios
QUANDO usuário tocar em Entrar
ENTÃO mensagens de erro devem ser exibidas

TESTE: login válido deve navegar para dashboard
DADO AuthController.login retorna sucesso
QUANDO usuário informar credenciais válidas
ENTÃO app deve navegar para /dashboard

TESTE: login inválido deve exibir mensagem de erro
DADO AuthController.login retorna falha
QUANDO usuário informar credenciais inválidas
ENTÃO mensagem "Credenciais inválidas" deve ser exibida
```

---

## 6.11 Sessão e ApiClient no Flutter

Prioridade: **crítica**

Arquivos alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\core\auth\auth_storage_test.dart
E:\desenvolvimento_mobile\projetoSGA\mobile\test\core\network\api_client_test.dart
```

Dependências simuladas:

- `FlutterSecureStorage`
- cliente HTTP fake

Testes:

```text
TESTE: AuthStorage deve salvar token com chave jwt_token
TESTE: AuthStorage deve retornar null quando token não existir
TESTE: AuthStorage.clear deve remover token salvo
TESTE: ApiClient deve incluir Authorization quando token existir
TESTE: ApiClient não deve incluir Authorization quando token não existir
TESTE: resposta 401 deve limpar sessão local
```

---

## 6.12 Rotas e permissões no Flutter

Prioridade: **crítica**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\core\routes\app_router_test.dart
```

Dependências simuladas:

- estado autenticado;
- usuário com perfil ADMINISTRADOR;
- usuário com perfil ATENDENTE.

Testes:

```text
TESTE: usuário não autenticado deve ser redirecionado para /login
TESTE: usuário autenticado deve acessar /dashboard
TESTE: ADMINISTRADOR deve acessar /usuarios
TESTE: ATENDENTE deve ser bloqueado ao acessar /usuarios
TESTE: ADMINISTRADOR deve acessar /associacao
TESTE: ATENDENTE deve ser bloqueado ao acessar /associacao
```

---

## 6.13 Associados no Flutter

Prioridade: **alta**

Arquivos alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\features\associados\associados_page_test.dart
E:\desenvolvimento_mobile\projetoSGA\mobile\test\features\associados\associado_form_page_test.dart
```

Dependências simuladas:

- `ApiClient`
- repository/controller de associados.

Testes:

```text
TESTE: listagem deve exibir associados retornados pela API
TESTE: erro de API deve exibir mensagem e botão tentar novamente
TESTE: filtro por nome deve chamar endpoint com query nome
TESTE: formulário vazio deve exibir erro para nome, CPF, dataFiliacao e status
TESTE: cadastro válido deve chamar POST /associados
TESTE: edição válida deve chamar PUT /associados/{id}
TESTE: inativação deve pedir confirmação antes de chamar PATCH
```

---

## 6.14 Cobranças no Flutter

Prioridade: **alta**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\features\cobrancas\cobrancas_page_test.dart
```

Dependências simuladas:

- `ApiClient`
- controller de cobranças.

Testes:

```text
TESTE: tela deve listar cobranças retornadas pela API
TESTE: tela deve carregar associados antes da seleção de cobrança
TESTE: estado inicial sem associado deve orientar selecionar associado
TESTE: seleção de associado deve chamar GET /cobrancas?associadoId={id}
TESTE: associado sem cobranças deve exibir estado vazio "Nenhum boleto encontrado"
TESTE: boleto listado deve exibir número, valor, vencimento e status
TESTE: botão Gerar PDF deve chamar GET /cobrancas/{id}/boleto.pdf
TESTE: geração de PDF em andamento deve exibir feedback visual e evitar duplo toque
TESTE: erro ao gerar PDF deve exibir mensagem de falha sem remover a lista
TESTE: criação com valor vazio deve exibir validação
TESTE: criação sem associado selecionado deve exibir validação visual
TESTE: criação com vencimento vazio deve exibir validação visual
TESTE: criação com valor maior que zero deve chamar POST /cobrancas
TESTE: marcar como paga deve pedir confirmação
TESTE: confirmação deve chamar PATCH /cobrancas/{id}/pagar
TESTE: erro de API deve exibir mensagem de falha
TESTE: loading da tela deve exibir indicador acessível
TESTE: erro de carregamento deve exibir mensagem e botão Tentar novamente
TESTE: layout estreito deve manter ações do boleto sem overflow
TESTE: botões de PDF e pagamento devem possuir tooltip/rótulo acessível
TESTE: regressão visual deve validar estados carregando, erro, vazio e lista preenchida
TESTE: teste E2E deve selecionar associado, listar boletos e acionar geração de PDF
```

---

## 6.15 Carteirinhas no Flutter

Prioridade: **média**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\features\carteirinhas\carteirinhas_page_test.dart
```

Dependências simuladas:

- `ApiClient`
- serviço de visualização/compartilhamento de arquivo.

Testes:

```text
TESTE: selecionar associado deve buscar carteirinha existente
TESTE: ausência de carteirinha deve exibir opção Gerar Carteirinha
TESTE: gerar carteirinha deve chamar POST /carteirinhas/{associadoId}
TESTE: carteirinha gerada deve exibir emissão, validade e arquivo
TESTE: arquivo disponível deve habilitar visualizar ou compartilhar
```

---

## 6.16 Relatórios no Flutter

Prioridade: **alta**

Arquivo alvo:

```text
E:\desenvolvimento_mobile\projetoSGA\mobile\test\features\relatorios\relatorios_page_test.dart
```

Dependências simuladas:

- `ApiClient`

Testes:

```text
TESTE: tela deve exibir indicadores retornados pela API
TESTE: indicadores nulos devem ser exibidos como zero ou mensagem controlada
TESTE: erro de API deve exibir opção de tentar novamente
TESTE: filtro de período deve chamar endpoint com parâmetros corretos quando aplicável
```

---

## 7. Testes de integração

Prioridade: **alta**

Testes de integração devem validar contratos entre camadas, com dependências controladas.

### Backend com banco de teste

Executar somente em ambiente isolado.

```text
CRIAR banco db_sga_test
EXECUTAR schema.sql
EXECUTAR seed.sql
EXECUTAR testes de repositories
APAGAR dados após execução
```

Casos mínimos:

```text
TESTE: UsuarioRepository.create deve persistir usuário
TESTE: UsuarioRepository.findByEmail deve recuperar usuário persistido
TESTE: AssociadoRepository.create deve rejeitar CPF duplicado
TESTE: CobrancaRepository.create deve respeitar chave estrangeira de associado
TESTE: RelatorioRepository deve calcular totais com dados reais de teste
```

### Contrato HTTP

Casos mínimos:

```text
TESTE: POST /auth/login retorna JSON com token e usuario
TESTE: rotas protegidas sem token retornam 401
TESTE: rota administrativa com perfil ATENDENTE retorna 403
TESTE: GET /relatorios/dashboard retorna campos obrigatórios
```

---

## 8. Automação e regressão

Antes de qualquer entrega, executar:

### Backend

```powershell
cd E:\desenvolvimento_mobile\projetoSGA\backend
dart pub get
dart analyze
dart test
```

### Frontend Flutter

```powershell
cd E:\desenvolvimento_mobile\projetoSGA\mobile
flutter pub get
flutter analyze
flutter test
```

### Regra de regressão

Uma alteração só pode ser considerada segura quando:

```text
dart analyze não retornar erros
dart test passar 100%
flutter analyze não retornar erros
flutter test passar 100%
nenhum teste crítico for removido sem substituição equivalente
```

---

## 9. Ordem recomendada de implementação TDD

Implementar nesta sequência para reduzir dependências cruzadas:

```text
1. Modelos e validações puras
2. AuthService
3. Middlewares de autenticação e autorização
4. UsuarioService
5. AssociadoService
6. CobrancaService
7. CarteirinhaService
8. RelatorioService
9. Controllers REST
10. AuthStorage e ApiClient no Flutter
11. AuthController e LoginPage
12. Rotas protegidas
13. Dashboard
14. Associados
15. Usuários
16. Associação
17. Cobranças
18. Carteirinhas
19. Relatórios
20. Testes de integração e regressão completa
```

---

## 10. Critérios de aceite do plano de testes

O plano será considerado atendido quando:

```text
1. Cada funcionalidade crítica possuir pelo menos um teste automatizado.
2. Regras de autenticação e autorização possuírem testes positivos e negativos.
3. CRUDs principais possuírem testes de validação, sucesso e erro.
4. Fluxos Flutter críticos possuírem testes de widget ou controller.
5. Dependências externas forem mockadas em testes unitários.
6. Testes de integração usarem ambiente isolado.
7. Comandos de análise e teste puderem ser executados automaticamente.
8. A suíte completa impedir regressões em login, permissões, associados, cobranças, carteirinhas e relatórios.
```

---

## 11. Riscos cobertos pelos testes

| Risco | Cobertura prevista |
|---|---|
| Login aceitar senha inválida | `auth_service_test.dart` |
| Atendente acessar recurso administrativo | `role_middleware_test.dart` e `app_router_test.dart` |
| CPF duplicado em associado | `associado_service_test.dart` e teste de repository |
| Cobrança com valor inválido | `cobranca_service_test.dart` |
| Cobrança cancelada ser paga | `cobranca_service_test.dart` |
| Dashboard com totais incorretos | `relatorio_service_test.dart` |
| Token não enviado ao backend | `api_client_test.dart` |
| Sessão não ser limpa após 401 | `api_client_test.dart` |
| Formulários aceitarem campos obrigatórios vazios | testes de widget Flutter |
| Alteração futura quebrar fluxo crítico | execução automatizada da suíte |
