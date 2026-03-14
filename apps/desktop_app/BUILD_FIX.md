# Error al compilar en Linux (flutter run)

## Problema encontrado
Al ejecutar:

```bash
fvm flutter run -d linux
```

la compilación fallaba con dos problemas principales:

1. **Advertencia de API deprecada convertida en error**

```
.../tray_manager_plugin.cc:118:17: error: 'app_indicator_new' is deprecated [-Werror,-Wdeprecated-declarations]
```

El plugin `tray_manager` usa `app_indicator_new`, que está marcado como **deprecated** en las bibliotecas de Linux (libayatana-appindicator).

2. **Fallo en instalación de assets nativos**

```
file INSTALL cannot find ".../build/native_assets/linux": No such file or directory.
```

El paso de instalación del build esperaba que existiera `build/native_assets/linux`, pero en algunas versiones de Flutter el directorio no se genera.

---

## Solución aplicada

### ✅ 1) Ignorar warnings de deprecated que se tratan como errores

En `linux/CMakeLists.txt` se ajustó la función `APPLY_STANDARD_SETTINGS` para permitir advertencias de API deprecada sin fallar el build:

```cmake
target_compile_options(${TARGET} PRIVATE -Wall -Werror -Wno-error=deprecated-declarations)
```

Esto evita que el uso de `app_indicator_new` haga que la compilación falle.

### ✅ 2) Evitar fallar cuando `native_assets/linux` no existe

Se agregó un chequeo condicional antes de intentar instalar `native_assets` para que la instalación solo ocurra si el directorio existe:

```cmake
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
if(EXISTS "${NATIVE_ASSETS_DIR}")
  install(DIRECTORY "${NATIVE_ASSETS_DIR}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
```

---

## Resultado
Con estos cambios, `fvm flutter run -d linux` construye y lanza la aplicación correctamente en Linux.

> Nota: la app sigue mostrando advertencias en tiempo de ejecución relacionadas con GTK y el plugin de tray, pero ya no bloquean la compilación.
