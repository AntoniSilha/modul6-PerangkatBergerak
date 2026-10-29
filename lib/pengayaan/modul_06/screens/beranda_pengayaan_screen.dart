
import 'package:flutter/material.dart';

import '../../../modul_06/models/sesi_pengguna.dart';
import '../controllers/sesi_controller.dart';

class BerandaPengayaanScreen extends StatelessWidget {
  final SesiController controller;
  final SesiPengguna sesi;

  const BerandaPengayaanScreen({
    super.key,
    required this.controller,
    required this.sesi,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime? batas =
    DateTime.tryParse(sesi.kedaluwarsaPada);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Pengayaan'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Keluar',
            onPressed: controller.keluar,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 40,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Selamat datang, ${sesi.nama}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 12),
                  Text('Email: ${sesi.email}'),
                  Text(
                    'Peran: ${SesiPengguna.labelPeran(sesi.peran)}',
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Token Sesi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    sesi.token,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text('Masuk pada: ${sesi.masukPada}'),
                  Text('Kedaluwarsa: ${sesi.kedaluwarsaPada}'),

                  if (batas != null)
                    Text(
                      'Sisa waktu: '
                          '${sesi.sisaWaktu(DateTime.now()).inMinutes} menit',
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: controller.sedangMemproses
                ? null
                : controller.perbaruiSesi,
            icon: const Icon(Icons.refresh),
            label: const Text('Perbarui sesi'),
          ),

          OutlinedButton.icon(
            onPressed: controller.keluar,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),

          const SizedBox(height: 12),
          const Text(
            'Catatan: token sesi di aplikasi ini adalah data dummy '
                'untuk praktikum.',
          ),
        ],
      ),
    );
  }
}
