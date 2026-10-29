import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/receipt_settings_model.dart';

class ReceiptSettingsDataSource {
  final SupabaseClient _db;
  static const _table = 'receipt_settings';
  static const _bucket = 'receipt_image';

  ReceiptSettingsDataSource(this._db);

  Future<ReceiptSettings> fetch(String branchId) async {
    final res = await _db.from(_table).select().maybeSingle();

    if (res == null) {
      final def = const ReceiptSettings();
      await _db.from(_table).insert(def.toMap());
      return def;
    }
    return ReceiptSettings.fromMap(res);
  }

  Future<void> upsert(ReceiptSettings settings) async {
    final existing = await _db.from(_table).select('id').maybeSingle();
    if (existing == null) {
      await _db.from(_table).insert(settings.toMap());
    } else {
      await _db.from(_table).update(settings.toMap()).eq('id', existing['id']);
    }
  }

  // ← Logo upload function
  Future<String> uploadLogo(String branchId, File file) async {
    final ext = file.path.split('.').last;
    final path = 'logos/$branchId.$ext';

    await _db.storage
        .from(_bucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    final url = _db.storage.from(_bucket).getPublicUrl(path);
    return url;
  }
}
