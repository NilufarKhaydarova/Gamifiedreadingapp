import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Points sqflite at a fresh temp directory (FFI, no isolate), mocks
/// SharedPreferences and loads an empty .env so no AI keys are present —
/// every AI service therefore takes its offline fallback path.
Future<Directory> setUpTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  final dir = await Directory.systemTemp.createTemp('booklify_test_');
  await databaseFactory.setDatabasesPath(dir.path);
  SharedPreferences.setMockInitialValues({});
  dotenv.loadFromString(envString: 'UNUSED=1');
  return dir;
}

int _seq = 0;

/// Unique e-mail per call so tests sharing one DB never collide.
String uniqueEmail([String prefix = 'user']) =>
    '$prefix${DateTime.now().microsecondsSinceEpoch}_${_seq++}@test.dev';

/// Widget tests render text with the boxy "Ahem" font, which makes almost
/// every Row overflow. Load Roboto (shipped with the Flutter SDK) under the
/// families the app asks for so layout checks resemble a real device. The
/// app's 'Plus Jakarta Sans' is not bundled, so devices use the system font
/// too.
Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent
          .path;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  for (final family in ['Roboto', 'Plus Jakarta Sans', 'Georgia']) {
    final loader = FontLoader(family);
    for (final f in ['Regular', 'Medium', 'Bold', 'Italic']) {
      final file = File('${dir.path}/Roboto-$f.ttf');
      if (file.existsSync()) {
        loader.addFont(Future.value(
            ByteData.view(file.readAsBytesSync().buffer)));
      }
    }
    await loader.load();
  }
  final icons = File('${dir.path}/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer))))
        .load();
  }
}
