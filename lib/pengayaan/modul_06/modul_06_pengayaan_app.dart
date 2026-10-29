import 'package:flutter/material.dart';

import '../../modul_06/models/sesi_pengguna.dart';
import '../../modul_06/services/auth_api.dart';
import 'controllers/sesi_controller.dart';
import 'repositories/memori_sesi_repository.dart';
import 'repositories/aman_sesi_repository.dart';
import 'repositories/prefs_sesi_repository.dart';
import 'screens/beranda_pengayaan_screen.dart';
import 'screens/login_pengayaan_screen.dart';
import 'storage/penyimpanan_aman_platform.dart';
import 'widgets/gerbang_sesi.dart';


class Modul06PengayaanApp extends StatefulWidget {
  const Modul06PengayaanApp({super.key});

  @override
  State<Modul06PengayaanApp> createState() => _Modul06PengayaanAppState();
}

class _Modul06PengayaanAppState extends State<Modul06PengayaanApp> {
  late final AuthApi _api = const AuthApi();

  late final SesiController _kendali = SesiController(
    api: _api,
    repository: PrefsSesiRepository(),
  );

  @override
  void initState() {
    super.initState();
    _kendali.pulihkan();
  }

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modul 06 - Login dan Session',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
        ),
        useMaterial3: true,
      ),
      home: GerbangSesi(
        controller: _kendali,
        form: (BuildContext context) =>
            LoginPengayaanScreen(controller: _kendali),
        beranda: (BuildContext context, SesiPengguna sesi) =>
            BerandaPengayaanScreen(controller: _kendali, sesi: sesi),
      ),
    );
  }
}
