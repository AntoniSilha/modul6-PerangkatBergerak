import 'package:flutter/material.dart';

import '../repositories/sesi_repository.dart';

class PapanDiagnostikPenyimpanan extends StatefulWidget {
  final SesiRepository repository;

  const PapanDiagnostikPenyimpanan({
    super.key,
    required this.repository,
  });

  @override
  State<PapanDiagnostikPenyimpanan> createState() =>
      _PapanDiagnostikPenyimpananState();
}

class _PapanDiagnostikPenyimpananState
    extends State<PapanDiagnostikPenyimpanan> {
  bool _sedangMengintip = false;
  bool _sudahMengintip = false;
  String? _hasilIntip;

  Future<void> _intip() async {
    setState(() {
      _sedangMengintip = true;
    });

    String? hasil;
    String? pesanGagal;

    try {
      hasil = await widget.repository.intipMentah();
    } catch (e) {
      pesanGagal = 'Gagal membaca penyimpanan: $e';
    }

    if (!mounted) return;

    setState(() {
      _hasilIntip = pesanGagal ?? hasil;
      _sudahMengintip = true;
      _sedangMengintip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Papan diagnostik penyimpanan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Repository: ${widget.repository.nama}'),
            Text(widget.repository.keterangan),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sedangMengintip ? null : _intip,
              icon: _sedangMengintip
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.visibility_outlined),
              label: Text(
                _sedangMengintip
                    ? 'Memeriksa...'
                    : 'Intip isi penyimpanan',
              ),
            ),
            if (_sudahMengintip) ...[
              const SizedBox(height: 16),
              Text(
                'Hasil pembacaan mentah',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SelectableText(_hasilIntip ?? 'null'),
            ],
          ],
        ),
      ),
    );
  }
}