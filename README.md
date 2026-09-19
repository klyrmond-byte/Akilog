# Akilog — projeto Flutter corrigido

O código original foi organizado e corrigido para um projeto Flutter.

## O que foi corrigido
- erros de sintaxe que impediam a compilação;
- seleção de foto pela câmera/galeria;
- armazenamento das imagens em Base64;
- filtros e lista de produtos;
- formulário de anúncio/edição;
- fluxo de compra e geração do código de rastreio;
- mensagens;
- conversões numéricas do Hive;
- armazenamento do cartão apenas com os 4 últimos dígitos.

## Importante sobre pagamento
A tela de Pix/cartão é apenas uma simulação visual. Ela não processa pagamentos reais nem se conecta a um banco ou gateway.

## Como gerar o APK no Windows

1. Instale o Flutter SDK e o Android Studio.
2. Abra o Prompt de Comando/PowerShell nesta pasta.
3. Execute:

```text
flutter create .
flutter pub get
flutter build apk --release
```

O APK será criado em:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Para testar diretamente em um celular Android conectado:

```text
flutter run
```

## Se `flutter create .` perguntar sobre arquivos existentes
Escolha manter os arquivos `lib/main.dart` e `pubspec.yaml` deste projeto. O comando cria a estrutura Android/Gradle necessária para a versão do Flutter instalada.

## Observação
Este ambiente de conversa não possui o Flutter SDK instalado, então não foi possível compilar o APK binário aqui. O projeto já está preparado para a etapa de `flutter build apk`.
