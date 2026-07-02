# Sistema de Gerenciamento de Associacao

MVP com backend em Dart, aplicativo Flutter e MySQL 8 em Docker.

## Banco de dados

```powershell
docker compose up -d
```

## Backend

```powershell
cd backend
copy .env.example .env
dart pub get
dart run bin/server.dart
```

API: `http://localhost:8080`

Login inicial:

- Email: `admin@sga.com`
- Senha: `admin123`

### Verificacao do backend

```powershell
cd backend
dart analyze
dart test
```

## Frontend

```powershell
cd mobile
flutter pub get
flutter run
```

No Android Emulator, o app usa `http://10.0.2.2:8080`.

Para apontar o Flutter para o SDK Android local usado neste ambiente:

```powershell
flutter config --android-sdk E:\android\sdk
```

### Verificacao do frontend

```powershell
cd mobile
flutter analyze
flutter test
flutter build apk --debug
```

## Fluxo de boletos

Na tela de cobrancas, selecione um associado para listar os boletos vinculados a ele. Cada boleto exibido possui acao para gerar o PDF pelo endpoint `GET /cobrancas/{id}/boleto.pdf`.
