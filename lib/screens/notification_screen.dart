import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';
import 'main_shell.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Widget _notif(String text) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: BorderRadius.circular(30)),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: C.orange, borderRadius: BorderRadius.circular(9)),
            child: const WLogo(size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Expanded(
                        child: Text('Wattpret',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17))),
                    Text('baru saja',
                        style: TextStyle(color: C.grey, fontSize: 14)),
                  ]),
                  Text(text, style: const TextStyle(fontSize: 17)),
                ]),
          ),
        ]),
      );

  Widget _item(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(children: [
          Icon(i, size: 26),
          const SizedBox(width: 18),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 18))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 18),
            const Text('Tetap terhubung\ndengan notifikasi',
                style: TextStyle(
                    fontSize: 31, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              decoration: BoxDecoration(
                  color: const Color(0xFF7D4A3A),
                  borderRadius: BorderRadius.circular(36)),
              child: Column(children: [
                _notif('Kamu memiliki komentar baru'),
                _notif('Kamu menerima 10 Koin'),
                _notif('Bab baru telah dipublikasi'),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('Izinkan notifikasi untuk mendapat kabar tentang:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            _item(Icons.menu_book, 'Cerita dan penulis yang kamu ikuti'),
            _item(Icons.chat_bubble_outline, 'Komentar dan balasan'),
            _item(Icons.monetization_on_outlined, 'Diskon, penawaran, dan hadiah'),
            _item(Icons.contact_page_outlined,
                'Rekomendasi cerita yang dipersonalisasi'),
            _item(Icons.newspaper, 'Berita dan acara spesial'),
            const Spacer(),
            WhiteButton('Lanjutkan',
                onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (r) => false)),
          ]),
        ),
      ),
    );
  }
}
