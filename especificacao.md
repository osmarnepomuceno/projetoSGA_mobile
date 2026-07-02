# Especificação do Sistema de Gerenciamento de Associação

Documento gerado a partir da descrição do projeto **Sistema de Gerenciamento de Associação**, concebido com **backend em Dart**, **frontend em Flutter** e **banco de dados MySQL**.

As especificações abaixo são determinísticas, granulares e sem ambiguidades. Cada item define o caminho do arquivo, a ação, a descrição e o pseudocódigo esperado.

---

## 1. Estrutura inicial do projeto

### E:\desenvolvimento_mobile\projetoSGA\README.md

- ação: criar
- descrição: Criar documentação inicial do projeto contendo nome do sistema, objetivo, tecnologias usadas, estrutura de diretórios e instruções básicas de execução.
- pseudocódigo:

```text
INICIAR documento README
DEFINIR título como "Sistema de Gerenciamento de Associação"
DESCREVER objetivo do sistema
LISTAR tecnologias:
  - Dart no backend
  - Flutter no frontend
  - MySQL no banco de dados
  - Android Studio como IDE
  - Android SDK e Android Emulator para testes
DESCREVER estrutura de diretórios:
  - backend
  - mobile
  - database
  - docs
INCLUIR comandos futuros para instalar dependências e executar o sistema
FINALIZAR documento
```

### E:\desenvolvimento_mobile\projetoSGA\.gitignore

- ação: criar
- descrição: Criar arquivo de exclusão do Git para impedir versionamento de arquivos temporários, dependências, builds, credenciais e configurações locais.
- pseudocódigo:

```text
CRIAR arquivo .gitignore
ADICIONAR padrões:
  - .dart_tool/
  - build/
  - .idea/
  - .vscode/
  - *.iml
  - .env
  - android/local.properties
  - pubspec.lock quando aplicável ao backend
  - arquivos temporários do sistema operacional
SALVAR arquivo
```

---

## 2. Banco de dados MySQL

### E:\desenvolvimento_mobile\projetoSGA\database\schema.sql

- ação: criar
- descrição: Criar script SQL determinístico com a estrutura inicial do banco MySQL, incluindo tabelas de usuários, associação, associados, cobranças, carteirinhas e auditoria.
- pseudocódigo:

```text
CRIAR banco de dados se não existir db_sga
SELECIONAR banco db_sga

CRIAR tabela tb_usuario com campos:
  id BIGINT chave primária auto incremento
  nome VARCHAR(120) obrigatório
  email VARCHAR(160) obrigatório único
  senha_hash VARCHAR(255) obrigatório
  perfil ENUM('ADMINISTRADOR','ATENDENTE') obrigatório
  ativo BOOLEAN obrigatório padrão true
  criado_em DATETIME obrigatório
  atualizado_em DATETIME opcional

CRIAR tabela tb_associacao com campos:
  id BIGINT chave primária auto incremento
  nome VARCHAR(160) obrigatório
  cnpj VARCHAR(20) opcional único
  endereco VARCHAR(255) opcional
  telefone VARCHAR(30) opcional
  email VARCHAR(160) opcional
  criado_em DATETIME obrigatório
  atualizado_em DATETIME opcional

CRIAR tabela tb_associado com campos:
  id BIGINT chave primária auto incremento
  nome VARCHAR(120) obrigatório
  cpf VARCHAR(14) obrigatório único
  telefone VARCHAR(30) opcional
  email VARCHAR(160) opcional
  endereco VARCHAR(255) opcional
  data_filiacao DATE obrigatório
  status ENUM('ATIVO','INATIVO','INADIMPLENTE') obrigatório
  criado_em DATETIME obrigatório
  atualizado_em DATETIME opcional

CRIAR tabela tb_cobranca com campos:
  id BIGINT chave primária auto incremento
  associado_id BIGINT obrigatório referenciando tb_associado.id
  valor DECIMAL(10,2) obrigatório
  data_vencimento DATE obrigatório
  data_pagamento DATE opcional
  status ENUM('ABERTA','PAGA','VENCIDA','CANCELADA') obrigatório
  criado_em DATETIME obrigatório
  atualizado_em DATETIME opcional

CRIAR tabela tb_carteirinha com campos:
  id BIGINT chave primária auto incremento
  associado_id BIGINT obrigatório referenciando tb_associado.id
  data_emissao DATE obrigatório
  data_validade DATE obrigatório
  arquivo_url VARCHAR(255) opcional
  criado_em DATETIME obrigatório

CRIAR tabela tb_auditoria com campos:
  id BIGINT chave primária auto incremento
  usuario_id BIGINT opcional referenciando tb_usuario.id
  acao VARCHAR(80) obrigatório
  entidade VARCHAR(80) obrigatório
  entidade_id BIGINT opcional
  detalhes TEXT opcional
  criado_em DATETIME obrigatório
```

### E:\desenvolvimento_mobile\projetoSGA\database\seed.sql

- ação: criar
- descrição: Criar script de carga inicial com administrador inicial e dados mínimos da associação.
- pseudocódigo:

```text
SELECIONAR banco db_sga
INSERIR registro inicial em tb_usuario somente se email ainda não existir:
  nome = "Administrador Inicial"
  email = valor definido para ADMIN_INITIAL_EMAIL
  senha_hash = hash da senha definida para ADMIN_INITIAL_PASSWORD
  perfil = "ADMINISTRADOR"
  ativo = true
  criado_em = data e hora atual

INSERIR registro inicial em tb_associacao somente se tabela estiver vazia:
  nome = "Associação"
  criado_em = data e hora atual
```

---

## 3. Backend em Dart

### E:\desenvolvimento_mobile\projetoSGA\backend\pubspec.yaml

- ação: criar
- descrição: Criar manifesto do backend Dart com dependências necessárias para API REST, MySQL, JWT, variáveis de ambiente, criptografia de senha e testes.
- pseudocódigo:

```text
DEFINIR nome do pacote como sga_backend
DEFINIR SDK mínimo compatível com Dart atual
ADICIONAR dependências:
  - shelf ou dart_frog para API REST
  - mysql_client ou mysql1 para MySQL
  - dart_jsonwebtoken para JWT
  - bcrypt ou equivalente para hash de senha
  - dotenv para variáveis de ambiente
  - json_annotation para serialização se necessário
ADICIONAR dependências de desenvolvimento:
  - test
  - lints
SALVAR manifesto
```

### E:\desenvolvimento_mobile\projetoSGA\backend\.env.example

- ação: criar
- descrição: Criar arquivo modelo de variáveis de ambiente exigidas pelo backend.
- pseudocódigo:

```text
CRIAR arquivo .env.example
DEFINIR variáveis:
  DB_HOST=localhost
  DB_PORT=3306
  DB_NAME=db_sga
  DB_USER=root
  DB_PASSWORD=
  JWT_SECRET_KEY=alterar_esta_chave
  ADMIN_INITIAL_EMAIL=admin@sga.com
  ADMIN_INITIAL_PASSWORD=admin123
  API_PORT=8080
SALVAR arquivo
```

### E:\desenvolvimento_mobile\projetoSGA\backend\bin\server.dart

- ação: criar
- descrição: Criar ponto de entrada do servidor backend Dart, carregando variáveis de ambiente, configurando rotas, middlewares e porta HTTP.
- pseudocódigo:

```text
INICIAR função main
CARREGAR variáveis do arquivo .env
VALIDAR presença de DB_HOST, DB_NAME, DB_USER, JWT_SECRET_KEY e API_PORT
CRIAR conexão com MySQL
EXECUTAR rotina de seed do administrador inicial se necessário
CRIAR router HTTP
REGISTRAR rotas:
  POST /auth/login
  GET /usuarios
  POST /usuarios
  PUT /usuarios/{id}
  PATCH /usuarios/{id}/inativar
  GET /associacao
  PUT /associacao
  GET /associados
  POST /associados
  GET /associados/{id}
  PUT /associados/{id}
  PATCH /associados/{id}/inativar
  GET /cobrancas
  POST /cobrancas
  PATCH /cobrancas/{id}/pagar
  GET /carteirinhas/{associadoId}
  POST /carteirinhas/{associadoId}
  GET /relatorios/dashboard
APLICAR middleware de log
APLICAR middleware de autenticação nas rotas protegidas
INICIAR servidor HTTP na porta API_PORT
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\config\env.dart

- ação: criar
- descrição: Criar classe de configuração responsável por ler e validar variáveis de ambiente do backend.
- pseudocódigo:

```text
DEFINIR classe Env
CRIAR método estático load
LER variáveis:
  DB_HOST
  DB_PORT
  DB_NAME
  DB_USER
  DB_PASSWORD
  JWT_SECRET_KEY
  API_PORT
  ADMIN_INITIAL_EMAIL
  ADMIN_INITIAL_PASSWORD
PARA cada variável obrigatória:
  SE valor estiver vazio
    LANÇAR erro de configuração
CONVERTER DB_PORT e API_PORT para inteiro
RETORNAR objeto Env imutável
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\config\database.dart

- ação: criar
- descrição: Criar configuração de conexão com MySQL e função para executar consultas parametrizadas.
- pseudocódigo:

```text
DEFINIR classe Database
RECEBER Env no construtor
CRIAR método connect
  ABRIR conexão com MySQL usando DB_HOST, DB_PORT, DB_NAME, DB_USER e DB_PASSWORD
  ARMAZENAR conexão ativa
CRIAR método query(sql, params)
  EXIGIR conexão ativa
  EXECUTAR SQL parametrizado
  RETORNAR resultado
CRIAR método close
  FECHAR conexão ativa se existir
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\models\usuario.dart

- ação: criar
- descrição: Criar modelo de usuário do sistema com campos, serialização e validação mínima.
- pseudocódigo:

```text
DEFINIR classe Usuario
DEFINIR campos:
  id
  nome
  email
  senhaHash
  perfil
  ativo
  criadoEm
  atualizadoEm
CRIAR construtor obrigatório para nome, email, perfil e ativo
CRIAR método fromMap para converter linha do MySQL em Usuario
CRIAR método toJson omitindo senhaHash
CRIAR validação:
  nome não pode ser vazio
  email deve conter "@"
  perfil deve ser ADMINISTRADOR ou ATENDENTE
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\models\associado.dart

- ação: criar
- descrição: Criar modelo de associado com dados cadastrais, status e datas de controle.
- pseudocódigo:

```text
DEFINIR classe Associado
DEFINIR campos:
  id
  nome
  cpf
  telefone
  email
  endereco
  dataFiliacao
  status
  criadoEm
  atualizadoEm
CRIAR método fromMap
CRIAR método toJson
CRIAR validação:
  nome não pode ser vazio
  cpf não pode ser vazio
  status deve ser ATIVO, INATIVO ou INADIMPLENTE
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\models\associacao.dart

- ação: criar
- descrição: Criar modelo de associação com dados institucionais usados em relatórios, cobranças e carteirinhas.
- pseudocódigo:

```text
DEFINIR classe Associacao
DEFINIR campos:
  id
  nome
  cnpj
  endereco
  telefone
  email
  criadoEm
  atualizadoEm
CRIAR método fromMap
CRIAR método toJson
CRIAR validação:
  nome não pode ser vazio
  email, quando informado, deve conter "@"
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\models\cobranca.dart

- ação: criar
- descrição: Criar modelo de cobrança vinculada a um associado.
- pseudocódigo:

```text
DEFINIR classe Cobranca
DEFINIR campos:
  id
  associadoId
  valor
  dataVencimento
  dataPagamento
  status
  criadoEm
  atualizadoEm
CRIAR método fromMap
CRIAR método toJson
CRIAR validação:
  associadoId deve ser maior que zero
  valor deve ser maior que zero
  dataVencimento deve existir
  status deve ser ABERTA, PAGA, VENCIDA ou CANCELADA
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\models\carteirinha.dart

- ação: criar
- descrição: Criar modelo de carteirinha vinculada a um associado.
- pseudocódigo:

```text
DEFINIR classe Carteirinha
DEFINIR campos:
  id
  associadoId
  dataEmissao
  dataValidade
  arquivoUrl
  criadoEm
CRIAR método fromMap
CRIAR método toJson
CRIAR validação:
  associadoId deve ser maior que zero
  dataValidade deve ser posterior ou igual a dataEmissao
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\repositories\usuario_repository.dart

- ação: criar
- descrição: Criar repositório de usuários com operações de consulta, criação, atualização e inativação no MySQL.
- pseudocódigo:

```text
DEFINIR classe UsuarioRepository
RECEBER Database no construtor
CRIAR método findByEmail(email)
  EXECUTAR SELECT em tb_usuario WHERE email = email LIMIT 1
  RETORNAR Usuario ou null
CRIAR método findById(id)
  EXECUTAR SELECT por id
  RETORNAR Usuario ou null
CRIAR método list()
  EXECUTAR SELECT ordenado por nome
  RETORNAR lista de Usuario
CRIAR método create(usuario)
  INSERIR nome, email, senha_hash, perfil, ativo e criado_em
  RETORNAR usuário criado
CRIAR método update(id, dados)
  ATUALIZAR nome, email, perfil, ativo e atualizado_em
  RETORNAR usuário atualizado
CRIAR método inativar(id)
  ATUALIZAR ativo para false
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\repositories\associado_repository.dart

- ação: criar
- descrição: Criar repositório de associados com paginação, filtro, cadastro, atualização e inativação.
- pseudocódigo:

```text
DEFINIR classe AssociadoRepository
RECEBER Database no construtor
CRIAR método list(filtro, pagina, tamanhoPagina)
  CALCULAR offset = (pagina - 1) * tamanhoPagina
  EXECUTAR SELECT em tb_associado com filtros opcionais de nome, cpf e status
  ORDENAR por nome
  LIMITAR por tamanhoPagina e offset
  RETORNAR lista de Associado
CRIAR método findById(id)
  EXECUTAR SELECT por id
  RETORNAR Associado ou null
CRIAR método create(associado)
  VALIDAR cpf único
  INSERIR registro
  RETORNAR associado criado
CRIAR método update(id, associado)
  ATUALIZAR campos permitidos
  RETORNAR associado atualizado
CRIAR método inativar(id)
  ATUALIZAR status para INATIVO
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\repositories\associacao_repository.dart

- ação: criar
- descrição: Criar repositório para consultar e atualizar os dados institucionais da associação.
- pseudocódigo:

```text
DEFINIR classe AssociacaoRepository
RECEBER Database no construtor
CRIAR método getAtual()
  CONSULTAR primeiro registro de tb_associacao
  RETORNAR Associacao ou null
CRIAR método update(dados)
  SE não existir associação
    INSERIR novo registro
  SENÃO
    ATUALIZAR registro existente
  RETORNAR dados atualizados
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\repositories\cobranca_repository.dart

- ação: criar
- descrição: Criar repositório de cobranças com operações de listagem, criação e marcação de pagamento.
- pseudocódigo:

```text
DEFINIR classe CobrancaRepository
RECEBER Database no construtor
CRIAR método list(filtros)
  CONSULTAR tb_cobranca com filtros opcionais de associado_id, status e vencimento
  ORDENAR por data_vencimento descendente
  RETORNAR lista de Cobranca
CRIAR método create(cobranca)
  VERIFICAR se associado existe
  INSERIR cobrança com status ABERTA
  RETORNAR cobrança criada
CRIAR método marcarComoPaga(id, dataPagamento)
  ATUALIZAR status para PAGA e data_pagamento
  RETORNAR cobrança atualizada
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\services\auth_service.dart

- ação: criar
- descrição: Criar serviço de autenticação com validação de credenciais, verificação de senha e geração de JWT.
- pseudocódigo:

```text
DEFINIR classe AuthService
RECEBER UsuarioRepository e Env no construtor
CRIAR método login(email, senha)
  BUSCAR usuário por email
  SE usuário não existir
    RETORNAR erro 401
  SE usuário estiver inativo
    RETORNAR erro 403
  VERIFICAR senha com hash armazenado
  SE senha inválida
    RETORNAR erro 401
  GERAR JWT contendo:
    usuarioId
    email
    perfil
    expiração
  RETORNAR token e dados públicos do usuário
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\services\usuario_service.dart

- ação: criar
- descrição: Criar serviço de regras de negócio para usuários, exigindo perfil administrador nas operações sensíveis.
- pseudocódigo:

```text
DEFINIR classe UsuarioService
CRIAR método criarUsuario(usuarioAtual, dados)
  EXIGIR usuarioAtual.perfil == ADMINISTRADOR
  VALIDAR nome, email, senha e perfil
  VERIFICAR email único
  GERAR senha_hash
  CHAMAR UsuarioRepository.create
  REGISTRAR auditoria
  RETORNAR usuário criado
CRIAR método atualizarUsuario(usuarioAtual, id, dados)
  EXIGIR perfil ADMINISTRADOR
  VALIDAR dados
  ATUALIZAR usuário
CRIAR método inativarUsuario(usuarioAtual, id)
  EXIGIR perfil ADMINISTRADOR
  IMPEDIR inativação do próprio usuário logado
  INATIVAR usuário
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\services\associado_service.dart

- ação: criar
- descrição: Criar serviço de regras para cadastro e manutenção de associados.
- pseudocódigo:

```text
DEFINIR classe AssociadoService
CRIAR método listar(filtros, pagina, tamanhoPagina)
  VALIDAR pagina maior ou igual a 1
  VALIDAR tamanhoPagina entre 1 e 100
  RETORNAR AssociadoRepository.list
CRIAR método criar(dados)
  VALIDAR campos obrigatórios
  VALIDAR CPF único
  DEFINIR status inicial como ATIVO se não informado
  SALVAR associado
  REGISTRAR auditoria
CRIAR método atualizar(id, dados)
  VERIFICAR se associado existe
  VALIDAR dados
  ATUALIZAR associado
  REGISTRAR auditoria
CRIAR método inativar(id)
  VERIFICAR se associado existe
  ALTERAR status para INATIVO
  REGISTRAR auditoria
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\services\cobranca_service.dart

- ação: criar
- descrição: Criar serviço para registro e acompanhamento de cobranças de associados.
- pseudocódigo:

```text
DEFINIR classe CobrancaService
CRIAR método criar(dados)
  VALIDAR associado_id
  VALIDAR valor maior que zero
  VALIDAR data_vencimento
  DEFINIR status inicial como ABERTA
  SALVAR cobrança
  REGISTRAR auditoria
CRIAR método listar(filtros)
  VALIDAR filtros permitidos
  RETORNAR cobranças
CRIAR método marcarComoPaga(id, dataPagamento)
  VERIFICAR se cobrança existe
  VERIFICAR status atual igual a ABERTA ou VENCIDA
  ATUALIZAR status para PAGA
  REGISTRAR auditoria
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\services\carteirinha_service.dart

- ação: criar
- descrição: Criar serviço para geração de carteirinha do associado em PDF ou imagem.
- pseudocódigo:

```text
DEFINIR classe CarteirinhaService
CRIAR método gerar(associadoId)
  BUSCAR associado por id
  SE associado não existir
    RETORNAR erro 404
  BUSCAR dados da associação
  DEFINIR data_emissao como data atual
  DEFINIR data_validade conforme regra de validade configurada
  GERAR arquivo de carteirinha com:
    nome do associado
    CPF
    status
    nome da associação
    data de emissão
    data de validade
  SALVAR registro em tb_carteirinha
  RETORNAR metadados e caminho do arquivo
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\services\relatorio_service.dart

- ação: criar
- descrição: Criar serviço para consolidar indicadores gerenciais do dashboard.
- pseudocódigo:

```text
DEFINIR classe RelatorioService
CRIAR método dashboard()
  CONSULTAR total de associados ativos
  CONSULTAR total de associados inativos
  CONSULTAR total de associados inadimplentes
  CONSULTAR total de cobranças abertas
  CONSULTAR total de cobranças pagas
  CONSULTAR soma de valores pagos no mês atual
  CONSULTAR soma de valores em aberto
  RETORNAR objeto JSON com todos os indicadores
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\middlewares\auth_middleware.dart

- ação: criar
- descrição: Criar middleware de autenticação para validar token JWT antes de acessar rotas protegidas.
- pseudocódigo:

```text
DEFINIR middleware authMiddleware
LER cabeçalho Authorization
SE cabeçalho não existir
  RETORNAR HTTP 401
EXTRAIR token do formato "Bearer <token>"
VALIDAR assinatura usando JWT_SECRET_KEY
SE token inválido ou expirado
  RETORNAR HTTP 401
ADICIONAR usuarioId, email e perfil ao contexto da requisição
ENCAMINHAR requisição para próximo handler
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\middlewares\role_middleware.dart

- ação: criar
- descrição: Criar middleware de autorização por perfil para bloquear ações exclusivas de administrador.
- pseudocódigo:

```text
DEFINIR middleware roleMiddleware(perfisPermitidos)
LER perfil do usuário autenticado no contexto
SE perfil não estiver em perfisPermitidos
  RETORNAR HTTP 403
SENÃO
  ENCAMINHAR requisição para próximo handler
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\controllers\auth_controller.dart

- ação: criar
- descrição: Criar controller de autenticação com endpoint de login.
- pseudocódigo:

```text
REGISTRAR rota POST /auth/login
LER corpo JSON
EXIGIR campos email e senha
CHAMAR AuthService.login(email, senha)
SE login for válido
  RETORNAR HTTP 200 com token e usuário
SENÃO
  RETORNAR erro HTTP correspondente
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\controllers\usuario_controller.dart

- ação: criar
- descrição: Criar controller REST para CRUD de usuários.
- pseudocódigo:

```text
REGISTRAR rotas:
  GET /usuarios
  POST /usuarios
  PUT /usuarios/{id}
  PATCH /usuarios/{id}/inativar
APLICAR authMiddleware em todas as rotas
APLICAR roleMiddleware ADMINISTRADOR em POST, PUT e PATCH
PARA GET:
  RETORNAR lista de usuários sem senha_hash
PARA POST:
  VALIDAR JSON
  CHAMAR UsuarioService.criarUsuario
PARA PUT:
  VALIDAR id numérico
  CHAMAR UsuarioService.atualizarUsuario
PARA PATCH:
  VALIDAR id numérico
  CHAMAR UsuarioService.inativarUsuario
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\controllers\associado_controller.dart

- ação: criar
- descrição: Criar controller REST para CRUD de associados com filtros e paginação.
- pseudocódigo:

```text
REGISTRAR rotas:
  GET /associados
  POST /associados
  GET /associados/{id}
  PUT /associados/{id}
  PATCH /associados/{id}/inativar
APLICAR authMiddleware em todas as rotas
PARA GET /associados:
  LER filtros nome, cpf, status, pagina e tamanhoPagina
  CHAMAR AssociadoService.listar
  RETORNAR lista paginada
PARA POST:
  LER JSON
  CHAMAR AssociadoService.criar
PARA GET /associados/{id}:
  VALIDAR id
  RETORNAR associado ou 404
PARA PUT:
  VALIDAR id e JSON
  CHAMAR AssociadoService.atualizar
PARA PATCH:
  VALIDAR id
  CHAMAR AssociadoService.inativar
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\controllers\associacao_controller.dart

- ação: criar
- descrição: Criar controller REST para consulta e atualização dos dados da associação.
- pseudocódigo:

```text
REGISTRAR rotas:
  GET /associacao
  PUT /associacao
APLICAR authMiddleware em todas as rotas
PARA GET:
  RETORNAR dados atuais da associação
PARA PUT:
  EXIGIR perfil ADMINISTRADOR
  VALIDAR JSON
  CHAMAR AssociacaoService.atualizar
  RETORNAR dados atualizados
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\controllers\cobranca_controller.dart

- ação: criar
- descrição: Criar controller REST para cobranças.
- pseudocódigo:

```text
REGISTRAR rotas:
  GET /cobrancas
  POST /cobrancas
  PATCH /cobrancas/{id}/pagar
APLICAR authMiddleware em todas as rotas
PARA GET:
  LER filtros associadoId, status e período
  CHAMAR CobrancaService.listar
PARA POST:
  VALIDAR JSON com associadoId, valor e dataVencimento
  CHAMAR CobrancaService.criar
PARA PATCH /pagar:
  VALIDAR id
  LER dataPagamento ou usar data atual
  CHAMAR CobrancaService.marcarComoPaga
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\controllers\carteirinha_controller.dart

- ação: criar
- descrição: Criar controller REST para geração e consulta de carteirinhas.
- pseudocódigo:

```text
REGISTRAR rotas:
  GET /carteirinhas/{associadoId}
  POST /carteirinhas/{associadoId}
APLICAR authMiddleware em todas as rotas
PARA GET:
  VALIDAR associadoId
  RETORNAR última carteirinha do associado ou 404
PARA POST:
  VALIDAR associadoId
  CHAMAR CarteirinhaService.gerar
  RETORNAR carteirinha gerada
```

### E:\desenvolvimento_mobile\projetoSGA\backend\lib\controllers\relatorio_controller.dart

- ação: criar
- descrição: Criar controller REST para indicadores gerenciais do dashboard.
- pseudocódigo:

```text
REGISTRAR rota GET /relatorios/dashboard
APLICAR authMiddleware
CHAMAR RelatorioService.dashboard
RETORNAR JSON com indicadores:
  associadosAtivos
  associadosInativos
  associadosInadimplentes
  cobrancasAbertas
  cobrancasPagas
  valorPagoMesAtual
  valorEmAberto
```

---

## 4. Frontend Flutter

### E:\desenvolvimento_mobile\projetoSGA\mobile\pubspec.yaml

- ação: criar
- descrição: Criar manifesto Flutter com dependências para navegação, requisições HTTP, armazenamento seguro, estado, internacionalização e documentos.
- pseudocódigo:

```text
DEFINIR nome do app como sga_mobile
DEFINIR SDK Flutter compatível
ADICIONAR dependências:
  - flutter
  - dio ou http
  - flutter_secure_storage
  - go_router
  - provider, riverpod ou flutter_bloc
  - intl
  - pdf
  - printing
ADICIONAR assets quando necessário
SALVAR arquivo
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\main.dart

- ação: criar
- descrição: Criar ponto de entrada do aplicativo Flutter com tema, rotas e inicialização dos serviços principais.
- pseudocódigo:

```text
INICIAR função main
EXECUTAR WidgetsFlutterBinding.ensureInitialized
CRIAR instância de AuthController
CARREGAR sessão salva em armazenamento seguro
CRIAR MaterialApp com:
  título "SGA"
  tema principal
  router configurado
EXECUTAR runApp
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\core\config\app_config.dart

- ação: criar
- descrição: Criar arquivo de configuração do app com URL base da API.
- pseudocódigo:

```text
DEFINIR classe AppConfig
DEFINIR constante apiBaseUrl
SE ambiente for desenvolvimento
  apiBaseUrl = "http://10.0.2.2:8080"
SENÃO
  apiBaseUrl = URL configurada para produção
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\core\network\api_client.dart

- ação: criar
- descrição: Criar cliente HTTP centralizado para comunicação com backend e inclusão automática do token JWT.
- pseudocódigo:

```text
DEFINIR classe ApiClient
RECEBER AuthStorage no construtor
CRIAR cliente HTTP com baseUrl = AppConfig.apiBaseUrl
ANTES de cada requisição:
  LER token salvo
  SE token existir
    ADICIONAR cabeçalho Authorization = "Bearer token"
AO receber resposta 401:
  LIMPAR sessão local
  REDIRECIONAR para login
CRIAR métodos get, post, put, patch e delete
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\core\auth\auth_storage.dart

- ação: criar
- descrição: Criar serviço local para salvar, ler e remover token JWT com armazenamento seguro.
- pseudocódigo:

```text
DEFINIR classe AuthStorage
CRIAR método saveToken(token)
  GRAVAR token em flutter_secure_storage com chave "jwt_token"
CRIAR método readToken()
  LER valor da chave "jwt_token"
  RETORNAR token ou null
CRIAR método clear()
  REMOVER chave "jwt_token"
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\core\routes\app_router.dart

- ação: criar
- descrição: Criar configuração de rotas protegidas do Flutter.
- pseudocódigo:

```text
DEFINIR rotas:
  /login -> LoginPage
  /dashboard -> DashboardPage
  /usuarios -> UsuariosPage
  /associacao -> AssociacaoPage
  /associados -> AssociadosPage
  /cobrancas -> CobrancasPage
  /carteirinhas -> CarteirinhasPage
  /relatorios -> RelatoriosPage
PARA cada rota diferente de /login:
  VERIFICAR se usuário está autenticado
  SE não autenticado
    REDIRECIONAR para /login
PARA rota /usuarios e /associacao:
  EXIGIR perfil ADMINISTRADOR
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\login\login_page.dart

- ação: criar
- descrição: Criar tela de login com campos de e-mail, senha, validação e botão de entrada.
- pseudocódigo:

```text
EXIBIR formulário com:
  campo email obrigatório
  campo senha obrigatório
  botão Entrar
AO clicar Entrar:
  VALIDAR campos
  SE inválidos
    EXIBIR mensagens de erro
  SENÃO
    CHAMAR AuthController.login
    SE sucesso
      NAVEGAR para /dashboard
    SE falha
      EXIBIR mensagem "Credenciais inválidas"
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\login\auth_controller.dart

- ação: criar
- descrição: Criar controlador de autenticação do app, responsável por login, logout e estado da sessão.
- pseudocódigo:

```text
DEFINIR classe AuthController
MANTER estado:
  usuarioAtual
  token
  carregando
CRIAR método login(email, senha)
  DEFINIR carregando = true
  ENVIAR POST /auth/login
  SE resposta 200
    SALVAR token no AuthStorage
    DEFINIR usuarioAtual
    RETORNAR sucesso
  SENÃO
    RETORNAR falha
  DEFINIR carregando = false
CRIAR método logout()
  LIMPAR token salvo
  LIMPAR usuarioAtual
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\dashboard\dashboard_page.dart

- ação: criar
- descrição: Criar tela inicial com indicadores gerenciais retornados pelo backend.
- pseudocódigo:

```text
AO abrir tela:
  CHAMAR GET /relatorios/dashboard
  EXIBIR indicador de carregamento
SE resposta for sucesso:
  EXIBIR cards:
    associados ativos
    associados inativos
    inadimplentes
    cobranças abertas
    cobranças pagas
    valor pago no mês
    valor em aberto
SE resposta falhar:
  EXIBIR mensagem de erro e botão tentar novamente
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\associados\associados_page.dart

- ação: criar
- descrição: Criar tela de listagem de associados com filtro, paginação e acesso a cadastro/edição.
- pseudocódigo:

```text
EXIBIR campos de filtro:
  nome
  cpf
  status
EXIBIR botão Buscar
AO abrir tela ou buscar:
  CHAMAR GET /associados com filtros e paginação
  EXIBIR lista de associados
PARA cada associado:
  EXIBIR nome, CPF e status
  EXIBIR ações editar, inativar e carteirinha
AO clicar Novo:
  ABRIR formulário de associado
AO clicar Editar:
  ABRIR formulário preenchido
AO clicar Inativar:
  CONFIRMAR ação
  CHAMAR PATCH /associados/{id}/inativar
  RECARREGAR lista
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\associados\associado_form_page.dart

- ação: criar
- descrição: Criar formulário de cadastro e edição de associado.
- pseudocódigo:

```text
EXIBIR campos:
  nome obrigatório
  cpf obrigatório
  telefone opcional
  email opcional
  endereco opcional
  dataFiliacao obrigatória
  status obrigatório
AO salvar:
  VALIDAR campos obrigatórios
  SE edição
    CHAMAR PUT /associados/{id}
  SENÃO
    CHAMAR POST /associados
  SE sucesso
    VOLTAR para lista
  SE erro
    EXIBIR mensagem retornada pela API
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\usuarios\usuarios_page.dart

- ação: criar
- descrição: Criar tela administrativa de usuários, visível apenas para perfil administrador.
- pseudocódigo:

```text
AO abrir tela:
  VERIFICAR perfil ADMINISTRADOR
  SE perfil diferente
    EXIBIR acesso negado
  SENÃO
    CHAMAR GET /usuarios
    EXIBIR lista de usuários
PERMITIR criar, editar e inativar usuário
AO inativar:
  CONFIRMAR ação
  CHAMAR PATCH /usuarios/{id}/inativar
  RECARREGAR lista
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\associacao\associacao_page.dart

- ação: criar
- descrição: Criar tela de manutenção dos dados da associação, restrita ao administrador.
- pseudocódigo:

```text
AO abrir tela:
  CHAMAR GET /associacao
  PREENCHER formulário com dados existentes
EXIBIR campos:
  nome obrigatório
  cnpj opcional
  endereço opcional
  telefone opcional
  email opcional
AO salvar:
  VALIDAR nome
  CHAMAR PUT /associacao
  EXIBIR mensagem de sucesso ou erro
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\cobrancas\cobrancas_page.dart

- ação: criar
- descrição: Criar tela de listagem e registro de cobranças, com fluxo visual de boleto por associado.
- pseudocódigo:

```text
EXIBIR filtros:
  associado
  status
  período de vencimento
AO abrir tela:
  EXIBIR estado de carregamento enquanto associados e cobranças forem carregados
  SE API retornar erro
    EXIBIR mensagem de erro e ação Tentar novamente
  SE nenhum associado estiver selecionado
    EXIBIR estado vazio orientando selecionar associado
AO selecionar associado:
  CHAMAR GET /cobrancas?associadoId={id}
  EXIBIR somente boletos/cobranças do associado selecionado
  SE associado não possuir cobranças
    EXIBIR estado vazio "Nenhum boleto encontrado"
AO buscar:
  CHAMAR GET /cobrancas com filtros
  EXIBIR lista de cobranças
PARA cada cobrança:
  EXIBIR identificação do boleto, valor, vencimento e status
  EXIBIR ação Gerar PDF do boleto com tooltip e rótulo acessível
  AO clicar Gerar PDF
    CHAMAR GET /cobrancas/{id}/boleto.pdf
    EXIBIR feedback de carregamento da ação
    AO concluir
      EXIBIR mensagem com confirmação de PDF gerado
    SE API retornar erro
      EXIBIR mensagem de erro
AO criar cobrança:
  EXIBIR formulário com associado, valor e vencimento
  VALIDAR visualmente associado, valor e vencimento antes de enviar
  CHAMAR POST /cobrancas
AO marcar como paga:
  CONFIRMAR ação
  CHAMAR PATCH /cobrancas/{id}/pagar
  RECARREGAR lista
REGRAS DE INTERFACE:
  manter consistência com Cards, ListTile, FilledButton, OutlinedButton e IconButton existentes
  manter espaçamento interno mínimo de 16px nas telas de lista
  evitar overflow dos botões de ação em telas estreitas
  manter textos de erro e estados vazios legíveis em mobile
  manter foco e rótulos acessíveis em campos e botões
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\carteirinhas\carteirinhas_page.dart

- ação: criar
- descrição: Criar tela para gerar e consultar carteirinhas de associados.
- pseudocódigo:

```text
PERMITIR selecionar associado
AO selecionar:
  CHAMAR GET /carteirinhas/{associadoId}
  SE existir carteirinha
    EXIBIR dados da última emissão
AO clicar Gerar Carteirinha:
  CHAMAR POST /carteirinhas/{associadoId}
  EXIBIR resultado com data de emissão, validade e arquivo
SE houver arquivo disponível:
  PERMITIR visualizar ou compartilhar
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\features\relatorios\relatorios_page.dart

- ação: criar
- descrição: Criar tela de relatórios gerenciais com indicadores e filtros.
- pseudocódigo:

```text
EXIBIR filtros de período quando aplicável
CHAMAR GET /relatorios/dashboard
EXIBIR indicadores consolidados
EXIBIR seções:
  inadimplência
  adesões
  associados ativos
  fluxo financeiro
SE API retornar erro:
  EXIBIR mensagem e opção de tentar novamente
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\lib\shared\widgets\app_menu.dart

- ação: criar
- descrição: Criar menu reutilizável com opções exibidas conforme perfil do usuário autenticado.
- pseudocódigo:

```text
LER perfil do usuário autenticado
EXIBIR item Dashboard para todos os usuários autenticados
EXIBIR item Associados para ADMINISTRADOR e ATENDENTE
EXIBIR item Cobranças para ADMINISTRADOR e ATENDENTE
EXIBIR item Carteirinhas para ADMINISTRADOR e ATENDENTE
EXIBIR item Relatórios para ADMINISTRADOR e ATENDENTE
EXIBIR item Usuários somente para ADMINISTRADOR
EXIBIR item Associação somente para ADMINISTRADOR
EXIBIR item Sair para todos
```

---

## 5. Testes

### E:\desenvolvimento_mobile\projetoSGA\backend\test\auth_service_test.dart

- ação: criar
- descrição: Criar testes unitários para autenticação.
- pseudocódigo:

```text
TESTAR login com email inexistente retorna erro 401
TESTAR login com senha incorreta retorna erro 401
TESTAR login com usuário inativo retorna erro 403
TESTAR login válido retorna token JWT e dados públicos do usuário
TESTAR token contém usuarioId, email e perfil
```

### E:\desenvolvimento_mobile\projetoSGA\backend\test\associado_service_test.dart

- ação: criar
- descrição: Criar testes unitários para regras de associados.
- pseudocódigo:

```text
TESTAR criação com nome vazio retorna erro de validação
TESTAR criação com CPF vazio retorna erro de validação
TESTAR criação com CPF duplicado retorna erro de conflito
TESTAR criação válida retorna associado com status ATIVO
TESTAR inativação altera status para INATIVO
```

### E:\desenvolvimento_mobile\projetoSGA\backend\test\cobranca_service_test.dart

- ação: criar
- descrição: Criar testes unitários para regras de cobrança.
- pseudocódigo:

```text
TESTAR criação com valor zero retorna erro
TESTAR criação com associado inexistente retorna erro 404
TESTAR criação válida retorna cobrança ABERTA
TESTAR marcar cobrança ABERTA como paga altera status para PAGA
TESTAR marcar cobrança CANCELADA como paga retorna erro de regra
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\test\login_page_test.dart

- ação: criar
- descrição: Criar teste de widget para a tela de login.
- pseudocódigo:

```text
RENDERIZAR LoginPage
VERIFICAR existência dos campos email e senha
CLICAR em Entrar sem preencher
VERIFICAR mensagens de campos obrigatórios
PREENCHER email e senha válidos
SIMULAR resposta de login com sucesso
VERIFICAR navegação para dashboard
```

### E:\desenvolvimento_mobile\projetoSGA\mobile\test\associado_form_test.dart

- ação: criar
- descrição: Criar teste de widget para formulário de associado.
- pseudocódigo:

```text
RENDERIZAR AssociadoFormPage
CLICAR em Salvar sem preencher campos
VERIFICAR erro em nome, cpf, dataFiliacao e status
PREENCHER campos obrigatórios
SIMULAR resposta de API com sucesso
VERIFICAR retorno para lista de associados
```

---

## 6. Documentação técnica

### E:\desenvolvimento_mobile\projetoSGA\docs\api.md

- ação: criar
- descrição: Criar documentação dos endpoints REST do backend.
- pseudocódigo:

```text
DOCUMENTAR endpoint POST /auth/login
DOCUMENTAR endpoints de usuários
DOCUMENTAR endpoints de associação
DOCUMENTAR endpoints de associados
DOCUMENTAR endpoints de cobranças
DOCUMENTAR endpoints de carteirinhas
DOCUMENTAR endpoint GET /relatorios/dashboard
PARA cada endpoint:
  INFORMAR método HTTP
  INFORMAR URL
  INFORMAR autenticação exigida
  INFORMAR perfil exigido quando houver
  INFORMAR exemplo de requisição
  INFORMAR exemplo de resposta de sucesso
  INFORMAR possíveis erros
```

### E:\desenvolvimento_mobile\projetoSGA\docs\modelo-dados.md

- ação: criar
- descrição: Criar documentação textual do modelo de dados MySQL.
- pseudocódigo:

```text
DESCREVER tabela tb_usuario
DESCREVER tabela tb_associacao
DESCREVER tabela tb_associado
DESCREVER tabela tb_cobranca
DESCREVER tabela tb_carteirinha
DESCREVER tabela tb_auditoria
PARA cada tabela:
  LISTAR campos
  LISTAR tipo de dado
  INFORMAR obrigatoriedade
  INFORMAR chaves primárias
  INFORMAR chaves estrangeiras
  INFORMAR regras de unicidade
```

### E:\desenvolvimento_mobile\projetoSGA\docs\execucao-local.md

- ação: criar
- descrição: Criar guia de execução local do sistema em ambiente de desenvolvimento.
- pseudocódigo:

```text
DOCUMENTAR pré-requisitos:
  Dart SDK
  Flutter SDK
  Android Studio
  Android SDK
  Android Emulator
  MySQL
DOCUMENTAR configuração do banco:
  criar schema
  executar seed
DOCUMENTAR configuração do backend:
  copiar .env.example para .env
  preencher variáveis
  instalar dependências
  executar servidor
DOCUMENTAR configuração do mobile:
  instalar dependências
  iniciar emulator
  executar app Flutter
DOCUMENTAR URL de API para Android Emulator:
  usar http://10.0.2.2:8080
```

---

## 7. Critérios determinísticos de aceite

### E:\desenvolvimento_mobile\projetoSGA\docs\criterios-aceite.md

- ação: criar
- descrição: Criar critérios objetivos para validar a entrega do sistema.
- pseudocódigo:

```text
CRITÉRIO 1:
  DADO usuário administrador válido
  QUANDO realizar login
  ENTÃO sistema deve retornar JWT e abrir dashboard

CRITÉRIO 2:
  DADO usuário atendente
  QUANDO acessar tela de usuários
  ENTÃO sistema deve bloquear acesso

CRITÉRIO 3:
  DADO administrador autenticado
  QUANDO cadastrar usuário com email novo
  ENTÃO usuário deve ser salvo ativo

CRITÉRIO 4:
  DADO associado com CPF já cadastrado
  QUANDO cadastrar novo associado com mesmo CPF
  ENTÃO sistema deve rejeitar cadastro

CRITÉRIO 5:
  DADO associado ativo existente
  QUANDO criar cobrança com valor maior que zero
  ENTÃO cobrança deve ser salva com status ABERTA

CRITÉRIO 6:
  DADO cobrança aberta existente
  QUANDO marcar como paga
  ENTÃO status deve mudar para PAGA e data_pagamento deve ser preenchida

CRITÉRIO 7:
  DADO associado existente
  QUANDO gerar carteirinha
  ENTÃO sistema deve criar registro com data_emissao e data_validade

CRITÉRIO 8:
  DADO dados cadastrados no sistema
  QUANDO acessar dashboard
  ENTÃO indicadores devem refletir os totais persistidos no MySQL
```
