
import '../../../modul_06/models/sesi_pengguna.dart';
import '../../../modul_06/services/sesi_memori.dart';
import 'sesi_repository.dart';

class MemoriSesiRepository implements SesiRepository {
  final SesiMemori _memori;

  MemoriSesiRepository({
    SesiMemori? memori,
  }) : _memori = memori ?? SesiMemori();

  @override
  String get nama => 'Memori';

  @override
  String get keterangan =>
      'Sesi disimpan di memori dan hilang saat aplikasi ditutup.';

  @override
  bool get bertahanSetelahRestart => false;

  @override
  Future<SesiPengguna?> baca() async {
    return _memori.baca();
  }

  @override
  Future<void> simpan(SesiPengguna sesi) async {
    await _memori.simpan(sesi);
  }

  @override
  Future<void> hapus() async {
    await _memori.hapus();
  }

  @override
  Future<bool> adaSesi() async {
    return _memori.baca() != null;
  }

  @override
  Future<String?> intipMentah() async {
    return _memori.baca()?.token;
  }
}
