# Copilot Instructions for `trucai`

## Arquitectura General
- Proyecto Flutter multiplataforma (móvil, web, escritorio) ubicado en `lib/`.
- Entrypoint principal: `lib/main.dart`.
- Soporte para Android (`android/`), iOS (`ios/`), Linux (`linux/`), macOS (`macos/`), Windows (`windows/`), y Web (`web/`).
- Recursos y assets específicos de plataforma en sus respectivas carpetas (`ios/Runner/Assets.xcassets`, `web/`, etc).

## Flujos de Desarrollo
- **Compilar y ejecutar:**
  - Usar `flutter run` para desarrollo local.
  - Para plataformas específicas: `flutter run -d <plataforma>` (ej: `windows`, `chrome`, `android`).
- **Construir release:**
  - `flutter build <plataforma>` (ej: `flutter build apk`, `flutter build web`).
- **Pruebas:**
  - Ejecutar tests con `flutter test`.
  - Los tests están en `test/` (ejemplo: `test/widget_test.dart`).

## Convenciones y Patrones
- Código fuente principal en `lib/`.
- Mantener la lógica de UI en widgets y separar lógica de negocio en clases o servicios.
- Usar assets colocando archivos en las carpetas de plataforma o en `assets/` (si existe).
- No hay convenciones personalizadas documentadas en el README.

## Integraciones y Dependencias
- Las dependencias se gestionan en `pubspec.yaml`.
- Ejecutar `flutter pub get` tras modificar dependencias.
- No se detectan integraciones externas personalizadas en la estructura actual.

## Ejemplo de flujo típico
```sh
flutter pub get
flutter run -d windows
flutter test
```

## Archivos Clave
- `lib/main.dart`: punto de entrada de la app.
- `pubspec.yaml`: dependencias y configuración de assets.
- `test/`: pruebas automatizadas.
- Carpetas de plataforma: configuración y recursos específicos.

## Notas
- No se encontraron reglas o convenciones AI previas en el repositorio.
- Si se agregan convenciones, documentarlas aquí para agentes futuros.
