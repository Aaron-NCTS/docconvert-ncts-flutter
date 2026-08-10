import 'package:flutter/foundation.dart';

import '../models/document_item.dart';
import '../services/document_repository.dart';

/// Estado centralizado de "Archivos creados" -- Inicio y la pantalla de
/// Documentos escuchan este mismo provider, así que crear/renombrar/
/// eliminar un archivo en cualquier pantalla se refleja de inmediato en
/// las demás sin tener que refrescar manualmente.
class DocumentsProvider extends ChangeNotifier {
  DocumentsProvider(this._repository);

  final DocumentRepository _repository;

  List<DocumentItem> _items = [];
  bool _loading = true;

  List<DocumentItem> get items => _items;
  bool get isLoading => _loading;

  List<DocumentItem> get pdfItems => _items.where((d) => d.isPdf).toList();
  List<DocumentItem> get docxItems => _items.where((d) => d.isDocx).toList();
  List<DocumentItem> get photoItems => _items.where((d) => d.isFromPhotos).toList();

  Future<void> load() async {
    _items = await _repository.loadValid();
    _loading = false;
    notifyListeners();
  }

  Future<void> registerCreatedFile(DocumentItem item) async {
    await _repository.add(item);
    await load();
  }

  Future<void> removeItem(String id) async {
    await _repository.remove(id);
    await load();
  }

  Future<void> renameItem(String id, String newBaseName) async {
    await _repository.rename(id, newBaseName);
    await load();
  }
}
