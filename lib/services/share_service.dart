import 'package:share_plus/share_plus.dart';

/// Comparte un archivo con el selector nativo de Android. share_plus
/// maneja el content:// URI / FileProvider internamente -- no hace
/// falta configurar nada más de nuestro lado.
class ShareService {
  static Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }
}
