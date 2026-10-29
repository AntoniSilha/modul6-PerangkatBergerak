abstract class PenyimpananAman {
  Future<void> tulis(String kunci, String nilai);
  Future<String?> baca(String kunci);
  Future<void> hapus(String kunci);

  /// Antarmuka demo untuk membandingkan kemampuan adapter; bukan alat forensik.
  Future<String?> bacaMentah(String kunci);
}