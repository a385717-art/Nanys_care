<div align="center">

# 🧸 Nanys Care

**Plataforma móvil para conectar tutores con cuidadoras de confianza**

*Proyecto de desarrollo de software — Mayo 2026*

</div>

---

## 📱 Descripción

**Nanys Care** es una aplicación móvil multiplataforma (Android/iOS) que conecta a tutores o padres de familia con cuidadoras infantiles de confianza. Permite buscar cuidadoras por zona y tarifa, agendar citas, gestionarlas en tiempo real y recibir notificaciones por correo.

---

## ✨ Funcionalidades

### 👤 Autenticación (Sprint 1)
- Registro con correo electrónico y verificación
- Inicio de sesión seguro con manejo de sesiones
- Selección de rol: **Tutor** o **Cuidadora**
- Indicador de seguridad de contraseña

### 🧑‍💼 Perfiles (Sprint 1)
- Perfil de cuidadora con foto, zona, tarifa y años de experiencia
- Perfil de tutor con información de hijos (nombre, edad, alergias)
- Carga de avatar al almacenamiento de Supabase
- Sección de reglamento de la plataforma con acordeón interactivo

### 🔍 Búsqueda (Sprint 2)
- Búsqueda de cuidadoras con filtros por zona, tarifa máxima y experiencia mínima
- Vista detallada del perfil de cada cuidadora
- Chips de filtros activos con opción de eliminarlos

### 📅 Citas (Sprint 2)
- Agendar citas con selector de fecha, hora de inicio y hora de fin
- Cálculo automático del costo estimado
- Vista de agenda con secciones: Próximas / Historial
- Aceptar o rechazar solicitudes (vista de la cuidadora) con confirmación
- Marcar citas como completadas

### 📧 Notificaciones (Sprint 3)
- Correos automáticos al enviar, aceptar o rechazar una cita
- Integración con la API REST de Resend
- Calificación del servicio con estrellas y comentario

---

## 🗂️ Estructura del proyecto

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # Constantes generales
│   │   └── secrets.dart            # 🔒 Claves privadas (no se sube a git)
│   ├── router/
│   │   └── app_router.dart         # Rutas con go_router
│   └── theme/
│       └── app_theme.dart          # Tema visual de la app
│
├── features/
│   ├── auth/                       # US01, US02 — Registro y login
│   ├── profile/                    # US03, US04, US05 — Perfiles
│   ├── reglamento/                 # US13 — Reglamento
│   ├── search/                     # US06, US07 — Búsqueda
│   ├── citas/                      # US08, US09, US11, US12 — Citas
│   ├── cuidadores/                 # Repositorio de cuidadores
│   ├── notificaciones/             # US10 — Correos con Resend
│   └── home/                       # Pantalla principal
│
└── main.dart
```

---

## 🛠️ Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter | Framework multiplataforma |
| Dart | Lenguaje de programación |
| Supabase | Base de datos, auth y storage |
| go_router | Navegación declarativa |
| Resend API | Notificaciones por correo |
| image_picker | Selección de fotos de perfil |
| intl | Formato de fechas |
| http | Llamadas REST a Resend |

---

## 🗃️ Base de datos (Supabase)

| Tabla | Descripción |
|---|---|
| `profiles` | Datos generales de todos los usuarios |
| `cuidadores` | Perfil extendido de cuidadoras |
| `tutores` | Perfil extendido de tutores |
| `hijos` | Hijos registrados por tutor |
| `citas` | Solicitudes y citas agendadas |
| `hijos_citas` | Relación cita ↔ hijo cuidado |
| `calificaciones` | Reseñas de tutores a cuidadoras |
| `cuidadores_perfil` | **VIEW** — Cuidadoras con promedio de calificación |

---

## 🚀 Instalación y configuración

### Requisitos
- Flutter SDK 3.x
- Dart 3.x
- Cuenta en [Supabase](https://supabase.com)
- Cuenta en [Resend](https://resend.com) (para correos)

### 1. Clonar el repositorio

```bash
git clone https://github.com/a385717-art/Nanys_care.git
cd Nanys_care
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar las claves

Crea el archivo `lib/core/constants/secrets.dart` (está en `.gitignore`, no se sube al repo):

```dart
class AppSecrets {
  static const supabaseUrl     = 'TU_SUPABASE_URL';
  static const supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
  static const resendApiKey    = 'TU_RESEND_API_KEY';
}
```

### 4. Configurar la base de datos

Ejecuta los siguientes scripts SQL en **Supabase → SQL Editor**:

1. Schema principal (tablas y RLS)
2. `sprint2_fix.sql` (VIEW `cuidadores_perfil` e índices)

### 5. Correr la app

```bash
flutter run
```

---

## 📋 Historias de usuario implementadas

| ID | Historia | Sprint | Estado |
|---|---|---|---|
| US01 | Registro con correo electrónico | 1 | ✅ |
| US02 | Inicio de sesión seguro | 1 | ✅ |
| US03 | Perfil completo del cuidador | 1 | ✅ |
| US04 | Tarifas por hora | 1 | ✅ |
| US05 | Perfil del tutor con info de hijos | 1 | ✅ |
| US06 | Búsqueda con filtros | 2 | ✅ |
| US07 | Solicitudes de cuidado por zona | 2 | ✅ |
| US08 | Agendar citas según disponibilidad | 2 | ✅ |
| US09 | Aceptar o rechazar citas | 2 | ✅ |
| US10 | Correos de reservas y recordatorios | 3 | ✅ |
| US11 | Calificaciones del tutor al cuidador | 3 | ✅ |
| US12 | Consulta de agenda | 2 | ✅ |
| US13 | Sección de reglamento del cuidador | 1 | ✅ |

---

## 🔒 Seguridad

- Las claves de Supabase y Resend **nunca se suben al repositorio**
- El archivo `secrets.dart` está en `.gitignore`
- Row Level Security (RLS) habilitado en todas las tablas
- Cada usuario solo puede ver y modificar sus propios datos

---

## 👥 Equipo

Proyecto desarrollado para la materia de Desarrollo de Software  
Instituto / Universidad — Mayo 2026

---

<div align="center">
Hecho con ❤️ y Flutter
</div>
