# ECHOES — O Despertar

Marco B/C da expansão V2: O Despertar com cinco seções, sete Ecos e diálogos com retrato transparente. Consulte `../docs/DEVELOPMENT_LOG.md` e `../docs/GAMEPLAY_HANDOFF.md` para estado real, física, assets, testes e limitações. As fases 2/3 e os sistemas online ainda não estão implementados.

```powershell
flutter pub get
flutter run -d windows
# ou: flutter run -d chrome
```

A/D ou setas: mover. Espaço: pulo variável. Shift: dash. Esc/P: pausa. R: retornar ao checkpoint. Os mesmos comandos estão nos botões de toque. Colete o Coração do Lume e alcance o farol final; explore desvios para encontrar os outros Ecos. No diálogo, Espaço/Enter/toque revelam e avançam; Esc/Pular encerra. Memórias vistas podem ser revistas na pausa durante a sessão.

Verificação: `flutter analyze` e `flutter test`. Compilação: `flutter build web` ou `flutter build windows`. O runner Android está preparado, mas o ambiente auditado precisa resolver licenças do SDK e a compatibilidade Java/Gradle antes de compilar para Android.
