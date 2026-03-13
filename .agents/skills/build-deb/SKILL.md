---
name: build-deb
description: Úsala cuando el usuario pida compilar la app en Linux, crear un ejecutable para Linux, generar un script de compilación Linux, crear un instalador .deb, empaquetar la app para distribución en Ubuntu o Debian, o configurar el build de Flutter para Linux desktop. Cubre compilación con fvm, empaquetado dpkg-deb, soporte multi-instancia Wayland/GTK, extracción de APPLICATION_ID desde CMakeLists.txt, y generación de archivos DEBIAN/control y .desktop con acción new-window.
license: Complete terms in LICENSE.txt
---

# Build Flutter Linux → instalador .deb

Esta skill documenta cómo compilar un proyecto Flutter para Linux y generar un paquete `.deb`
redistribuible. Incluye el script de empaquetado, plantillas de `DEBIAN/control` y `.desktop`
con soporte multi-instancia (Wayland/GNOME), y la tarea VS Code correspondiente.

## Archivos en la skill

- `scripts/build_deb.sh` — script de empaquetado fiel al proyecto de referencia
- `templates/control.tpl` — plantilla `DEBIAN/control`
- `templates/desktop.tpl` — plantilla `.desktop` con `Actions=new-window`
- `templates/tasks.json` — tarea VS Code lista para copiar
- `references/README.md` — referencia rápida de variables

---

## Cuándo usar esta skill

- Compilar y empaquetar la app Flutter como `.deb` para Debian/Ubuntu.
- Entornos de escritorio Wayland o GNOME que requieran soporte multi-instancia.
- Añadir esta capacidad a un proyecto Flutter que aún no la tiene.

---

## Prerrequisitos

| Herramienta | Propósito |
|---|---|
| `fvm` | Gestión de versiones Flutter — **el script lo requiere** |
| `dpkg-deb` | Construir el `.deb` (paquete `dpkg` en Ubuntu) |
| `bash` 4+ | Ejecutar el script |
| `awk`, `grep` | Extraer metadatos de `CMakeLists.txt` |

```bash
sudo apt-get install dpkg
dart pub global activate fvm   # si fvm no está instalado
```

---

## Estructura de archivos en el proyecto

```
linux/
├── installer/
│   ├── build_deb.sh        ← script de empaquetado
│   ├── icon.png            ← ícono de la app (256×256 recomendado)
│   └── releases/           ← directorio de salida del .deb (en .gitignore)
├── CMakeLists.txt          ← contiene set(APPLICATION_ID "...") para StartupWMClass
└── runner/
    └── my_application.cc   ← debe usar G_APPLICATION_HANDLES_COMMAND_LINE
pubspec.yaml                ← fuente de name y version
```

---

## Cómo funciona el script

### 1. Auto-localización del proyecto

```bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_ROOT"
```

Funciona sin importar desde dónde se invoque porque calcula la raíz del proyecto a partir
de su propia ubicación en `linux/installer/`.

### 2. Variables de configuración

Hardcodeadas al inicio del script; se adaptan por proyecto:

```bash
APP_NAME="<nombre-kebab-case>"        # nombre del paquete .deb
APP_EXEC="<nombre_ejecutable>"        # nombre del binario en /opt/
APP_VERSION="<versión>"               # versión (sin build number del pubspec)
ARCH="amd64"
INSTALLER_DIR="linux/installer"
RELEASES_DIR="${INSTALLER_DIR}/releases"
BUILD_BUNDLE_DIR="build/linux/x64/release/bundle"
DEB_STAGING_DIR="${INSTALLER_DIR}/${APP_NAME}_${APP_VERSION}_${ARCH}"
```

> La versión es independiente de `pubspec.yaml`. Actualizar ambas al hacer release.

### 3. Extracción de APPLICATION_ID desde CMakeLists.txt

```bash
APP_ID=$(grep 'set(APPLICATION_ID' linux/CMakeLists.txt | awk -F '"' '{print $2}')
if [ -z "$APP_ID" ]; then
    APP_ID="$APP_EXEC"
fi
```

Vincula el `StartupWMClass` del `.desktop` con el ID D-Bus de la app en Wayland/GNOME para
que el entorno de escritorio agrupe las ventanas correctamente.

### 4. Compilación con fvm

```bash
fvm flutter build linux
```

El script usa `fvm` directamente, no como fallback opcional. Si `fvm` no está en PATH, el
script falla con error de compilación.

### 5. Estructura del paquete generado

```
${DEB_STAGING_DIR}/
├── DEBIAN/
│   └── control
├── opt/
│   └── ${APP_EXEC}/
│       ├── ${APP_EXEC}   ← ejecutable (chmod +x)
│       ├── lib/
│       └── data/
└── usr/
    ├── share/applications/
    │   └── ${APP_ID}.desktop
    └── share/pixmaps/
        └── ${APP_EXEC}.png
```

### 6. Archivo `.desktop` con acción multi-instancia

El `.desktop` incluye una `Desktop Action` para abrir nuevas instancias desde el dock de
GNOME/KDE. Requiere que `linux/runner/my_application.cc` registre la app con
`G_APPLICATION_HANDLES_COMMAND_LINE` (ver workflow `build-ubuntu-wayland.md`):

```ini
[Desktop Entry]
Version=1.0
Name=<APP_NAME>
Comment=<descripción>
Exec=/opt/<APP_EXEC>/<APP_EXEC> %u
Icon=<APP_EXEC>
Terminal=false
Type=Application
Categories=Utility;Finance;
StartupWMClass=<APP_ID>
Actions=new-window;

[Desktop Action new-window]
Name=Nueva ventana
Exec=/opt/<APP_EXEC>/<APP_EXEC>
```

### 7. Permisos

```bash
chmod +x "${DEB_STAGING_DIR}/opt/${APP_EXEC}/${APP_EXEC}"
chmod 644 "${DEB_STAGING_DIR}/usr/share/applications/${APP_ID}.desktop"
chmod 644 "${DEB_STAGING_DIR}/usr/share/pixmaps/${APP_EXEC}.png"
```

### 8. Empaquetado final

```bash
dpkg-deb --root-owner-group --build "$DEB_STAGING_DIR" "${RELEASES_DIR}/${DEB_DIR_NAME}.deb"
```

El directorio de staging se elimina automáticamente al completar con éxito.

---

## Instalar el script en un proyecto nuevo

```bash
mkdir -p linux/installer

# Copiar script desde la skill y ajustar las variables al inicio
cp .github/skills/build-deb/scripts/build_deb.sh linux/installer/build_deb.sh
chmod +x linux/installer/build_deb.sh

# Copiar el ícono de la app
cp assets/images/logo.png linux/installer/icon.png   # ajusta la ruta al ícono real

# Excluir releases del repositorio
echo "/linux/installer/releases/" >> .gitignore
```

---

## Ejecutar el empaquetado

```bash
./linux/installer/build_deb.sh
```

O bien `Ctrl+Shift+B` en VS Code → `Build Debian Package`.

El `.deb` queda en `linux/installer/releases/`.
Para instalarlo localmente:

```bash
sudo dpkg -i linux/installer/releases/<app>_<version>_amd64.deb
```

---

## Tarea VS Code

Copiar o fusionar `templates/tasks.json` en `.vscode/tasks.json` del proyecto:

```json
{
  "label": "Build Debian Package",
  "type": "shell",
  "command": "./linux/installer/build_deb.sh",
  "group": { "kind": "build", "isDefault": true }
}
```

---

## Notas importantes

- `linux/installer/releases/` debe estar en `.gitignore` para no subir binarios.
- Si `linux/installer/icon.png` no existe, el script emite advertencia pero no falla.
- La versión del script es manual; actualizarla junto a `pubspec.yaml` en cada release.
- Para multi-instancia en Wayland, `linux/runner/my_application.cc` debe usar
  `G_APPLICATION_HANDLES_COMMAND_LINE` (ver workflow `build-ubuntu-wayland.md`).
