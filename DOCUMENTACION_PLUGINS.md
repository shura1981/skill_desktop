# Arquitectura y Guía de Uso de Plugins - Flutter Desktop

Este documento proporciona una revisión **detallada e ilustrada con código** sobre cómo se estructuraron las distintas funcionalidades y plugins dentro del proyecto **User Manager (multi_window_app)**. Su propósito es servir como una guía robusta (boilerplate) para entender los patrones y reutilizar estos fragmentos en futuros proyectos de escritorio bajo Flutter.

*Nota: Únicamente se documentan aquí los plugins que **sí tienen un uso activo** comprobado en el código base, ignorando dependencias huérfanas.*

---

## 1. Gestión de Temas (Theming) y Estado Global
Para administrar el estado de forma reactiva en toda la aplicación, incluyendo el sistema de temas dinámico, se utiliza `flutter_riverpod` en conjunto con `shared_preferences` para la persistencia.

### `flutter_riverpod` + `shared_preferences`
La aplicación puede cambiar entre **Modo Claro, Oscuro o del Sistema**, y adicionalmente elegir un **Color de Acento** principal que afecta a toda la interfaz.

**Implementación del Modelo de Datos ( `lib/theme_provider.dart` ):**
Al utilizar Riverpod, agrupamos el estado en un `Notifier`. Los métodos para mutar el tema no sólo actualizan la vista inmediatamente (`state = state.copyWith(...)`), sino que además escriben en disco mediante las SharedPreferences:

```dart
class ThemeSettings {
  final ThemeMode mode;
  final Color color;

  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.color = const Color(0xFF1565C0), // Azul por defecto
  });

  ThemeSettings copyWith({ ThemeMode? mode, Color? color }) {
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
    
    // Carga de Tema (Claro/Oscuro/Sistema)
    final modeString = prefs.getString('theme_preference_mode');
    ThemeMode mode = ThemeMode.system;
    if (modeString != null) {
      mode = ThemeMode.values.firstWhere(
        (e) => e.name == modeString, orElse: () => ThemeMode.system,
      );
    }
    
    // Carga del Color de Acento
    final colorInt = prefs.getInt('theme_preference_color');
    Color color = const Color(0xFF1565C0);
    if (colorInt != null) color = Color(colorInt);

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
    await prefs.setInt('theme_preference_color', color.value);
  }
}

// Global Provider
final themeProvider = NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(() {
  return ThemeSettingsNotifier();
});
```

**Consumo en la UI ( `lib/theme_settings_dialog.dart` ):**
En cualquier widget que lea estas variables, se usa `ConsumerWidget` y `ref.watch`. Por ejemplo, en el diálogo de despliegue donde el usuario pulsa para escoger su paleta preferida:

```dart
class ThemeSettingsDialog extends ConsumerWidget {
  const ThemeSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchar los cambios reactivos
    final settings = ref.watch(themeProvider);

    return Dialog(
      child: Column(
        children: [
          // Selector de Tema Base
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: settings.mode,
            onChanged: (val) => ref.read(themeProvider.notifier).setMode(val!),
          ),
          
          // Selector de Color Acento
          InkWell(
            onTap: () => ref.read(themeProvider.notifier).setColor(myCustomColor),
            child: Container(color: myCustomColor), // Simulación simple
          )
        ],
      )
    );
  }
}
```

---

## 2. Sistema Operativo y Ventanas Múltiples

Gestionar ventanas en sistemas de escritorio bajo frameworks móviles es complejo. Aquí se agrupan los recursos para controlar el sistema de visibilidad, bandeja y arquitectura multi-ventana.

### `window_manager` y `tray_manager` (Soporte Multiplataforma para Íconos)
Estas dos librerías trabajan de la mano. `window_manager` previene los cierres por defecto y gestiona el foco nativo. `tray_manager` crea el pequeño icono inferior que se usa para despertar la aplicación desde el **Systray**.

#### Compatibilidad de Íconos del System Tray (Windows y Linux)
Al inicializar `tray_manager`, surge un desafío muy común entre plataformas respecto al ruteo de imágenes.
- **Linux:** Puede cargar y asimilar los íconos PNG declarados en la carpeta normal de `assets` de Flutter.
- **Windows:** Es estricto a las API win32 nativas, requiriendo obligatoriamente un formato `.ico` despachado desde **rutas absolutas del disco duro**, que dependen de si el archivo está siendo empaquetado para release o si se está corriendo localmente con `flutter run`.

Para solucionar esto de raíz, el proyecto cuenta con el siguiente puente de inicialización (`lib/main.dart`):

```dart
String resolveTrayIconPath() {
  if (Platform.isWindows) {
    // Buscar la ruta en disco de nuestro ejecutable compilado en Windows
    final exeDir = p.dirname(Platform.resolvedExecutable);
    
    // Posibles candidatos de ruteo
    final candidates = <String>[
      // Rutas para ejecutable ya generado (release)
      p.join(exeDir, 'resources', 'app_icon.ico'),
      // Rutas durante el modo debug/desarrollo (`flutter run`)
      p.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico'),
      p.normalize(p.join(exeDir, '..', 'resources', 'app_icon.ico')),
    ];
    
    for (final iconPath in candidates) {
      if (File(iconPath).existsSync()) {
        return iconPath; // Retorna ruta absoluta (C:\...\app_icon.ico)
      }
    }
  }
  // Para Linux y macOS retorna la ruta de asset normal
  return 'assets/tray_icon.png';
}

// ...
// Ya dentro del método main() de Flutter
await trayManager.setIcon(resolveTrayIconPath());
```

#### Creación y Despliegue del Menú Contextual (Click Derecho)
Un System Tray es mucho más útil si brinda opciones al hacer _click derecho_ sobre el icono. En este proyecto se configura el `Menu` con sus respectivas acciones, y luego se interceptan los eventos nativos (cuidando las diferencias sutiles entre Linux y Windows para saber exactamente _cuándo_ levantar el menú flotante).

**1. Configuración del Menú Base (`lib/main.dart`):**
```dart
await trayManager.setContextMenu(Menu(
  items: [
    MenuItem(
      label: 'Show Window', 
      onClick: (_) async {
        await windowManager.show();
        await windowManager.focus();
      },
    ),
    MenuItem.separator(), // Añade un separador nativo
    MenuItem(
      label: 'Refresh', 
      onClick: (_) {
         // Comunicación mediante un Notifier global
         MainWindowRefreshNotifier.instance.notify();
      }
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
// Tooltip al hacer hover sobre el ícono
await trayManager.setToolTip('User Manager');
```

**2. Despliegue seguro multiplataforma (`lib/main_window.dart`):**
Para invocar ese menú sin que haya superposiciones (o se "coma" el click en diferentes SO), el gestor distingue los eventos:

```dart
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

  /// Evento click Izquierdo en el Icono de Bandeja
  @override
  void onTrayIconMouseDown() async {
    if (!await windowManager.isFocused()) {
      if (await windowManager.isMinimized()) await windowManager.restore();
      if (Platform.isLinux) await windowManager.hide(); // Solución Wayland
      
      await windowManager.show();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 300));
      await windowManager.setAlwaysOnTop(false);
    }
  }

  /// Despliegue del menú contextual en WINDOWS (Click derecho presionado)
  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows) {
      trayManager.popUpContextMenu();
    }
  }

  /// Despliegue del menú contextual en LINUX (Click derecho soltado)
  @override
  void onTrayIconRightMouseUp() {
    if (Platform.isLinux) {
      trayManager.popUpContextMenu();
    }
  }

  /// Interceptar el evento "Cerrar" nativo de la barra superior (la (X) roja)
  @override
  void onWindowClose() async {
    final shouldExit = await showDialog<bool>(...); 
    if (shouldExit == true) {
      await windowManager.close();
      exit(0);
    }
  }
}
```

### `desktop_multi_window`
Al manejar sistemas con ventanas que necesitan vivir en contextos separados (ej. Un panel de formulario de usuario paralelo a su DataGrid principal), Flutter emplea instanciaciones de Multi-ventana de manera paralela.

Una ventana hija puede comunicarse con la ventana principal y viceversa o, también "ocultarse" temporalmente para rehusar cerrar el thread nativo de esa ventana.

```dart
import 'package:desktop_multi_window/desktop_multi_window.dart';

// Ocultar la ventana en lugar de destruirla para mejor rendimiento al reabrirse (ej: user_form_window.dart)
Future<void> _hideWindow() async {
  final self = await WindowController.fromCurrentEngine();
  await self.hide();
}

// Envío de señales de comunicación Inter-Ventana: Disparar refresco
final mainId = widget.mainWindowId;
if (mainId != null) {
  final mainController = WindowController.fromWindowId(mainId);
  await mainController.invokeMethod('refresh');
}
```

### `local_notifier`
Integrado a nivel base de programa para despachar notificaciones enriquecidas directas al sistema de alertas de Windows o Linux.

```dart
// En el `lib/main.dart`:
await localNotifier.setup(appName: 'User Manager');

// (Para usos futuros: Invocar una notificación global con sus args)
await localNotifier.showNotificationFromArgs({
  'title': 'User Manager',
  'body': 'Usuario ha sido añadido correctamente.',
});
```

---

## 3. Base de Datos FFI para Desktop (`sqflite_common_ffi` y `path_provider`)

En Flutter Desktop no se puede utilizar `sqflite` a secas porque está ligado en Java/ObjC a las rutas y wrappers de mobile. Para escritorio, se delega al plugin `sqflite_common_ffi` que enlaza bibliotecas C.

**Lógica principal (`lib/database_helper.dart`):**
Haciendo uso del patrón Singleton y con las API de rutas, se instala el DB.

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // 1. Inicialización vital FFI para que Desktop entienda el motor de SQFlite
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 2. Traer el directorio "Mis Documentos" nativo para la Base de Datos
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    // 3. Abrir la BD (y ejecutar onCreate de ser versión limpia)
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _createDB),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dob TEXT NOT NULL,
        phone TEXT NOT NULL
      )
    ''');
  }

  // Ejemplo puro de un query simple
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'id ASC');
  }
}
```

---

## 4. Generación de Archivos (PDF) e Impresión Nativa

Para exportar registros tabulares o imprimir nativamente, se unen `pdf` (Capa visual de armado en vectores PDF) y `printing` (Puente hacia los spoolers de impresoras de los SOs nativos).

**Configuración Completa (`lib/print_service.dart`):**

```dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Se usan widgets de pdf como homólogos de Flutter

class PrintService {
  static Future<Uint8List> generateUsersPdf(List<Map<String, dynamic>> users) async {
    final pdf = pw.Document(
      title: 'Users List',
      creator: 'User Manager App',
    );

    // Se maneja la paginación con `pw.MultiPage` de forma transparente
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Reporte', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          
          pw.Table.fromTextArray(
            context: context,
            headers: ['ID', 'Name', 'D.O.B', 'Phone'],
            data: users.map((u) => [
              u['id'].toString(), u['name'], u['dob'], u['phone']
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página \${context.pageNumber} de \${context.pagesCount}'),
        ),
      ),
    );

    // Retorna los bytes, listos para ser arrojados al plugin `printing` o guardados al disco.
    return pdf.save(); 
  }
}
```

---

## 5. Cliente SMTP/IMAP (Manejo de Correos Avanzado)

Para procesar correos se usa `enough_mail`, un cliente extenso que permite leer el buzón a profundidad y procesar secuencias MIME (Multipart) de adjuntos o HTML. En paralelo a esto, se usa `flutter_widget_from_html` para renderizar el código HTML seguro directamente sobre el Canvas interno de la App.

**Implementación Core (`lib/email_service.dart`):**

```dart
import 'package:enough_mail/enough_mail.dart';

Future<List<EmailModel>> getUnreadEmails() async {
  final client = ImapClient(isLogEnabled: false);
  
  try {
    // 1. Establecer comunicación con Servidor
    await client.connectToServer('mail.servidor.com', 993, isSecure: true);
    await client.login('mimail@servidor.com', 'password123');

    final mailbox = await client.selectInbox();
    
    // 2. Ejecutar búsqueda basada en comandos estándares (UNSEEN = no leídos)
    final searchResult = await client.searchMessages(searchCriteria: 'UNSEEN');
    
    final List<EmailModel> emails = [];
    if (searchResult.matchingSequence != null) {
      final sequence = searchResult.matchingSequence!;
      
      // 3. Obtener todo el sobre y el cuerpo del mensaje PEEK[] para no marcarlos como leídos
      final fetchResult = await client.fetchMessages(sequence, '(FLAGS ENVELOPE BODY.PEEK[])');

      for (final message in fetchResult.messages) {
        
        // Comprobar adjuntos internos leyendo sus partes
        List<String> attachmentNames = [];
        if (message.hasAttachments() && message.parts != null) {
          for (final part in message.parts!) {
            final fileName = part.decodeFileName();
            if (fileName != null) attachmentNames.add(fileName);
          }
        }

        emails.add(EmailModel(
          sender: message.fromEmail ?? 'Desconocido',
          subject: message.decodeSubject() ?? 'Sin Asunto',
          date: message.decodeDate() ?? DateTime.now(),
          attachmentNames: attachmentNames,
          originalMessage: message, // Preservamos todo el MIME type original
        ));
      }
    }
    return emails;
  } finally {
    // Siempre asegurar la desconexión
    if (client.isLoggedIn) await client.logout();
  }
}
```

**Visor del Cuerpo HTML en Interface (`lib/email_detail_view.dart`):**
Una vez obtenido un texto crudo de base de datos o correo en formatos web, lo transcribimos nativamente aprovechando CSS embebido e iframes.

```dart
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

//...
Widget build(context) {
  return HtmlWidget(
    _htmlBody, // Cadena extraída del cuerpo del MIME Email
    textStyle: const TextStyle(fontSize: 14),
    // Esto se encarga hasta de leer src='base64...' o links img remotos
    renderMode: RenderMode.column,
    factoryBuilder: () => MyWidgetFactory(),
  );
}
```

---

## 6. Menús de Aplicación y Atajos de Teclado (Accelerators)

En aplicaciones de Escritorio, uno de los factores más importantes de la Experiencia de Usuario (UX) son las barras de menú superiores y sus respectivos atajos de teclado globales. Aunque esto lo provee el SDK de Flutter de forma nativa (sin third-party plugins adicionales), este proyecto contiene una implementación arquitectónica muy cuidada sobre cómo ensamblar esta estructura.

Para que los menús funcionen, reconozcan los atajos _incluso si el usuario no tiene el foco en el menú_ y reaccionen a la tecla `Alt` (los aceleradores visuales subrayados), se usa una combinación de `CallbackShortcuts`, `Focus`, y el ecosistema de widgets de `MenuBar`.

**Implementación Arquitectónica (`lib/main_window.dart`):**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // 1. Envolver todo en CallbackShortcuts para escuchar las combinaciones (Ctrl+N, Ctrl+R, etc.)
    // de manera global sin importar qué widget inferior se esté tocando.
    body: CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _openUserDialog(),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): _showPrintDialog,
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): _refreshUsers,
      },
      // 2. Se necesita un área de Focus principal para que el árbol visual intercepte eventos de teclado
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            // 3. El Widget MenuBar define la barra de menús en sí
            MenuBar(
              children: [
                SubmenuButton(
                  // El carácter '&' antes de una letra define el Acelerador. 
                  // '&File' permite que al presionar 'Alt + F' se despliegue este submenú.
                  child: const MenuAcceleratorLabel('&File'),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.add, size: 16),
                      onPressed: () => _openUserDialog(),
                      // Renderiza la combinación de atajo visual a la derecha
                      shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
                      // '&New User\tCtrl+N' hace que 'Alt + N' sea útil mientras se navega el menú, además de imprimir 'Ctrl+N' a la derecha
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
                      onPressed: () => onWindowClose(),
                      child: const MenuAcceleratorLabel('E&xit'),
                    ),
                  ],
                ),
                SubmenuButton(
                  child: const MenuAcceleratorLabel('&Modo'),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.people, size: 16),
                      onPressed: () => setState(() => _currentView = ViewState.users),
                      shortcut: const SingleActivator(LogicalKeyboardKey.digit1, control: true),
                      child: const MenuAcceleratorLabel('Ventana &Principal\tCtrl+1'),
                    ),
                  ],
                ),
              ],
            ),

            // 4. El resto de la vista (ej. DataTable, Lista de Emails, etc.)
            Expanded(
              child: _currentView == ViewState.emails ? EmailView() : DataTableView(),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### Conceptos Clave de esta implementación:
*   **`CallbackShortcuts` + `Focus`**: Es obligatorio para las aplicaciones de Flutter Desktop. Si pones el atajo solo de forma visual en la propiedad `shortcut` del `MenuItemButton`, el atajo *solo* funcionará si el usuario abre el menú manualmente primero. Al usar `CallbackShortcuts`, el atajo funciona desde cualquier parte de la aplicación.
*   **`MenuAcceleratorLabel`**: Es el widget dedicado que "parsea" el ampersand (`&`). Convierte la letra siguiente en un atajo que responde inmediatamente al presionar la tecla <kbd>Alt</kbd> seguida de la respectiva letra (por ejemplo, <kbd>Alt</kbd> + <kbd>F</kbd> para File). El tag `\tCtrl+...` añade un alineamiento visual hermoso de tabulación a la derecha, imitando nativamente a Windows, macOS y Linux.
