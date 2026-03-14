# Incompatibilidades de Plugins — Flutter Desktop Linux

Este documento cataloga plugins de webview **incompatibles con Flutter Linux desktop** en Flutter stable 3.41, con sus síntomas, causa raíz y la alternativa recomendada.

> **⚠️ Conclusión directa (verificado en proyecto real, marzo 2026):** **No existe ningún plugin de webview funcional para Flutter Linux desktop en stable 3.41.** La alternativa correcta es `url_launcher` para abrir el navegador del sistema.

---

---

## Plugin 1 — `webview_flutter` — Sin soporte Linux

**Versión probada:** `^4.13.1`  
**Plataforma afectada:** Linux  

### Síntoma

```
Failed assertion: 'WebViewPlatform.instance != null':
A platform implementation for webview_flutter has not been set.
```

### Causa raíz

El paquete `webview_flutter` tiene implementaciones separadas por plataforma:
- `webview_flutter_android` — Android ✅
- `webview_flutter_wkwebview` — iOS/macOS ✅
- `webview_flutter_web` — Web ✅
- `webview_flutter_windows` — Windows (experimental) ✅
- **Linux — ❌ No existe implementación oficial ni comunitaria estable**

### Solución

**No usar `webview_flutter` en Linux.** Usar `url_launcher` para abrir URLs en el navegador del sistema:

```dart
import 'package:url_launcher/url_launcher.dart';

await launchUrl(Uri.parse('https://example.com'));
```

---

## Plugin 2 — `flutter_inappwebview` — Falla de inicialización en Linux

**Versión probada:** `^6.1.5`  
**Plataforma afectada:** Linux  

### Síntoma

```
Failed assertion: line 215 pos 7:
'InAppWebViewPlatform.instance != null':
A platform implementation for flutter_inappwebview has not been set.
Please ensure that an implementation of InAppWebViewPlatform has been
set to InAppWebViewPlatform.instance before use.
```

### Causa raíz

Aunque `flutter_inappwebview` menciona soporte Linux/WebKitGTK en su documentación, el registro de la plataforma **no ocurre automáticamente** en Flutter stable 3.41. El plugin requiere que el backend GTK esté registrado manualmente, pero no expone una API pública estable para hacerlo en Dart — la inicialización falla en runtime.

### Solución

**No usar `flutter_inappwebview` en Linux desktop con Flutter stable 3.41.** Usar `url_launcher`:

```dart
import 'package:url_launcher/url_launcher.dart';

// Abrir en el navegador del sistema (Chrome, Firefox, etc.)
Future<void> abrirEnNavegador(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

---

## Plugin 3 — `desktop_webview_window` — Retirado (crash segfault en Linux)

**Versión:** `^0.2.3`  
**Plataforma afectada:** Linux  
**Estado:** ❌ **Plugin retirado del proyecto. No usar.**

### Síntomas
- Crash con **Segmentation Fault** al cerrar la ventana WebView (`signal 11`)
- Al cerrar la ventana webview, **cierra toda la aplicación**
- Colapso del contexto OpenGL del motor Flutter principal

### Causa raíz
Dos bugs en `linux/webview_window.cc`:
1. Use-After-Free en señal `destroy` de GTK — notifica a Dart después de liberar memoria
2. El plugin inyecta un segundo motor Flutter (`fl_view_new`) como barra de título, colapsando OpenGL en Linux multiproceso

### Decisión arquitectural

Plugin **retirado del proyecto** en favor de ventana única con `ViewState` enum + `url_launcher`. Ningún parche C++ en `.pub-cache` es mantenible a largo plazo.

---

## Tabla resumen de incompatibilidades webview en Linux

| Plugin | Versión | Error en Linux | Alternativa |
|---|---|---|---|
| `webview_flutter` | `^4.13.1` | `WebViewPlatform.instance != null` — sin implementación Linux | `url_launcher` |
| `flutter_inappwebview` | `^6.1.5` | `InAppWebViewPlatform.instance != null` — backend GTK no se registra | `url_launcher` |
| `desktop_webview_window` | `^0.2.3` | Segfault + cierra toda la app al cerrar ventana | `url_launcher` |

> **Regla:** Para Flutter Linux desktop stable 3.41, **no existe webview embebido funcional**. Cualquier requisito de navegación web debe resolverse con `url_launcher` (`launchUrl`) para delegar al navegador del sistema operativo.
