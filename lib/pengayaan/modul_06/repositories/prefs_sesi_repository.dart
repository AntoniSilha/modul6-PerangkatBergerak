import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../modul_06/models/sesi_pengguna.dart';
import 'sesi_repository.dart';

class PrefsSesiRepository implements SesiRepository {
  static const String kunciSesi = 'sesi_pengguna';

  final Future<SharedPreferences> _prefs;

  PrefsSesiRepository({Future<SharedPreferences> Function()? pemuat})
      : _prefs = (pemuat ?? SharedPreferences.getInstance)();

  @override
  String get nama => 'SharedPreferences';

  @override
  String get keterangan =>
      'Penyimpanan preferensi biasa; bukan secure storage untuk token.';

  @override
  bool get bertahanSetelahRestart => true;

  @override
  Future<SesiPengguna?> baca() async {
    final SharedPreferences prefs = await _prefs;
    final String? mentah = prefs.getString(kunciSesi);
    if (mentah == null || mentah.isEmpty) return null;

    try {
      final Object? hasil = jsonDecode(mentah);
      if (hasil is Map<String, dynamic>) {
        return SesiPengguna.fromJson(hasil);
      }
      await hapus();
      return null;
    } catch (_) {
      await hapus();
      return null;
    }
  }

  @override
  Future<void> simpan(SesiPengguna sesi) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(kunciSesi, jsonEncode(sesi.toJson()));
  }

  @override
  Future<void> hapus() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(kunciSesi);
  }

  @override
  Future<bool> adaSesi() async => (await baca()) != null;

  @override
  Future<String?> intipMentah() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(kunciSesi);
  }
}
