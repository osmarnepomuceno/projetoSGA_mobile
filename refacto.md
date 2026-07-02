# Refatoracao do Fluxo de Boletos

## Objetivo

Alterar o fluxo de cobrancas/boletos para que o usuario selecione um associado antes de visualizar os boletos. Apos a selecao, o sistema lista apenas os boletos daquele associado e disponibiliza um botao para gerar o PDF de cada boleto.

## Alteracoes no aplicativo Flutter

Arquivo alterado:

- `mobile/lib/main.dart`

Principais mudancas:

- A tela de cobrancas passou a carregar a lista de associados.
- Foi adicionado um seletor de associado no topo da tela.
- Enquanto nenhum associado estiver selecionado, a tela exibe uma mensagem orientando a selecao.
- Ao selecionar um associado, a tela busca as cobrancas usando o filtro `associadoId`.
- A lista passa a exibir somente os boletos do associado selecionado.
- Cada boleto agora possui um botao com icone de PDF.
- Ao tocar no botao de PDF, o app chama o backend e salva o arquivo gerado no diretorio temporario do sistema.
- O dialogo de nova cobranca tambem passou a usar seletor de associado, substituindo o campo manual de ID.
- O metodo `ApiClient.getBytes()` foi adicionado para permitir baixar arquivos binarios, como PDF.
- O metodo `FuturePanel.reload()` foi corrigido para nao retornar `Future` dentro de `setState`.

## Alteracoes no backend Dart

Arquivo alterado:

- `backend/bin/server.dart`

Principais mudancas:

- O endpoint `GET /cobrancas` passou a aceitar o parametro opcional `associadoId`.
- Quando `associadoId` e informado, o backend retorna apenas as cobrancas daquele associado.
- Foi criado o endpoint `GET /cobrancas/{id}/boleto.pdf`.
- O novo endpoint busca a cobranca pelo ID, incluindo dados do associado.
- O backend gera um PDF simples e valido contendo:
  - numero do boleto;
  - nome do associado;
  - CPF do associado;
  - valor;
  - data de vencimento;
  - status;
  - linha digitavel simulada.
- O PDF e retornado com `content-type: application/pdf`.

## Endpoints envolvidos

Listagem de boletos por associado:

```http
GET /cobrancas?associadoId={id}
```

Geracao do PDF do boleto:

```http
GET /cobrancas/{id}/boleto.pdf
```

## Fluxo final

1. Usuario acessa a tela de cobrancas.
2. Usuario seleciona um associado.
3. App busca os boletos desse associado.
4. App lista os boletos encontrados.
5. Usuario toca no botao de PDF do boleto desejado.
6. Backend gera o PDF.
7. App salva o PDF gerado no diretorio temporario e mostra o caminho em uma mensagem.

## Verificacoes realizadas

Foram executados os seguintes comandos:

```powershell
dart analyze
flutter analyze
dart test
flutter build apk --debug
```

Resultado:

- backend sem problemas de analise;
- mobile sem problemas de analise;
- testes do backend aprovados;
- APK debug gerado com sucesso.
