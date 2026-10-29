import 'dart:convert';

import '../../../modul_06/models/sesi_pengguna.dart';
import '../storage/penyimpanan_aman.dart';
import 'sesi_repository.dart';

class AmanSesiRepository implements SesiRepository {
  static const String kunciSesi = 'sesi_pengguna';

  final PenyimpananAman penyimpanan;

  AmanSesiRepository({required this.penyimpanan});

  @override
  String get nama => 'Secure storage platform';

  @override
  String get keterangan =>
      'Menyimpan data sesi menggunakan API secure storage platform.';

  @override
  bool get bertahanSetelahRestart => true;

  @override
  Future<SesiPengguna?> baca() async {
    final String? mentah = await penyimpanan.baca(kunciSesi);
    if (mentah == null || mentah.isEmpty) return null;

    try {
      final Object? hasil = jsonDecode(mentah);
      if (hasil is Map<String, dynamic>) {
        return SesiPengguna.fromJson(hasil);
      }
      await hapus();
      return null;
    } catch (_) {
      // Data yang rusak dibuang agar pemulihan berikutnya tidak terus gagal.
      await hapus();
      return null;
    }
  }

  @override
  Future<void> simpan(SesiPengguna sesi) async {
    await penyimpanan.tulis(kunciSesi, jsonEncode(sesi.toJson()));
  }

  @override
  Future<void> hapus() => penyimpanan.hapus(kunciSesi);

  @override
  Future<bool> adaSesi() async => (await baca()) != null;

  @override
  Future<String?> intipMentah() => penyimpanan.bacaMentah(kunciSesi);
}