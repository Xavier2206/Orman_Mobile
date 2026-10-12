# ORMAN Mobile

> Trabajo Final · Diplomado en Desarrollo Web y Aplicaciones Móviles · UAJMS 2026<br>
> Autor: `Xavier Ortega Mancilla` · Tutor: `<Nombre del tutor>`

## 1. Descripción

**ORMAN Mobile** es la aplicación Android para el **Inquilino**, desarrollada con Flutter. Permite iniciar sesión contra el Backend ORMAN, consultar contratos y cuotas, registrar pagos adjuntando comprobantes y revisar notificaciones.

La autenticación corresponde al Backend ORMAN. Firebase se utiliza en Android para notificaciones push; no se utiliza Firebase Authentication.

### Repositorios relacionados

| Componente | Repositorio |
|---|---|
| Backend | [Orman_Backend](https://github.com/Xavier2206/Orman_Backend) |
| Web | [Orman_Frontend](https://github.com/Xavier2206/Orman_Frontend) |
| Móvil | [Orman_Mobile](https://github.com/Xavier2206/Orman_Mobile) |

### Direcciones de producción

| Servicio | Dirección |
|---|---|
| Aplicación web | [https://orman-frontend.ortegaxavier75.workers.dev/](https://orman-frontend.ortegaxavier75.workers.dev/) |
| Backend | [https://orman-backend-e09w.onrender.com](https://orman-backend-e09w.onrender.com) |
| Salud del Backend | [https://orman-backend-e09w.onrender.com/api/v1/salud](https://orman-backend-e09w.onrender.com/api/v1/salud) |

El Backend público está disponible y el APK de entrega se compiló para esa dirección. El código fuente no la fija como valor predeterminado: `API_BASE_URL` se proporciona en tiempo de compilación mediante `--dart-define` y debe contener la URL base del Backend, **sin** `/api/v1`.

## 2. Stack tecnológico y versiones

Las restricciones indicadas corresponden a `pubspec.yaml`; las versiones resueltas corresponden a `pubspec.lock`. Los límites del SDK en el lockfile indican compatibilidad mínima, no la versión exacta instalada en cada equipo.

| Componente | Restricción o configuración declarada | Versión resuelta/configurada | Uso |
|---|---|---|---|
| Flutter | Sin versión exacta en `pubspec.yaml` | Mínimo compatible `>=3.44.0` en `pubspec.lock` | SDK de aplicación |
| Dart | `^3.12.2` | Compatibilidad `>=3.12.2 <4.0.0` en `pubspec.lock` | Lenguaje |
| Android SDK | `compileSdk`, `minSdk` y `targetSdk` delegados a Flutter | Valores provistos por el Flutter SDK usado al compilar | Plataforma Android |
| Java | Java 17 en Gradle | 17 | Compilación Android |
| Android Gradle Plugin | Configuración Gradle | 9.0.1 | Compilación Android |
| Kotlin | Configuración Gradle | 2.3.20 | Interoperabilidad Android |
| Gradle | Wrapper del proyecto | 9.1.0 | Compilación Android |
| Google Services Gradle Plugin | Configuración Gradle | 4.5.0 | Configuración Firebase Android |
| `dio` | `^5.11.1` | 5.11.1 | Cliente HTTP |
| `flutter_secure_storage` | `^11.2.0` | 11.2.0 | Almacenamiento de tokens |
| `shared_preferences` | `^2.5.3` | 2.5.5 | Preferencias locales |
| `device_info_plus` / `uuid` | `^13.2.0` / `^4.6.0` | 13.2.0 / 4.6.0 | Identidad e información de instalación/dispositivo |
| `flutter_svg` / `http_parser` | `^2.3.0` / `^4.1.2` | 2.3.0 / 4.1.2 | Recursos gráficos y manejo HTTP |
| `image_picker` / `gal` | `^1.2.3` / `^2.3.3` | 1.2.3 / 2.3.3 | Selección de comprobantes y guardado de imágenes QR |
| `firebase_core` / `firebase_messaging` | `^4.15.0` / `^16.7.0` | 4.15.0 / 16.7.0 | Inicialización y notificaciones push Android |
| `firebase_app_installations` | `^0.4.4` | 0.4.4 | Identificador de instalación Firebase |
| `flutter_local_notifications` | `^22.3.1` | 22.3.1 | Presentación local en foreground |
| `flutter_lints` / `flutter_launcher_icons` | `^6.0.0` / `^0.14.4` | 6.0.0 / 0.14.4 | Análisis estático e icono de aplicación |

La versión de aplicación declarada en `pubspec.yaml` es **1.0.0+1**. En Android corresponde a `versionName` 1.0.0 y `versionCode` 1.

## 3. Requisitos previos

- Flutter compatible con `>=3.44.0` y Dart compatible con `>=3.12.2 <4.0.0`.
- Android SDK y herramientas de compilación Android.
- Java 17 para la configuración Gradle actual.
- Android Studio o herramientas de línea de comandos de Android.
- Dispositivo Android físico o emulador.
- Backend ORMAN accesible desde el dispositivo.
- Para FCM en Android, el archivo cliente `android/app/google-services.json`, incluido en este repositorio.

## 4. Instalación y ejecución local

Clonar el repositorio e instalar las dependencias:

```bash
git clone https://github.com/Xavier2206/Orman_Mobile.git
cd Orman_Mobile
flutter pub get
```

### Ejecución con el Backend local en un dispositivo Android físico

Con el Backend local escuchando en el puerto `9090` del equipo de desarrollo, conectar el teléfono y comprobarlo con `adb devices`. Después, reenviar el puerto y ejecutar Flutter:

```bash
adb -s <device-id> reverse tcp:9090 tcp:9090
flutter run -d <device-id> --dart-define=API_BASE_URL=http://127.0.0.1:9090
```

En PowerShell, el comando de ejecución puede escribirse en una sola línea:

```powershell
flutter run -d <device-id> --dart-define=API_BASE_URL=http://127.0.0.1:9090
```

La configuración Android `google-services.json` es de cliente Firebase. La integración de Firebase documentada en este proyecto corresponde a notificaciones Android.

## 5. Configuración de API

Flutter recibe la dirección del Backend mediante `--dart-define`; la aplicación no carga un archivo `.env`.

| Variable | Descripción |
|---|---|
| `API_BASE_URL` | URL base HTTP(S) del Backend ORMAN. No añadir `/api/v1`; los endpoints de la API incluyen sus rutas y versión. |

En debug, si no se proporciona, el cliente usa `http://10.0.2.2:9090`, dirección del equipo anfitrión desde el emulador Android. Para el dispositivo físico con `adb reverse`, usar `http://127.0.0.1:9090`. Para la compilación de entrega se usó el Backend público indicado en la sección 1.

## 6. Estructura y arquitectura

```text
.
├── android/
├── assets/
├── lib/
│   ├── app/
│   ├── core/
│   ├── features/
│   │   ├── auth/
│   │   ├── contracts/
│   │   ├── notifications/
│   │   └── payments/
│   └── shared/
├── test/
├── pubspec.yaml
└── README.md
```

La organización sigue **Feature First** con una **Clean Architecture pragmática**: `lib/app/` agrupa arranque, configuración, tema y navegación; `lib/core/` contiene autenticación, red, almacenamiento y utilidades; `lib/features/` organiza las funciones por módulo; y `lib/shared/` contiene widgets reutilizables.

Los módulos móviles permiten iniciar y cerrar sesión, consultar contratos y cuotas, ver el detalle de una cuota y su QR de cobro, guardar la imagen QR, registrar un pago con imagen de comprobante y consultar la bandeja y el contador de notificaciones. Una notificación válida puede abrir el detalle de la cuota relacionada.

### Autenticación y sesión

La aplicación autentica al Inquilino mediante el Backend ORMAN. Los tokens se guardan usando `flutter_secure_storage`; las preferencias visuales se mantienen separadas en `shared_preferences`.

### API y notificaciones

La aplicación consume el Backend ORMAN con el contexto autenticado del Inquilino. Firebase se inicializa para Android y se usa para Firebase Cloud Messaging. Con una sesión autenticada, el cliente registra la instalación Android en el Backend mediante `PUT api/v1/mobile/push-installation`. La recepción de mensajes, la presentación local en foreground y la navegación desde una notificación se implementan en el cliente; la autenticación no corresponde a Firebase.

## 7. Cuentas para evaluación académica

Las cuentas de prueba para la evaluación académica se proporcionan en el apartado A4.4 del documento entregado al tribunal. La aplicación web corresponde al Propietario y la aplicación móvil al Inquilino.

## 8. Pruebas

El repositorio incluye pruebas unitarias y de widgets para autenticación y modelos de sesión, renovación de tokens, contratos, políticas y envío de pagos, notificaciones e instalación FCM, navegación y componentes de interfaz.

Para ejecutarlas desde la raíz del repositorio:

```bash
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Estos comandos describen cómo ejecutar las comprobaciones. La verificación del APK indicada en la sección siguiente no implica que se hayan ejecutado estas pruebas automatizadas.

## 9. APK de entrega y distribución

El APK preparado para la entrega académica tiene los siguientes datos:

- **Versión:** 1.0.0.
- **Número de compilación Android:** 1.
- **Archivo:** `ORMAN-1.0.0.apk`.
- **Ubicación relativa en el espacio de trabajo:** `build/entrega/ORMAN-1.0.0.apk`.
- **Backend configurado:** `https://orman-backend-e09w.onrender.com` mediante `API_BASE_URL`.
- **Firma:** clave propia de lanzamiento, certificado `ORMAN Mobile Release`; verificada con `apksigner` y esquema APK v2.

El comando de compilación utilizado para generar un APK release conectado al Backend de producción es:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://orman-backend-e09w.onrender.com
```

La firma release requiere una clave y una configuración privadas externas al repositorio, según la configuración Gradle actual. No se deben incorporar esos archivos privados al control de versiones.

### Comprobaciones comunicadas

- El agente verificó la compilación del APK, sus metadatos y su firma.
- El autor confirmó posteriormente la instalación y el funcionamiento en un teléfono Android; Android mostró la versión 1.0.0.
- No se registran aquí resultados de ejecución de pruebas automatizadas.

### Descargar APK

Para esta entrega se publicará un único APK directamente en el repositorio, dentro de `build/entrega/`, en la rama `main`:

- **Versión:** 1.0.0.
- **Número de compilación:** 1.
- **Archivo:** `ORMAN-1.0.0.apk`.
- **Descarga directa:** [ORMAN-1.0.0.apk](https://github.com/Xavier2206/Orman_Mobile/raw/refs/heads/main/build/entrega/ORMAN-1.0.0.apk).
- **Ver archivo en GitHub:** [ORMAN-1.0.0.apk](https://github.com/Xavier2206/Orman_Mobile/blob/main/build/entrega/ORMAN-1.0.0.apk).

La rama local y la rama publicada `origin/main` son `main`. Los enlaces apuntan a esa rama y quedarán disponibles después de que el autor haga commit y push; todavía no se afirma que funcionen. El directorio `build/` continúa excluido de Git y el resto de sus archivos generados permanece ignorado. GitHub Releases queda como alternativa futura de distribución.

## 10. Licencia

Uso académico. Todos los derechos reservados por el autor.
