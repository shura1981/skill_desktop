Uso de la skill build-deb

Esta carpeta contiene plantillas y un script portable para generar un paquete .deb.

Variables soportadas (exporta antes de ejecutar o personaliza las plantillas):

- APP_NAME: nombre del paquete (kebab-case recomendado)
- APP_EXEC: nombre del ejecutable
- APP_VERSION: versión del paquete
- ARCH: arquitectura (default: amd64)
- APP_ID: application id (StartupWMClass)
- INSTALLER_DIR: directorio donde copiar las plantillas (default: linux/installer)

Ejemplo rápido:

```bash
# desde la raíz del proyecto
mkdir -p linux/installer
cp .github/skills/build-deb/scripts/build_deb.sh linux/installer/
cp .github/skills/build-deb/templates/control.tpl linux/installer/control.tpl
cp .github/skills/build-deb/templates/desktop.tpl linux/installer/desktop.tpl
chmod +x linux/installer/build_deb.sh
APP_NAME=my-app APP_EXEC=my_app APP_VERSION=1.0.0 ./linux/installer/build_deb.sh
```

Si el repositorio contiene `pubspec.yaml`, el script intenta inferir `APP_NAME`, `APP_EXEC` y `APP_VERSION`.
