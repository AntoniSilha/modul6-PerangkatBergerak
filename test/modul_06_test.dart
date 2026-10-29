import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modul_06/modul_06/models/sesi_pengguna.dart';
import 'package:modul_06/modul_06/screens/login_screen.dart';
import 'package:modul_06/modul_06/services/auth_api.dart';
import 'package:modul_06/modul_06/services/sesi_memori.dart';
import 'package:modul_06/pengayaan/modul_06/controllers/sesi_controller.dart';
import 'package:modul_06/pengayaan/modul_06/repositories/aman_sesi_repository.dart';
import 'package:modul_06/pengayaan/modul_06/repositories/memori_sesi_repository.dart';
import 'package:modul_06/pengayaan/modul_06/repositories/prefs_sesi_repository.dart';
import 'package:modul_06/pengayaan/modul_06/storage/penyimpanan_aman.dart';
import 'package:modul_06/pengayaan/modul_06/widgets/gerbang_sesi.dart';

/// Fake secure storage agar unit test tidak memanggil plugin platform asli.
class PenyimpananAmanPalsu implements PenyimpananAman {
  final Map<String, String> data = <String, String>{};

  @override
  Future<void> tulis(String kunci, String nilai) async {
    data[kunci] = nilai;
  }

  @override
  Future<String?> baca(String kunci) async => data[kunci];

  @override
  Future<void> hapus(String kunci) async {
    data.remove(kunci);
  }

  @override
  Future<String?> bacaMentah(String kunci) async => null;
}

SesiPengguna buatSesi({
  String token = 'token-uji',
  DateTime? sekarang,
  Duration masaBerlaku = const Duration(hours: 2),
}) {
  return SesiPengguna.contoh(
    token: token,
    sekarang: sekarang ?? DateTime(2030, 1, 1, 8),
    masaBerlaku: masaBerlaku,
  );
}

void main() {
  group('Fase A - Model SesiPengguna', () {
    test('sesi dapat diubah menjadi JSON dan dibaca kembali', () {
      final awal = buatSesi();
      final hasil = SesiPengguna.fromJson(awal.toJson());

      expect(hasil.token, awal.token);
      expect(hasil.email, awal.email);
      expect(hasil.nama, awal.nama);
      expect(hasil.peran, awal.peran);
      expect(hasil.masukPada, awal.masukPada);
      expect(hasil.kedaluwarsaPada, awal.kedaluwarsaPada);
    });

    test('JSON yang tidak lengkap menggunakan nilai cadangan', () {
      final hasil = SesiPengguna.fromJson(<String, dynamic>{});

      expect(hasil.token, isEmpty);
      expect(hasil.email, 'tanpa-email');
      expect(hasil.nama, 'Pengguna');
      expect(hasil.peran, 'mahasiswa');
    });

    test('copyWith hanya mengubah field yang diminta', () {
      final awal = buatSesi();
      final hasil = awal.copyWith(token: 'token-baru');

      expect(hasil.token, 'token-baru');
      expect(hasil.email, awal.email);
      expect(hasil.kedaluwarsaPada, awal.kedaluwarsaPada);
    });

    test('label peran mahasiswa benar', () {
      expect(SesiPengguna.labelPeran('mahasiswa'), 'Mahasiswa');
    });

    test('label peran dosen benar', () {
      expect(SesiPengguna.labelPeran('dosen'), 'Dosen');
    });

    test('peran yang tidak dikenal menjadi Pengguna', () {
      expect(SesiPengguna.labelPeran('lainnya'), 'Pengguna');
    });

    test('sesi belum kedaluwarsa sebelum batas waktu', () {
      final mulai = DateTime(2030, 1, 1, 8);
      final sesi = buatSesi(sekarang: mulai);

      expect(sesi.sudahKedaluwarsa(mulai), isFalse);
      expect(sesi.sudahKedaluwarsa(mulai.add(const Duration(hours: 1))), isFalse);
    });

    test('sesi kedaluwarsa tepat pada batas waktunya', () {
      final mulai = DateTime(2030, 1, 1, 8);
      final sesi = buatSesi(sekarang: mulai, masaBerlaku: const Duration(hours: 1));

      expect(sesi.sudahKedaluwarsa(mulai.add(const Duration(hours: 1))), isTrue);
    });

    test('tanggal kedaluwarsa tidak valid dianggap kedaluwarsa', () {
      final sesi = SesiPengguna(
        token: 'token',
        email: 'student@trpl.test',
        nama: 'Mahasiswa TRPL',
        peran: 'mahasiswa',
        masukPada: 'tanggal-tidak-valid',
        kedaluwarsaPada: 'tanggal-tidak-valid',
      );

      expect(sesi.sudahKedaluwarsa(DateTime(2030)), isTrue);
    });

    test('sisa waktu dihitung dengan benar', () {
      final mulai = DateTime(2030, 1, 1, 8);
      final sesi = buatSesi(sekarang: mulai, masaBerlaku: const Duration(hours: 2));

      expect(sesi.sisaWaktu(mulai).inMinutes, 120);
      expect(sesi.sisaWaktu(mulai.add(const Duration(minutes: 30))).inMinutes, 90);
    });

    test('sisa waktu tidak pernah negatif', () {
      final mulai = DateTime(2030, 1, 1, 8);
      final sesi = buatSesi(sekarang: mulai, masaBerlaku: const Duration(hours: 1));

      expect(sesi.sisaWaktu(mulai.add(const Duration(hours: 2))), Duration.zero);
    });
  });

  group('Fase A - AuthApi tiruan', () {
    const api = AuthApi(tunda: Duration.zero);

    test('kredensial demo menghasilkan sesi', () async {
      final sesi = await api.masuk(
        email: AuthApi.emailDemo,
        sandi: AuthApi.sandiDemo,
      );

      expect(sesi.email, AuthApi.emailDemo);
      expect(sesi.nama, 'Mahasiswa TRPL');
      expect(sesi.token, startsWith('dummy.'));
    });

    test('kata sandi salah menghasilkan kode 401', () async {
      await expectLater(
        api.masuk(email: AuthApi.emailDemo, sandi: 'salah123'),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 401)),
      );
    });

    test('akun terkunci menghasilkan kode 423', () async {
      await expectLater(
        api.masuk(email: AuthApi.emailTerkunci, sandi: AuthApi.sandiDemo),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 423)),
      );
    });

    test('server bermasalah menghasilkan kode 503', () async {
      await expectLater(
        api.masuk(email: AuthApi.emailServerGangguan, sandi: AuthApi.sandiDemo),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 503)),
      );
    });

    test('email atau kata sandi kosong menghasilkan kode 400', () async {
      await expectLater(
        api.masuk(email: '', sandi: ''),
        throwsA(isA<AuthException>().having((e) => e.kode, 'kode', 400)),
      );
    });

    test('pembaruan sesi mempertahankan token dummy', () async {
      final sesi = await api.masuk(
        email: AuthApi.emailDemo,
        sandi: AuthApi.sandiDemo,
      );
      final diperbarui = await api.perbaruiSesi(sesi, masaBerlaku: const Duration(hours: 3));

      expect(diperbarui.token, sesi.token);
      expect(diperbarui.kedaluwarsaPada, isNot(sesi.kedaluwarsaPada));
    });
  });

  group('Fase A - SesiMemori', () {
    late SesiMemori memori;

    setUp(() {
      memori = SesiMemori();
    });

    test('awalnya tidak memiliki sesi', () {
      expect(memori.baca(), isNull);
      expect(memori.adaSesi, isFalse);
    });

    test('menyimpan sesi agar dapat dibaca kembali', () async {
      final sesi = buatSesi();
      await memori.simpan(sesi);

      expect(memori.baca()?.token, sesi.token);
      expect(memori.adaSesi, isTrue);
    });

    test('menghapus sesi dari memori', () async {
      await memori.simpan(buatSesi());
      await memori.hapus();

      expect(memori.baca(), isNull);
      expect(memori.adaSesi, isFalse);
    });

    test('menghitung jumlah penulisan sesi', () async {
      await memori.simpan(buatSesi(token: 'satu'));
      await memori.simpan(buatSesi(token: 'dua'));

      expect(memori.jumlahPenulisan, 2);
    });
  });

  group('Fase A - LoginScreen', () {
    Future<void> bukaLogin(WidgetTester tester, SesiMemori memori) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            api: const AuthApi(tunda: Duration.zero),
            sesiMemori: memori,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> isiKredensial(
        WidgetTester tester, {
          required String email,
          required String sandi,
        }) async {
      final kolom = find.byType(TextFormField);
      await tester.enterText(kolom.at(0), email);
      await tester.enterText(kolom.at(1), sandi);
    }

    testWidgets('menampilkan form login setelah tidak ada sesi', (tester) async {
      await bukaLogin(tester, SesiMemori());

      expect(find.text('Masuk ke Portal Akademik'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('email kosong ditolak oleh validator', (tester) async {
      await bukaLogin(tester, SesiMemori());
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi.'), findsOneWidget);
    });

    testWidgets('format email tidak benar ditolak', (tester) async {
      await bukaLogin(tester, SesiMemori());
      await isiKredensial(tester, email: 'email-salah', sandi: 'belajar123');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Format email belum benar.'), findsOneWidget);
    });

    testWidgets('kata sandi kosong ditolak', (tester) async {
      await bukaLogin(tester, SesiMemori());
      await isiKredensial(tester, email: AuthApi.emailDemo, sandi: '');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
    });

    testWidgets('kata sandi kurang dari delapan karakter ditolak', (tester) async {
      await bukaLogin(tester, SesiMemori());
      await isiKredensial(tester, email: AuthApi.emailDemo, sandi: '1234567');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
    });

    testWidgets('login demo menampilkan beranda', (tester) async {
      final memori = SesiMemori();
      await bukaLogin(tester, memori);
      await isiKredensial(tester, email: AuthApi.emailDemo, sandi: AuthApi.sandiDemo);
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
      expect(memori.adaSesi, isTrue);
    });

    testWidgets('kredensial salah menampilkan pesan aman', (tester) async {
      await bukaLogin(tester, SesiMemori());
      await isiKredensial(tester, email: AuthApi.emailDemo, sandi: 'sandi-salah');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    });

    testWidgets('akun terkunci menampilkan pesan terkunci', (tester) async {
      await bukaLogin(tester, SesiMemori());
      await isiKredensial(tester, email: AuthApi.emailTerkunci, sandi: AuthApi.sandiDemo);
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Akun terkunci sementara'), findsOneWidget);
    });

    testWidgets('gangguan server menampilkan pesan server', (tester) async {
      await bukaLogin(tester, SesiMemori());
      await isiKredensial(tester, email: AuthApi.emailServerGangguan, sandi: AuthApi.sandiDemo);
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Server sedang tidak dapat dihubungi'), findsOneWidget);
    });

    testWidgets('logout kembali ke form login', (tester) async {
      final memori = SesiMemori();
      await bukaLogin(tester, memori);
      await isiKredensial(tester, email: AuthApi.emailDemo, sandi: AuthApi.sandiDemo);
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Portal Akademik'), findsOneWidget);
      expect(memori.baca(), isNull);
    });
  });

  group('Fase B - kontrak repository sesi', () {
    test('MemoriSesiRepository menyimpan dan menghapus sesi', () async {
      final repository = MemoriSesiRepository();
      final sesi = buatSesi();

      await repository.simpan(sesi);
      expect((await repository.baca())?.token, sesi.token);
      expect(await repository.adaSesi(), isTrue);

      await repository.hapus();
      expect(await repository.baca(), isNull);
      expect(await repository.adaSesi(), isFalse);
      expect(repository.bertahanSetelahRestart, isFalse);
    });

    test('PrefsSesiRepository dapat membaca sesi dan isi mentah', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = PrefsSesiRepository();
      final sesi = buatSesi(token: 'token-prefs-uji');

      await repository.simpan(sesi);
      expect((await repository.baca())?.token, 'token-prefs-uji');
      expect(await repository.adaSesi(), isTrue);
      expect(await repository.intipMentah(), contains('token-prefs-uji'));
      expect(repository.bertahanSetelahRestart, isTrue);

      await repository.hapus();
      expect(await repository.baca(), isNull);
    });

    test('AmanSesiRepository menyimpan dan membaca sesi melalui adapter', () async {
      final storage = PenyimpananAmanPalsu();
      final repository = AmanSesiRepository(penyimpanan: storage);
      final sesi = buatSesi(token: 'token-aman-uji');

      await repository.simpan(sesi);
      expect((await repository.baca())?.token, 'token-aman-uji');
      expect(await repository.adaSesi(), isTrue);
      expect(repository.bertahanSetelahRestart, isTrue);
    });

    test('AmanSesiRepository tidak menampilkan pembacaan mentah', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      await repository.simpan(buatSesi(token: 'rahasia-uji'));

      expect(await repository.intipMentah(), isNull);
    });

    test('AmanSesiRepository menghapus sesi tersimpan', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      await repository.simpan(buatSesi());
      await repository.hapus();

      expect(await repository.baca(), isNull);
      expect(await repository.adaSesi(), isFalse);
    });
  });

  group('Fase B - SesiController', () {
    final sekarang = DateTime(2030, 1, 1, 8);

    SesiController buatController(AmanSesiRepository repository) {
      return SesiController(
        api: const AuthApi(tunda: Duration.zero),
        repository: repository,
        jam: () => sekarang,
      );
    }

    test('tanpa sesi tersimpan status menjadi keluar', () async {
      final controller = buatController(AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu()));
      addTearDown(controller.dispose);

      await controller.pulihkan();

      expect(controller.status, StatusSesi.keluar);
      expect(controller.sesi, isNull);
    });

    test('sesi aktif dipulihkan menjadi masuk', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      await repository.simpan(buatSesi(sekarang: sekarang));
      final controller = buatController(repository);
      addTearDown(controller.dispose);

      await controller.pulihkan();

      expect(controller.status, StatusSesi.masuk);
      expect(controller.sesi, isNotNull);
    });

    test('sesi kedaluwarsa dihapus saat pemulihan', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      await repository.simpan(
        buatSesi(
          sekarang: sekarang.subtract(const Duration(hours: 3)),
          masaBerlaku: const Duration(hours: 1),
        ),
      );
      final controller = buatController(repository);
      addTearDown(controller.dispose);

      await controller.pulihkan();

      expect(controller.status, StatusSesi.kedaluwarsa);
      expect(controller.sesi, isNull);
      expect(await repository.baca(), isNull);
    });

    test('login dengan kredensial demo menyimpan sesi', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      final controller = buatController(repository);
      addTearDown(controller.dispose);

      await controller.masuk(email: AuthApi.emailDemo, sandi: AuthApi.sandiDemo);

      expect(controller.status, StatusSesi.masuk);
      expect(controller.sesi?.email, AuthApi.emailDemo);
      expect(await repository.adaSesi(), isTrue);
    });

    test('login dengan sandi salah menampilkan status gagal', () async {
      final controller = buatController(AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu()));
      addTearDown(controller.dispose);

      await controller.masuk(email: AuthApi.emailDemo, sandi: 'salah123');

      expect(controller.status, StatusSesi.gagal);
      expect(controller.sesi, isNull);
    });

    test('logout menghapus sesi', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      final controller = buatController(repository);
      addTearDown(controller.dispose);

      await controller.masuk(email: AuthApi.emailDemo, sandi: AuthApi.sandiDemo);
      await controller.keluar();

      expect(controller.status, StatusSesi.keluar);
      expect(controller.sesi, isNull);
      expect(await repository.baca(), isNull);
    });

    test('sesi aktif dapat diperbarui', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      await repository.simpan(buatSesi(token: 'token-perbarui', sekarang: sekarang));
      final controller = buatController(repository);
      addTearDown(controller.dispose);
      await controller.pulihkan();

      await controller.perbaruiSesi();

      expect(controller.status, StatusSesi.masuk);
      expect(controller.sesi?.token, 'token-perbarui');
      expect(controller.sesi?.kedaluwarsaPada, isNot(buatSesi(sekarang: sekarang).kedaluwarsaPada));
    });

    test('sesi kedaluwarsa tidak dapat diperbarui', () async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      await repository.simpan(
        buatSesi(
          token: 'token-lama',
          sekarang: sekarang.subtract(const Duration(hours: 3)),
          masaBerlaku: const Duration(hours: 1),
        ),
      );
      final controller = buatController(repository);
      addTearDown(controller.dispose);
      await controller.pulihkan();

      await controller.perbaruiSesi();

      expect(controller.status, StatusSesi.kedaluwarsa);
      expect(controller.sesi, isNull);
      expect(await repository.baca(), isNull);
    });
  });

  group('Fase B - GerbangSesi', () {
    testWidgets('menampilkan form saat tidak ada sesi', (tester) async {
      final controller = SesiController(
        api: const AuthApi(tunda: Duration.zero),
        repository: AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu()),
      );
      addTearDown(controller.dispose);

      await controller.pulihkan();
      await tester.pumpWidget(
        MaterialApp(
          home: GerbangSesi(
            controller: controller,
            form: (_) => const Scaffold(body: Text('FORM LOGIN')),
            beranda: (_, __) => const Scaffold(body: Text('BERANDA')),
          ),
        ),
      );

      expect(find.text('FORM LOGIN'), findsOneWidget);
      expect(find.text('BERANDA'), findsNothing);
    });

    testWidgets('menampilkan indikator saat sesi sedang diperiksa', (tester) async {
      final controller = SesiController(
        api: const AuthApi(tunda: Duration.zero),
        repository: AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu()),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: GerbangSesi(
            controller: controller,
            form: (_) => const Scaffold(body: Text('FORM LOGIN')),
            beranda: (_, __) => const Scaffold(body: Text('BERANDA')),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('menampilkan beranda saat sesi sudah aktif', (tester) async {
      final repository = AmanSesiRepository(penyimpanan: PenyimpananAmanPalsu());
      await repository.simpan(buatSesi());
      final controller = SesiController(
        api: const AuthApi(tunda: Duration.zero),
        repository: repository,
      );
      addTearDown(controller.dispose);

      await controller.pulihkan();
      await tester.pumpWidget(
        MaterialApp(
          home: GerbangSesi(
            controller: controller,
            form: (_) => const Scaffold(body: Text('FORM LOGIN')),
            beranda: (_, sesi) => Scaffold(body: Text('BERANDA ${sesi.email}')),
          ),
        ),
      );

      expect(find.text('BERANDA student@trpl.test'), findsOneWidget);
      expect(find.text('FORM LOGIN'), findsNothing);
    });
  });
}
