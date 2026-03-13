# Patrones de Proyecto — Flutter Desktop (Guía de Boilerplate Real)

Este documento contiene patrones extraídos de un proyecto real de escritorio Flutter (`multi_window_app`). Su propósito es servir como guía de referencia rápida y boilerplate reutilizable. Cada sección muestra código de producción probado.

> **Nota sobre versiones:** Los patrones aquí documentados son para Flutter 3.41. El plugin `desktop_multi_window` **ha sido eliminado** de esta guía porque está obsoleto desde SDK 3.4x — reemplazado íntegramente por `PlatformDispatcher.instance.requestView()`.

---

## 1. Gestión de Temas (Theming) y Estado Global

### `flutter_riverpod` + `shared_preferences`

La aplicación puede cambiar entre **Modo Claro, Oscuro o del Sistema**, y adicionalmente elegir un **Color de Acento** principal que afecta a toda la interfaz.

#### Modelo de datos (`lib/theme_provider.dart`)

Al utilizar Riverpod, se agrupa el estado en un `Notifier`. Los métodos para mutar el tema no sólo actualizan la vista inmediatamente (`state = state.copyWith(...)`), sino que además escriben en disco mediante `SharedPreferences`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemeSettings {
  final ThemeMode mode;
  final Color color;

  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.color = const Color(0xFF1565C0), // Azul por defecto
  });

  ThemeSettings copyWith({ThemeMode? mode, Color? color}) {
    return ThemeSettings(
      mode: mode ?? this.mode,
      color: color ?? this.color,
    );
  }
}

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    _loadSettings();
    return const ThemeSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final modeString = prefs.getString('theme_preference_mode');
    final mode = modeString != null
        ? ThemeMode.values.firstWhere(
            (e) => e.name == modeString,
            orElse: () => ThemeMode.system,
          )
        : ThemeMode.system;

    final colorInt = prefs.getInt('theme_preference_color');
    final color = colorInt != null ? Color(colorInt) : const Color(0xFF1565C0);

    state = ThemeSettings(mode: mode, color: color);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference_mode', mode.name);
  }

  Future<void> setColor(Color color) async {
    state = state.copyWith(color: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_preference_color', color.toARGB32());
  }
}

// Provider global
final themeProvider = NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);
```

#### Consumo en `MaterialApp`

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeProvider);
    return MaterialApp(
      themeMode: settings.mode,
      theme: ThemeData(
        colorSchemeSeed: settings.color,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: settings.color,
        brightness: Brightness.dark,
      ),
      home: const MainWindow(),
    );
  }
}
```

#### Diálogo de configuración de tema (`lib/theme_settings_dialog.dart`)

```dart
class ThemeSettingsDialog extends ConsumerWidget {
  const ThemeSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeProvider);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apariencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                title: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
                value: mode,
                groupValue: settings.mode,
                onChanged: (val) => ref.read(themeProvider.notifier).setMode(val!),
              ),
            // Aquí se añadiría un color picker para el acento
          ],
        ),
      ),
    );
  }
}
```

---

## 2. Sistema Operativo y Ventanas

### `window_manager` + `tray_manager`

Estas dos librerías trabajan en conjunto: `window_manager` controla el foco nativo y previene cierres por defecto; `tray_manager` crea el ícono en la bandeja del sistema para despertar la aplicación.

#### Compatibilidad de íconos del System Tray (Windows vs Linux/macOS)

- **Linux / macOS:** Aceptan íconos PNG declarados en la carpeta `assets` de Flutter.
- **Windows:** Requiere obligatoriamente un `.ico` en **ruta absoluta del disco**, que varía entre `flutter run` (debug) y el ejecutable compilado (release).

Helper de resolución (`lib/main.dart`):

```dart
import 'dart:io';
import 'package:path/path.dart' as p;

String resolveTrayIconPath() {
  if (Platform.isWindows) {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = <String>[
      p.join(exeDir, 'resources', 'app_icon.ico'),                                      // Release
      p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'), // Debug
      p.normalize(p.join(exeDir, '..', 'resources', 'app_icon.ico')),                   // Alternativo
    ];
    for (final iconPath in candidates) {
      if (File(iconPath).existsSync()) return iconPath;
    }
  }
  return 'assets/tray_icon.png'; // Linux y macOS: ruta de asset normal
}

// Uso en main():
await trayManager.setIcon(resolveTrayIconPath());
```

#### Configuración del menú contextual del tray (`lib/main.dart`)

```dart
import 'package:tray_manager/tray_manager.dart';

await trayManager.setContextMenu(Menu(
  items: [
    MenuItem(
      label: 'Show Window',
      onClick: (_) async {
        await windowManager.show();
        await windowManager.focus();
      },
    ),
    MenuItem.separator(),
    MenuItem(
      label: 'Refresh',
      onClick: (_) {
        MainWindowRefreshNotifier.instance.notify();
      },
    ),
    MenuItem.separator(),
    MenuItem(
      label: 'Exit',
      onClick: (_) async {
        await trayManager.destroy(); // Limpiar el hilo nativo del tray
        await windowManager.close();
        exit(0);
      },
    ),
  ],
));
await trayManager.setToolTip('My App');
```

#### Gestión completa de eventos (`lib/main_window.dart`)

```dart
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

class _MainWindowState extends State<MainWindow> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  /// Clic izquierdo en ícono de bandeja → restaurar ventana
  /// Workaround Wayland: hide() antes de show() fuerza el re-raise en Linux
  @override
  void onTrayIconMouseDown() async {
    if (!await windowManager.isFocused()) {
      if (await windowManager.isMinimized()) await windowManager.restore();
      if (Platform.isLinux) await windowManager.hide(); // Workaround Wayland
      await windowManager.show();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 300));
      await windowManager.setAlwaysOnTop(false);
    }
  }

  /// WINDOWS: menú contextual en right mouse DOWN (al presionar)
  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows) trayManager.popUpContextMenu();
  }

  /// LINUX: menú contextual en right mouse UP (al soltar)
  /// macOS: el SO lo gestiona automáticamente, NO llamar popUpContextMenu()
  @override
  void onTrayIconRightMouseUp() {
    if (Platform.isLinux) trayManager.popUpContextMenu();
  }

  /// Interceptar botón cerrar (X) → ocultar a bandeja en lugar de destruir
  @override
  void onWindowClose() async {
    await windowManager.hide();
    // El ícono de bandeja permanece activo
  }
}
```

### `local_notifier`

Para despachar notificaciones directamente al sistema de alertas del SO (Windows, macOS, Linux):

```dart
import 'package:local_notifier/local_notifier.dart';

// En main() — inicialización obligatoria antes de mostrar notificaciones
await localNotifier.setup(appName: 'My App');

// Notificación con acción
final notification = LocalNotification(
  title: 'My App',
  body: 'Usuario ha sido añadido correctamente.',
  actions: [
    LocalNotificationAction(type: 'button', text: 'Ver'),
  ],
);
notification.onClickAction = (actionIndex) {
  if (actionIndex == 0) windowManager.show();
};
await notification.show();
```

---

## 3. Base de Datos FFI para Desktop (`sqflite_common_ffi` + `path_provider`)

En Flutter Desktop **no se puede usar `sqflite` directamente** (está enlazado a wrappers Java/ObjC de mobile). Se usa `sqflite_common_ffi` que enlaza SQLite mediante FFI a las bibliotecas C nativas del sistema.

```yaml
dependencies:
  sqflite_common_ffi: ^2.3.3
  path_provider: ^2.1.4
  path: ^1.9.0
```

**`lib/database_helper.dart`** — Patrón Singleton:

```dart
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Paso CRÍTICO: inicializar FFI antes de cualquier operación de base de datos
    // Sin esto, la app crashea silenciosamente en desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Directorio "Mis Documentos" del usuario — persiste entre actualizaciones
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        name    TEXT NOT NULL,
        dob     TEXT NOT NULL,
        phone   TEXT NOT NULL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return db.query('users', orderBy: 'id ASC');
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return db.insert('users', row);
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
```

---

## 4. Generación de PDF e Impresión Nativa (`pdf` + `printing`)

Dos plugins del mismo autor (DavBfr):
- **`pdf`** — Construye documentos PDF con una API de widgets *idéntica* a Flutter (`pw.Column`, `pw.Text`, `pw.Table`, etc.) pero renderizando en vectores PDF.
- **`printing`** — Puente hacia los spoolers de impresoras nativos de Windows, macOS y Linux. También permite guardar a disco, previsualizar e imprimir en red.

```yaml
dependencies:
  pdf: ^3.11.1
  printing: ^5.13.2
```

**`lib/print_service.dart`:**

```dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintService {
  /// Genera los bytes del PDF listos para imprimir o guardar en disco.
  static Future<Uint8List> generateUsersPdf(
    List<Map<String, dynamic>> users,
  ) async {
    final pdf = pw.Document(
      title: 'Users List',
      creator: 'My App',
    );

    // pw.MultiPage maneja la paginación automáticamente
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Reporte de Usuarios',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            context: context,
            headers: ['ID', 'Nombre', 'F. Nac.', 'Teléfono'],
            data: users
                .map((u) => [
                      u['id'].toString(),
                      u['name'],
                      u['dob'],
                      u['phone'],
                    ])
                .toList(),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blue800,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  /// Abre el diálogo nativo de impresora del SO.
  static Future<void> printUsers(List<Map<String, dynamic>> users) async {
    await Printing.layoutPdf(
      onLayout: (format) => generateUsersPdf(users),
      name: 'Reporte de Usuarios',
    );
  }

  /// Guarda el PDF en la carpeta de Descargas sin mostrar diálogo.
  static Future<void> saveToDisk(
    List<Map<String, dynamic>> users,
    String fileName,
  ) async {
    final bytes = await generateUsersPdf(users);
    final dir = await getDownloadsDirectory();
    final file = File(p.join(dir!.path, fileName));
    await file.writeAsBytes(bytes);
  }

  /// Comparte / abre con visor externo del SO.
  static Future<void> share(List<Map<String, dynamic>> users) async {
    final bytes = await generateUsersPdf(users);
    await Printing.sharePdf(bytes: bytes, filename: 'reporte.pdf');
  }
}
```

### API clave de `pw` (análogos a widgets Flutter)

| Widget `pw` | Equivalente Flutter | Notas |
|---|---|---|
| `pw.Document()` | — | Contenedor raíz del PDF |
| `pw.Page` / `pw.MultiPage` | — | `MultiPage` pagina automáticamente |
| `pw.Text(s, style: pw.TextStyle(...))` | `Text` | **No** acepta `TextStyle` de Flutter |
| `pw.Column` / `pw.Row` / `pw.Stack` | Equivalentes exactos | Mismo modelo de layout |
| `pw.Container` / `pw.SizedBox` | Equivalentes exactos | — |
| `pw.Image(MemoryImage(bytes))` | `Image.memory` | Requiere `Uint8List` |
| `pw.Table.fromTextArray(...)` | `DataTable` | Cabeceras + celdas estilizadas |
| `pw.Header` | — | Cabecera de sección estilizada |
| `pw.Divider` | `Divider` | — |
| `PdfColors.blue800` | `Colors.blue[800]` | Paleta de colores del PDF |
| `PdfPageFormat.a4` | — | Tamaño de página (también `letter`, `legal`) |

### Fuentes personalizadas

```dart
final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
final ttf = pw.Font.ttf(fontData);

pdf.addPage(pw.Page(
  build: (ctx) => pw.Text('Hola', style: pw.TextStyle(font: ttf)),
));
```

---

## 5. Cliente SMTP/IMAP — `enough_mail` + `flutter_widget_from_html`

Para procesar correos: `enough_mail` lee el buzón a profundidad y procesa secuencias MIME (adjuntos, HTML). `flutter_widget_from_html` renderiza el HTML del cuerpo directamente en el canvas de Flutter.

```yaml
dependencies:
  enough_mail: ^2.4.1
  flutter_widget_from_html: ^0.15.2
```

**`lib/email_service.dart`:**

```dart
import 'package:enough_mail/enough_mail.dart';

Future<List<EmailModel>> getUnreadEmails() async {
  final client = ImapClient(isLogEnabled: false);

  try {
    await client.connectToServer('mail.servidor.com', 993, isSecure: true);
    await client.login('usuario@servidor.com', 'contraseña');
    await client.selectInbox();

    final searchResult = await client.searchMessages(searchCriteria: 'UNSEEN');
    final List<EmailModel> emails = [];

    if (searchResult.matchingSequence != null) {
      final fetchResult = await client.fetchMessages(
        searchResult.matchingSequence!,
        '(FLAGS ENVELOPE BODY.PEEK[])', // PEEK[] no marca como leído
      );

      for (final message in fetchResult.messages) {
        final attachments = <String>[];
        if (message.hasAttachments() && message.parts != null) {
          for (final part in message.parts!) {
            final name = part.decodeFileName();
            if (name != null) attachments.add(name);
          }
        }

        emails.add(EmailModel(
          sender: message.fromEmail ?? 'Desconocido',
          subject: message.decodeSubject() ?? 'Sin Asunto',
          date: message.decodeDate() ?? DateTime.now(),
          attachmentNames: attachments,
          originalMessage: message,
        ));
      }
    }
    return emails;
  } finally {
    if (client.isLoggedIn) await client.logout();
  }
}
```

**`lib/email_detail_view.dart`** — Renderizar el cuerpo HTML:

```dart
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

Widget build(BuildContext context) {
  return HtmlWidget(
    _htmlBody, // String extraído del cuerpo MIME
    textStyle: const TextStyle(fontSize: 14),
    renderMode: RenderMode.column,
    // Maneja automáticamente src='base64...' y URLs de imágenes remotas
  );
}
```

---

## 6. Menús de Aplicación y Atajos de Teclado (SDK Nativo — Sin Plugins)

Flutter Desktop provee `MenuBar`, `SubmenuButton`, `MenuItemButton` y `MenuAcceleratorLabel` de forma nativa. **No se requiere ningún plugin.**

**Regla crítica:** El `shortcut` en la propiedad de `MenuItemButton` solo activa el atajo si el usuario **tiene el menú abierto**. `CallbackShortcuts` + `Focus(autofocus: true)` son **obligatorios** para que los atajos funcionen desde cualquier parte de la app.

**`lib/main_window.dart`:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Estos shortcuts funcionan GLOBALMENTE sin necesidad de abrir el menú
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openUserDialog,
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): _showPrintDialog,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _refreshUsers,
      },
      child: Focus(
        autofocus: true, // Sin esto los shortcuts no se capturan al inicio
        child: Column(
          children: [
            MenuBar(
              children: [
                SubmenuButton(
                  // '&' antes de la letra define el acelerador Alt+F
                  child: const MenuAcceleratorLabel('&File'),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.add, size: 16),
                      onPressed: _openUserDialog,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
                      // '\t' genera el espaciado visual nativo del atajo a la derecha
                      child: const MenuAcceleratorLabel('&New User\tCtrl+N'),
                    ),
                    const Divider(),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.print, size: 16),
                      onPressed: _showPrintDialog,
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyP, control: true),
                      child: const MenuAcceleratorLabel('&Print Table\tCtrl+P'),
                    ),
                    const Divider(),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.exit_to_app, size: 16),
                      onPressed: _exitApp,
                      child: const MenuAcceleratorLabel('E&xit'),
                    ),
                  ],
                ),
                SubmenuButton(
                  child: const MenuAcceleratorLabel('&Modo'),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.people, size: 16),
                      onPressed: () => setState(() => _view = ViewState.users),
                      shortcut: const SingleActivator(LogicalKeyboardKey.digit1, control: true),
                      child: const MenuAcceleratorLabel('Ventana &Principal\tCtrl+1'),
                    ),
                  ],
                ),
              ],
            ),
            Expanded(child: _currentView),
          ],
        ),
      ),
    ),
  );
}
```

### Conceptos clave

| Concepto | Detalle |
|---|---|
| `MenuAcceleratorLabel('&File')` | `&` convierte la letra siguiente en acelerador `Alt+F` |
| `'\tCtrl+N'` en el label | `\t` genera el espaciado visual nativo del atajo a la derecha |
| `CallbackShortcuts` + `Focus(autofocus: true)` | Obligatorio para atajos globales (sin el menú abierto) |
| `shortcut` en `MenuItemButton` | Solo funciona mientras el menú está abierto — NO es suficiente solo |
| `RawMenuAnchor` | Para menús sin estilo por defecto, control total del layout (Flutter 3.32+) |
