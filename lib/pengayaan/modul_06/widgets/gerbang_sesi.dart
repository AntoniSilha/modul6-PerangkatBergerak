
import 'package:flutter/material.dart';

import '../../../modul_06/models/sesi_pengguna.dart';
import '../controllers/sesi_controller.dart';

typedef PembuatFormSesi = Widget Function(
    BuildContext context,
    );

typedef PembuatBerandaSesi = Widget Function(
    BuildContext context,
    SesiPengguna sesi,
    );

class GerbangSesi extends StatelessWidget {
  final SesiController controller;
  final PembuatFormSesi form;
  final PembuatBerandaSesi beranda;

  const GerbangSesi({
    super.key,
    required this.controller,
    required this.form,
    required this.beranda,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.status == StatusSesi.memeriksa) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (controller.status == StatusSesi.masuk) {
          final SesiPengguna? sesi = controller.sesi;

          if (sesi != null) {
            return beranda(context, sesi);
          }
        }

        return form(context);
      },
    );
  }
}
