# ORMAN

> Trabajo Final · Diplomado en Desarrollo Web y Aplicaciones Móviles · UAJMS 2026  
> Autor: <Nombre completo> · Tutor: <Nombre del tutor>

## 1. Descripción

ORMAN es un sistema orientado a la administración de alquileres de propiedades, diseñado para centralizar la gestión de propietarios, inquilinos, propiedades, unidades, contratos, cuotas, pagos y notificaciones.

El sistema busca facilitar el seguimiento de los alquileres, el control de cuotas y pagos, la revisión de comprobantes y la comunicación de eventos relevantes entre la propietaria y los inquilinos.

Este repositorio contiene el **Backend de ORMAN**, desarrollado con Java y Spring Boot. El Backend expone la API REST utilizada por las aplicaciones web y móvil y centraliza la lógica de negocio, autenticación, autorización, persistencia, seguridad y entrega de notificaciones.

**Sistema desplegado:** <pendiente / URL pública del Backend>

**Aplicaciones cliente:**

- Frontend web: Angular.
- Aplicación móvil: Flutter para Android.

---

## 2. Stack tecnológico

| Componente | Versión | Función |
|---|---:|---|
| Java | 21 | Lenguaje principal del Backend |
| Spring Boot | 4.1.0 | Framework principal de la aplicación |
| Maven / Maven Wrapper | — | Gestión de dependencias, compilación y pruebas |
| PostgreSQL | 17.x | Base de datos relacional |
| Spring Data JPA | — | Acceso y persistencia de datos |
| Hibernate | — | ORM y validación del esquema |
| Flyway | — | Migraciones versionadas de base de datos |
| Spring Security | — | Autenticación y autorización |
| JWT | — | Access tokens y refresh tokens |
| BCrypt | — | Hash seguro de contraseñas |
| Bean Validation | — | Validación de datos de entrada |
| Lombok | — | Reducción de código repetitivo |
| REST API | `/api/v1` | Comunicación con aplicaciones cliente |
| WebSocket / STOMP | `/ws` | Notificaciones en tiempo real para clientes web |
| Firebase Admin SDK | 9.11.0 | Integración del Backend con Firebase |
| Firebase Cloud Messaging | FCM | Notificaciones push para Android |
| PostgreSQL + Flyway | — | Persistencia y evolución controlada del esquema |

### Arquitectura

El Backend utiliza una arquitectura de **monolito modular**, organizada por funcionalidades.

La aplicación separa las responsabilidades principales en:

- controladores REST;
- servicios de negocio;
- repositorios;
- entidades JPA;
- DTO de entrada y salida;
- mappers;
- validaciones;
- manejo centralizado de errores;
- seguridad y autenticación;
- sesiones por dispositivo;
- notificaciones internas;
- comunicación en tiempo real mediante WebSocket;
- integración con Firebase Cloud Messaging.

Las entidades de persistencia no se exponen directamente mediante la API.

### Funcionalidades principales

El Backend incluye soporte para:

- gestión de personas;
- gestión de usuarios;
- catálogo fijo de roles funcionales (`PROPIETARIO` e `INQUILINO`);
- asignación de roles a usuarios;
- autenticación directa mediante usuario/contraseña y JWT;
- access token y refresh token;
- refresh WEB mediante cookie HttpOnly;
- protección XSRF/CSRF para las operaciones WEB que corresponden;
- sesiones diferenciadas por dispositivo;
- gestión de menús y procesos;
- administración de propiedades y unidades;
- registro de fotografías asociadas;
- gestión de contratos;
- administración de cuotas;
- registro de pagos;
- registro de comprobantes de pago;
- confirmación y rechazo de pagos;
- generación de códigos QR para cobros;
- gestión de cuentas de pago;
- notificaciones internas;
- notificaciones en tiempo real mediante WebSocket;
- notificaciones push Android mediante FCM;
- registro de instalaciones móviles;
- control de acceso basado en roles;
- login WEB directo mediante usuario y contraseña;
- catálogo de roles restringido a `PROPIETARIO` e `INQUILINO`.

### Zona horaria

ORMAN está orientado al contexto boliviano.

La zona horaria oficial utilizada para las reglas de negocio es:

```text
America/La_Paz
```

Las fechas y horas funcionales visibles para el usuario, como registros de pagos, revisiones, notificaciones y otras operaciones de negocio, utilizan la hora de Bolivia.

Los tiempos estrictamente técnicos, como expiraciones JWT y sesiones, conservan su semántica de instante técnico cuando corresponde.

---

## 3. Requisitos previos

Para ejecutar el Backend en un entorno local se requiere:

- JDK 21;
- PostgreSQL 17 o compatible;
- Git;
- Maven Wrapper incluido en el proyecto.

No es necesario instalar Maven globalmente porque el repositorio incluye:

```text
mvnw
mvnw.cmd
```

Para utilizar las notificaciones push también se necesita:

- proyecto configurado en Firebase;
- Firebase Cloud Messaging habilitado;
- cuenta de servicio de Firebase Admin;
- archivo JSON de credenciales almacenado fuera del repositorio.

---

## 4. Instalación local

### 4.1. Clonar el repositorio

```bash
git clone <url-del-repositorio-backend>
cd <carpeta-del-backend>
```

### 4.2. Preparar PostgreSQL

Crear una base de datos para ORMAN.

Ejemplo:

```text
orman
```

Configurar las variables correspondientes:

```text
DB_HOST
DB_PORT
DB_NAME
DB_USERNAME
DB_PASSWORD
```

Ejemplo en PowerShell:

```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_NAME = "orman"
$env:DB_USERNAME = "<usuario>"
$env:DB_PASSWORD = "<contraseña>"
```

Los cambios del esquema son administrados mediante Flyway.

Al iniciar la aplicación, Flyway valida y aplica automáticamente las migraciones pendientes.

Hibernate se utiliza para validar el esquema y no para generar automáticamente las tablas.

### 4.3. Configurar seguridad

Definir como mínimo los secretos necesarios para el entorno.

Ejemplo:

```powershell
$env:JWT_SECRET = "<secreto-seguro>"
```

Para generar un valor aleatorio puede utilizarse:

```powershell
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

Los valores generados no deben publicarse ni incluirse en Git.

### 4.4. Configurar Firebase Cloud Messaging

Las notificaciones push Android requieren:

```text
ORMAN_FIREBASE_ENABLED
ORMAN_FIREBASE_PROJECT_ID
GOOGLE_APPLICATION_CREDENTIALS
```

Ejemplo:

```text
ORMAN_FIREBASE_ENABLED=true
ORMAN_FIREBASE_PROJECT_ID=<firebase-project-id>
GOOGLE_APPLICATION_CREDENTIALS=<ruta-al-service-account.json>
```

`GOOGLE_APPLICATION_CREDENTIALS` debe apuntar al archivo JSON de una cuenta de servicio de Firebase.

Ese archivo es una **credencial privada** y nunca debe almacenarse dentro del repositorio.

Ejemplo de ubicación local:

```text
C:\ORMAN_SECRETS\firebase-service-account.json
```

No debe:

- subirse a GitHub;
- copiarse dentro de `src/main/resources`;
- incluirse en un commit;
- publicarse en documentación;
- compartirse públicamente.

#### Ejecutar Firebase desde PowerShell

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\ORMAN_SECRETS\firebase-service-account.json'
$env:ORMAN_FIREBASE_PROJECT_ID = '<firebase-project-id>'
$env:ORMAN_FIREBASE_ENABLED = 'true'

.\mvnw.cmd spring-boot:run
```

Las variables deben definirse en la misma terminal desde la que se inicia Spring Boot.

#### Ejecutar Firebase desde IntelliJ IDEA

Abrir:

```text
Run
→ Edit Configurations...
→ OrmanBackendApplication
→ Environment variables
```

Agregar:

```text
ORMAN_FIREBASE_ENABLED=true
ORMAN_FIREBASE_PROJECT_ID=<firebase-project-id>
GOOGLE_APPLICATION_CREDENTIALS=<ruta-al-service-account.json>
```

También puede utilizarse `EnvFile` para cargar un `.env` local.

Debe comprobarse que IntelliJ transfiera las variables al proceso Java que ejecuta Spring Boot.

### 4.5. Ejecutar el Backend

En Windows:

```powershell
.\mvnw.cmd spring-boot:run
```

En Linux/macOS:

```bash
./mvnw spring-boot:run
```

La API queda disponible por defecto en:

```text
http://localhost:9090
```

Los endpoints principales utilizan el prefijo:

```text
/api/v1
```

### 4.6. Compilar

Windows:

```powershell
.\mvnw.cmd clean package
```

Linux/macOS:

```bash
./mvnw clean package
```

El artefacto generado se almacena en:

```text
target/
```

---

## 5. Variables de entorno

Las variables requeridas por el proyecto se documentan mediante:

```text
.env.example
```

El archivo real:

```text
.env
```

es local y **nunca debe versionarse**.

> La existencia de un archivo `.env` no implica que Spring Boot o Firebase lo carguen automáticamente. Las variables deben estar disponibles en el proceso Java o ser cargadas explícitamente por el IDE.

| Variable | Obligatoria | Descripción |
|---|---|---|
| `DB_HOST` | Sí | Host del servidor PostgreSQL |
| `DB_PORT` | Sí | Puerto de PostgreSQL |
| `DB_NAME` | Sí | Nombre de la base de datos |
| `DB_USERNAME` | Sí | Usuario de PostgreSQL |
| `DB_PASSWORD` | Sí | Contraseña de PostgreSQL |
| `JWT_SECRET` | Sí | Secreto utilizado para firmar y validar JWT |
| `ORMAN_FRONTEND_URL` | Sí | URL permitida para el frontend web |
| `ORMAN_FIREBASE_ENABLED` | No | Activa o desactiva la integración con Firebase |
| `ORMAN_FIREBASE_PROJECT_ID` | Si FCM está activo | Identificador del proyecto Firebase |
| `GOOGLE_APPLICATION_CREDENTIALS` | Si FCM está activo | Ruta al JSON privado de Firebase Admin |

### Archivos sensibles

Nunca deben incluirse en Git:

```text
.env
firebase-adminsdk-*.json
service-account*.json
claves privadas
tokens
contraseñas
credenciales
logs con información sensible
```

Las credenciales de Firebase Admin deben mantenerse fuera del repositorio.

---

## 6. Estructura del repositorio

La estructura principal del Backend es:

```text
.
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/orman/backend/
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/
│   │           └── migration/
│   └── test/
│       ├── java/
│       └── resources/
├── mvnw
├── mvnw.cmd
├── pom.xml
├── .env.example
└── README.md
```

La organización interna de:

```text
com/orman/backend/
```

se divide por módulos funcionales.

Entre ellos se encuentran funcionalidades relacionadas con:

```text
auth
usuarios
personas
propiedades
contratos
cuotas
pagos
notificaciones
push
seguridad
```

Los archivos generados durante la ejecución no forman parte del código fuente.

Entre los directorios excluidos se encuentran:

```text
.env
docs/
storage/
target/
.idea/
.vscode/
```

### Base de datos y migraciones

Las migraciones de Flyway se encuentran en:

```text
src/main/resources/db/migration/
```

No deben modificarse migraciones que ya hayan sido aplicadas.

Los nuevos cambios de esquema deben incorporarse mediante una nueva migración versionada.

Las migraciones recientes relacionadas con la simplificación de autenticación y roles son:

```text
V22__fijar_catalogo_roles.sql
V23__retirar_otp_login.sql
```

`V22` fija el catálogo funcional de roles en `PROPIETARIO` e `INQUILINO`. `V23` retira la persistencia utilizada por el antiguo segundo paso OTP del login.

---

## 7. Roles y credenciales de prueba

ORMAN utiliza control de acceso basado en roles.

ORMAN utiliza un catálogo funcional fijo de dos roles: `PROPIETARIO` e `INQUILINO`. Las asignaciones de usuarios, menús y procesos se gestionan sobre estos roles.

| Rol | Usuario | Contraseña |
|---|---|---|
| PROPIETARIO | <usuario de prueba> | <ver documento entregado a la coordinación> |
| INQUILINO | <usuario de prueba> | <ver documento entregado a la coordinación> |

> Las credenciales de prueba se proporcionan a la coordinación o al tribunal por un canal privado. No se publican contraseñas en este repositorio.

Las sesiones de usuario están diferenciadas por dispositivo y pueden ser revocadas según las reglas de seguridad del sistema.

---

## 8. Pruebas

El proyecto incluye pruebas automatizadas para validar las diferentes capas y reglas de negocio.

### Ejecutar pruebas

Windows:

```powershell
.\mvnw.cmd test
```

Para ejecutar la suite completa desde cero:

```powershell
.\mvnw.cmd clean test
```

Linux/macOS:

```bash
./mvnw clean test
```

### Alcance de las pruebas

La suite permite validar, entre otros aspectos:

- lógica de negocio;
- persistencia;
- contratos HTTP;
- validaciones;
- autenticación;
- autorización;
- sesiones;
- refresh tokens;
- usuarios y roles;
- contratos;
- cuotas;
- pagos;
- comprobantes;
- notificaciones;
- WebSocket;
- Firebase Cloud Messaging;
- dispositivos push;
- restricciones de base de datos;
- manejo de errores;
- zona horaria y comportamiento temporal.

La tabla completa de casos de prueba y sus evidencias se documenta en el apartado correspondiente del documento monográfico.

### Notificaciones

ORMAN utiliza PostgreSQL y la API REST como fuente de verdad de las notificaciones.

Endpoints principales:

```text
GET   /api/v1/notificaciones
GET   /api/v1/notificaciones/{codnot}
GET   /api/v1/notificaciones/resumen
PATCH /api/v1/notificaciones/{codnot}/leer
```

#### WebSocket

El endpoint WebSocket es:

```text
/ws
```

Las notificaciones privadas se entregan mediante:

```text
/user/queue/notificaciones
```

WebSocket permite avisar al cliente web para que actualice los datos mediante REST.

#### Firebase Cloud Messaging

La aplicación Android utiliza FCM para recibir notificaciones push.

Actualmente el flujo móvil contempla eventos como:

```text
PAGO_CONFIRMADO
PAGO_RECHAZADO
CUOTA_PROXIMA_VENCER
CUOTA_VENCIDA
```

El Backend persiste primero la notificación y posteriormente intenta entregarla mediante los canales disponibles.

Una falla de Firebase no debe revertir la operación de negocio que originó la notificación.

#### Registro de instalaciones móviles

Registro:

```text
PUT /api/v1/mobile/push-installation
```

Eliminación o desactivación de la asociación correspondiente a la sesión:

```text
DELETE /api/v1/mobile/push-installation
```

El Backend obtiene la identidad del usuario y la sesión desde la autenticación activa.

### Flujo general de notificaciones

```text
Operación de negocio
        ↓
Persistencia en PostgreSQL
        ↓
Evento de notificación
        ↓
┌─────────────────────┬─────────────────────┐
│      WebSocket      │         FCM         │
│     cliente web     │   cliente Android   │
└─────────────────────┴─────────────────────┘
        ↓
Cliente actualiza los datos mediante REST
```

---

## 9. Despliegue

El Backend está preparado para ejecutarse mediante Spring Boot y empaquetarse como un archivo JAR.

Para generar el artefacto:

```powershell
.\mvnw.cmd clean package
```

El resultado se genera dentro de:

```text
target/
```

Para ejecutar el JAR generado puede utilizarse:

```bash
java -jar <archivo-generado>.jar
```

Antes del despliegue deben configurarse las variables de entorno correspondientes al entorno destino.

Como mínimo:

```text
DB_HOST
DB_PORT
DB_NAME
DB_USERNAME
DB_PASSWORD

JWT_SECRET

ORMAN_FRONTEND_URL
```

Si se habilitan notificaciones push:

```text
ORMAN_FIREBASE_ENABLED=true
ORMAN_FIREBASE_PROJECT_ID=<firebase-project-id>
GOOGLE_APPLICATION_CREDENTIALS=<ruta-segura-al-service-account.json>
```

Las credenciales privadas no deben empaquetarse dentro del JAR ni almacenarse en el repositorio.

### Consideraciones de seguridad para despliegue

No deben publicarse:

```text
.env
JWT_SECRET
contraseñas
refresh tokens
service-account de Firebase
claves privadas
```

El archivo de Firebase Admin debe proporcionarse al servidor mediante un mecanismo seguro.

### Estado de despliegue

**Backend público:** <pendiente / URL>

**Frontend web:** <pendiente / URL>

**Aplicación móvil instalable:** <pendiente / enlace al APK o mecanismo de distribución>

El procedimiento completo de instalación y despliegue debe mantenerse alineado con el apartado correspondiente de la monografía y el manual de instalación del proyecto.

---

## 10. Licencia

Proyecto desarrollado como Trabajo Final del:

**Diplomado en Desarrollo Web y Aplicaciones Móviles · UAJMS 2026**

Uso académico.

Todos los derechos reservados por el autor, salvo que posteriormente se adopte una licencia de software específica.

---

## Seguridad

El Backend implementa mecanismos orientados a proteger la aplicación y sus datos.

Entre ellos:

- contraseñas almacenadas mediante BCrypt;
- autenticación directa mediante usuario/contraseña y JWT;
- access token y refresh token;
- refresh WEB mediante cookie HttpOnly;
- protección XSRF/CSRF en el flujo WEB correspondiente;
- sesiones diferenciadas por dispositivo;
- autorización basada en roles;
- protección de endpoints;
- configuración CORS;
- revocación y control de vigencia de sesiones;
- asociación de instalaciones push con sesiones autenticadas.

No deben registrarse en logs:

```text
contraseñas
JWT completos
refresh tokens
Authorization headers
claves privadas
credenciales de Firebase Admin
```

---

## Consideraciones antes de publicar cambios

Antes de realizar un commit:

```powershell
git status
```

Verificar que no se incluyan accidentalmente:

```text
.env
credenciales Firebase Admin
claves privadas
tokens
contraseñas
archivos almacenados durante la ejecución
logs
```

Las credenciales de desarrollo y producción deben permanecer fuera del repositorio.