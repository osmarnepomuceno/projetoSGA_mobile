# Relato de Andamento do Trabalho

## Plataforma tecnologica escolhida

A plataforma tecnologica definida para o desenvolvimento do Sistema de Gerenciamento de Associacao foi:

- Backend em Dart, com API REST.
- Frontend mobile em Flutter, voltado inicialmente para Android.
- Banco de dados MySQL.
- Ambiente de desenvolvimento previsto com Android Studio, Android SDK, Android Emulator, Flutter SDK e Dart SDK.

Essa escolha foi feita porque Flutter e Dart permitem manter uma base tecnologica consistente entre o aplicativo mobile e parte da logica do backend, enquanto o MySQL atende bem a necessidade de armazenar usuarios, associados, cobrancas, carteirinhas, auditoria e dados da associacao.

## Instalacao do ambiente de desenvolvimento

O ambiente de desenvolvimento ja esta instalado, incluindo os principais recursos necessarios para o projeto: Dart SDK, Flutter SDK, Android Studio, Android SDK, Android Emulator e MySQL.

Com isso, a base para desenvolvimento ja esta disponivel. O proximo passo sera usar esse ambiente para criar a estrutura inicial do backend, do aplicativo mobile e do banco de dados.

## Inicio do projeto

O projeto ainda nao foi iniciado em codigo-fonte. No diretorio `projetoSGA`, existem atualmente documentos de planejamento e especificacao:

- `especificacao.md`, com a estrutura prevista do sistema, arquivos a serem criados, responsabilidades de backend, frontend, banco de dados, testes e documentacao.
- `testing.md`, com o plano de testes baseado em TDD First.

Ainda nao foram criadas as pastas principais de implementacao, como `backend`, `mobile`, `database` e `docs`, nem os arquivos iniciais como `pubspec.yaml`, `schema.sql`, `main.dart` ou `server.dart`.

Assim, o andamento atual esta na etapa de analise, especificacao e planejamento tecnico.

## Dificuldades encontradas

As principais dificuldades encontradas ate o momento foram:

- O projeto ainda esta apenas documentado, sem estrutura real de codigo criada.
- Apesar de o ambiente estar instalado, os codigos ainda nao foram iniciados.
- Sera preciso transformar a especificacao em uma estrutura real de projeto, criando primeiro os arquivos base do backend, do mobile e do banco de dados.
- Como a proposta envolve backend, aplicativo mobile e banco de dados, a integracao entre as partes exigira cuidado com configuracao de ambiente, URL da API, autenticacao JWT e acesso ao MySQL.

## Situacao atual

O trabalho esta em fase inicial. A concepcao tecnica esta bem definida nos documentos existentes e o ambiente de desenvolvimento ja esta instalado, mas a implementacao dos codigos ainda nao comecou. O proximo passo recomendado e criar a estrutura inicial do projeto, configurar o banco MySQL, iniciar o backend Dart e depois criar o aplicativo Flutter com as telas principais.
