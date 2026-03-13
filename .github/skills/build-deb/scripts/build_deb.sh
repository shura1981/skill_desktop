#!/bin/bash
# Template de script de empaquetado .deb para proyectos Flutter en Linux.
# Copia este archivo a linux/installer/build_deb.sh en tu proyecto y
# actualiza las variables APP_NAME, APP_EXEC, APP_VERSION a los valores reales.
#
# Uso: ./linux/installer/build_deb.sh

# Navegamos siempre a la raíz del proyecto sin importar desde dónde se invoque.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_ROOT"

# ─── Configura estas variables para tu proyecto ──────────────────────────────
APP_NAME="<nombre-kebab-case>"       # ej. mi-aplicacion
APP_EXEC="<nombre_ejecutable>"       # ej. mi_aplicacion  (debe coincidir con BINARY_NAME en CMakeLists.txt)
APP_VERSION="<version>"              # ej. 1.0.0  (sin build number del pubspec)
# ────────────────────────────────────────────────────────────────────────────

ARCH="amd64"
DEB_DIR_NAME="${APP_NAME}_${APP_VERSION}_${ARCH}"
INSTALLER_DIR="linux/installer"
RELEASES_DIR="${INSTALLER_DIR}/releases"
BUILD_BUNDLE_DIR="build/linux/x64/release/bundle"
DEB_STAGING_DIR="${INSTALLER_DIR}/${DEB_DIR_NAME}"

# Extraemos el Application ID de Linux configurado en CMakeLists.txt para GNOME/Wayland
APP_ID=$(grep 'set(APPLICATION_ID' linux/CMakeLists.txt | awk -F '"' '{print $2}')
if [ -z "$APP_ID" ]; then
    APP_ID="$APP_EXEC"
fi

echo "=========================================================="
echo "          Generando Instalador .deb para Linux            "
echo "=========================================================="

# 1. Compilar aplicación para Linux (requiere fvm instalado)
echo "=========================================================="
echo "          Compilando Proyecto Flutter para Linux          "
echo "=========================================================="
fvm flutter build linux

if [ $? -ne 0 ]; then
    echo "Error: La compilación de Flutter falló."
    exit 1
fi

# 2. Verificar si el bundle existe
if [ ! -d "$BUILD_BUNDLE_DIR" ]; then
    echo "Error: No se encontró el bundle de la aplicación en $BUILD_BUNDLE_DIR"
    exit 1
fi

# 3. Limpiar directorio de staging si existe
if [ -d "$DEB_STAGING_DIR" ]; then
    echo "Limpiando directorio temporal anterior..."
    rm -rf "$DEB_STAGING_DIR"
fi

# 4. Crear estructura de directorios del paquete .deb
echo "Creando estructura de directorios..."
mkdir -p "${DEB_STAGING_DIR}/DEBIAN"
mkdir -p "${DEB_STAGING_DIR}/opt/${APP_EXEC}"
mkdir -p "${DEB_STAGING_DIR}/usr/share/applications"
mkdir -p "${DEB_STAGING_DIR}/usr/share/pixmaps"

# 5. Copiar los archivos binarios de la aplicación
echo "Copiando binarios de la aplicación..."
cp -R ${BUILD_BUNDLE_DIR}/* "${DEB_STAGING_DIR}/opt/${APP_EXEC}/"

# 6. Copiar el icono
echo "Copiando icono..."
if [ -f "${INSTALLER_DIR}/icon.png" ]; then
    cp "${INSTALLER_DIR}/icon.png" "${DEB_STAGING_DIR}/usr/share/pixmaps/${APP_EXEC}.png"
else
    echo "Advertencia: No se encontró icon.png en ${INSTALLER_DIR}/"
fi

# 7. Crear archivo DEBIAN/control
echo "Generando archivo de control..."
cat << EOF > "${DEB_STAGING_DIR}/DEBIAN/control"
Package: ${APP_NAME}
Version: ${APP_VERSION}
Architecture: ${ARCH}
Maintainer: <Nombre Mantenedor>
Description: <Descripción de la aplicación>
EOF

# 8. Crear archivo .desktop para el menú de aplicaciones
# El bloque Actions=new-window requiere G_APPLICATION_HANDLES_COMMAND_LINE en my_application.cc
echo "Generando archivo .desktop..."
cat << EOF > "${DEB_STAGING_DIR}/usr/share/applications/${APP_ID}.desktop"
[Desktop Entry]
Version=1.0
Name=${APP_NAME}
Comment=<Descripción corta>
Exec=/opt/${APP_EXEC}/${APP_EXEC} %u
Icon=${APP_EXEC}
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=${APP_ID}
Actions=new-window;

[Desktop Action new-window]
Name=Nueva ventana
Exec=/opt/${APP_EXEC}/${APP_EXEC}
EOF

# Dar permisos correctos a los archivos generados
chmod +x "${DEB_STAGING_DIR}/opt/${APP_EXEC}/${APP_EXEC}"
chmod 644 "${DEB_STAGING_DIR}/usr/share/applications/${APP_ID}.desktop"
chmod 644 "${DEB_STAGING_DIR}/usr/share/pixmaps/${APP_EXEC}.png"

# 9. Construir el paquete .deb
echo "Construyendo el paquete .deb..."
mkdir -p "$RELEASES_DIR"
dpkg-deb --root-owner-group --build "$DEB_STAGING_DIR" "${RELEASES_DIR}/${DEB_DIR_NAME}.deb"

if [ $? -eq 0 ]; then
    echo "=========================================================="
    echo "¡Éxito! El paquete .deb se ha generado correctamente."
    echo "Archivo generado: ${RELEASES_DIR}/${DEB_DIR_NAME}.deb"
    echo "Puedes instalarlo ejecutando: sudo dpkg -i ${RELEASES_DIR}/${DEB_DIR_NAME}.deb"
    echo "=========================================================="
    rm -rf "$DEB_STAGING_DIR"
else
    echo "Error al construir el paquete .deb."
    exit 1
fi
