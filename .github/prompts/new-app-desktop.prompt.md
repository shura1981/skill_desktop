---
name: new-app-desktop
description: Describe when to use this prompt
---

En este directorio crea una app de Flutter para escritorio que cumpla con las siguientes características:

- Flutter SDK: 3.41.4
- Plataforma: Desktop (Linux/macOS/Windows)

## Diseño
- Usar Material 3 (Material You).
- Incluir una pantalla de configuración de tema que permita al usuario seleccionar:
  - Tema: Light / Dark / System
  - Color acento (Material 3 color scheme)

## Funcionalidades principales
### Menú nativo (barra de menú)
- Debe usar un menú de escritorio nativo (barra de menú superior en macOS/Linux o menu bar en Windows), **no un `MenuBar` dentro del body ni botones popup**.
- Estructura de menú propuesta (puede adaptarse a cada plataforma, pero debe ser nativo):
  - Archivo (o Edición): Nuevo, Buscar
  - Ayuda: Acerca de, Licencias

### Vista principal
- Mostrar una tabla de datos (lista/tabular) con los registros almacenados en una base de datos SQLite.
- La base de datos debe tener una tabla `usuarios` con los siguientes campos:
  - `nombres` (texto)
  - `apellidos` (texto)
  - `fecha_nacimiento` (fecha)
  - `ciudad` (texto)
  - `direccion` (texto)
  - `telefono` (texto)

### CRUD de usuarios
- El menú **Nuevo** abre un diálogo modal con un formulario para ingresar los datos de un usuario.
  - El diálogo debe tener botones **Guardar** y **Cancelar**.
- En la tabla, cada fila debe tener botones **Editar** y **Eliminar**.
  - **Eliminar** debe mostrar un mensaje de confirmación antes de borrar.
  - **Editar** abre el mismo modal prellenado para actualizar el registro.

### Bandeja del sistema (tray)
- La app debe registrar un ícono de bandeja (tray) para minimizar/ocultar la ventana.
- El menú contextual del ícono de bandeja debe incluir al menos estas opciones:
  - Mostrar (restaurar ventana)
  - Segundo plano (minimizar/ocultar)

## Organización del proyecto
- Crea el proyecto dentro de la carpeta `apps/`.
- El directorio del proyecto debe llamarse `desktop_app_v2`.

## Notas adicionales
- Usa las skills disponibles en este repositorio para generar el proyecto, configuraciones y código.
- Asegúrate de que la experiencia sea nativa en escritorio: menú de sistema real, comportamiento de ventana estándar, y un tray funcional.
