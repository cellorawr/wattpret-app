import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'genre_screen.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 22, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 70),
            const Icon(Icons.mark_email_read_outlined, color: C.orange, size: 62),
            const SizedBox(height: 38),
            const Text('Verifikasi email kamu',
                style: TextStyle(fontSize: 31, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                  style: const TextStyle(
                      fontSize: 18, height: 1.35, color: Color(0xFFBDBDBD)),
                  children: [
                    const TextSpan(
                        text: 'Silakan buka email yang baru saja kami kirimkan ke '),
                    TextSpan(
                        text: AppState.email,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const TextSpan(
                        text:
                            ' dan selesaikan proses verifikasi. Dengan melakukan proses ini, keamanan akunmu dapat terjaga, kamu dapat menulis di Wattpret dan mengakses fitur sosial seperti berkomentar.'),
                  ]),
            ),
            const SizedBox(height: 26),
            const Text(
                'Periksa juga folder spam untuk memastikan kamu tidak melewatkan emailnya.',
                style: TextStyle(
                    fontSize: 18, height: 1.35, color: Color(0xFFBDBDBD))),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WhiteButton('Mengerti',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GenreScreen()))),
            ),
          ]),
        ),
      ),
    );
  }
}
