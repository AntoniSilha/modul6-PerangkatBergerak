import 'package:flutter/material.dart';
import '../../../modul_06/services/auth_api.dart';
import '../../../modul_06/widgets/field_kata_sandi.dart';
import '../controllers/sesi_controller.dart';

class LoginPengayaanScreen extends StatefulWidget {
  final SesiController controller;

  const LoginPengayaanScreen({super.key, required this.controller});

  @override
  State<LoginPengayaanScreen> createState() => _LoginPengayaanScreenState();
}

class _LoginPengayaanScreenState extends State<LoginPengayaanScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _sandi = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  void _kirim() {
    if (widget.controller.sedangMemproses) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.controller.masuk(
      email: _email.text.trim(),
      sandi: _sandi.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modul 06 — Pengayaan (Aman)'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (BuildContext context, Widget? child) {
            final bool sibuk = widget.controller.sedangMemproses;
            final String? pesan = widget.controller.pesan;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                const SizedBox(height: 8),
                const Text(
                  'Masuk ke Portal Akademik',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Penyimpanan: ${widget.controller.repository.nama}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (pesan != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pesan,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _email,
                        enabled: !sibuk,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        validator: (String? val) {
                          final String teks = (val ?? '').trim();
                          if (teks.isEmpty) return 'Email wajib diisi.';
                          if (!teks.contains('@') || !teks.contains('.')) {
                            return 'Format email belum benar.';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FieldKataSandi(
                        controller: _sandi,
                        enabled: !sibuk,
                        validator: (String? nilai) {
                          if (nilai == null || nilai.isEmpty) {
                            return 'Kata sandi wajib diisi.';
                          }
                          if (nilai.length < 8) {
                            return 'Kata sandi minimal 8 karakter.';
                          }
                          return null;
                        },
                        onSubmitted: _kirim,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: sibuk ? null : _kirim,
                    icon: sibuk
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.login_rounded),
                    label: Text(sibuk ? 'Memproses…' : 'Masuk'),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Akun Demo:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('Email: ${AuthApi.emailDemo}'),
                        const Text('Sandi: ${AuthApi.sandiDemo}'),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: sibuk
                                ? null
                                : () => setState(() {
                              _email.text = AuthApi.emailDemo;
                              _sandi.text = AuthApi.sandiDemo;
                            }),
                            child: const Text('Isi Otomatis'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}