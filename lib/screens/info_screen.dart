import 'package:flutter/material.dart';
import '../widgets.dart';

const kTermsText =
    'Dengan memakai Wattpret kamu setuju untuk menghormati sesama pengguna, '
    'tidak membagikan konten yang melanggar hukum atau menyakiti orang lain, '
    'dan hanya mengunggah karya yang kamu miliki haknya.\n\n'
    'Ini adalah teks contoh untuk aplikasi tiruan (UI clone) dan bukan '
    'persyaratan resmi Wattpret.';

const kPrivacyText =
    'Kami hanya menyimpan data yang diperlukan agar akunmu berfungsi, seperti '
    'email, nama pengguna, dan preferensi genre.\n\n'
    'Ini adalah teks contoh untuk aplikasi tiruan (UI clone) dan bukan '
    'kebijakan privasi resmi Wattpret.';

class InfoScreen extends StatelessWidget {
  final String title, body;
  const InfoScreen(this.title, this.body, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Text(body,
              style: const TextStyle(
                  fontSize: 16, height: 1.5, color: Color(0xFFDDDDDD))),
        ),
      ),
    );
  }
}

/// Layar "Seri" saat belum ada seri yang dibuat.
class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Seri',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const WCollage(size: 118, bg: Color(0xFF2E2E2E)),
            const SizedBox(height: 22),
            const Text('Tidak ada seri yang dibuat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
                'Masuk ke Wattpret di web desktop untuk membuat dan mengedit serial kamu. Setiap perubahan yang kamu buat akan muncul di aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, height: 1.45, color: Color(0xFFDDDDDD))),
            const SizedBox(height: 24),
            WhiteButton('Info selengkapnya', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Buka wattpret.com di desktop untuk mengelola seri')));
            }),
          ]),
        ),
      ),
    );
  }
}
