import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'youtube_search_screen.dart' show YoutubeCard;
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

/// "Pratinjau": tampilan bab seperti saat dibaca pembaca.
class PartPreviewScreen extends StatelessWidget {
  final String storyTitle, title, body;

  /// Gambar yang disisipkan di bab (dari ikon gambar / video).
  final List<Uint8List> images;

  /// Tautan video YouTube yang disisipkan di bab.
  final List<String> videos;
  const PartPreviewScreen(
      {super.key,
      required this.storyTitle,
      required this.title,
      required this.body,
      this.images = const [],
      this.videos = const []});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1B1B1B);
    const serif = TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: ['Times New Roman', 'serif'],
        color: ink);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        Container(
          color: Colors.black,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back, size: 26),
                    onPressed: () => Navigator.pop(context)),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text(storyTitle.isEmpty ? 'Pratinjau' : storyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 22),
                    ]),
                    const Text('Daftar Isi', style: TextStyle(fontSize: 13)),
                  ]),
                ),
                const Icon(Icons.cloud_outlined, size: 24),
                const SizedBox(width: 14),
                const Text('Aa',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 34, 20, 30), children: [
            Text(title.isEmpty ? 'Tanpa judul' : title,
                textAlign: TextAlign.center,
                style: serif.copyWith(fontSize: 24)),
            const SizedBox(height: 26),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.remove_red_eye, size: 15, color: Color(0xFF8A8A8A)),
              SizedBox(width: 6),
              Text('0', style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13)),
              SizedBox(width: 34),
              Icon(Icons.star, size: 15, color: Color(0xFF8A8A8A)),
              SizedBox(width: 6),
              Text('0', style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13)),
              SizedBox(width: 34),
              Icon(Icons.comment, size: 15, color: Color(0xFF8A8A8A)),
              SizedBox(width: 6),
              Text('0', style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13)),
            ]),
            const SizedBox(height: 30),
            if (body.isNotEmpty || (images.isEmpty && videos.isEmpty))
              Text(body.isEmpty ? '(Bab ini masih kosong)' : body,
                  style: serif.copyWith(
                      fontSize: 18,
                      height: 1.6,
                      color: body.isEmpty ? const Color(0xFF9A9A9A) : ink)),
            for (final img in images)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(img,
                      width: double.infinity, fit: BoxFit.fitWidth),
                ),
              ),
            for (final v in videos)
              Padding(
                  padding: const EdgeInsets.only(top: 16), child: YoutubeCard(v)),
          ]),
        ),
        Container(
          color: const Color(0xFFF4F4F4),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
                _BarItem(Icons.star_border, 'Vote'),
                _BarItem(Icons.chat_bubble_outline, '0'),
                _BarItem(Icons.send_outlined, 'Bagikan'),
                Icon(Icons.more_vert, color: Color(0xFF555555)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BarItem(this.icon, this.label);
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: const Color(0xFF444444), size: 24),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A))),
      ]);
}

/// "Riwayat Revisi": kapan bab ini direvisi (hari, tanggal, bulan, tahun, jam).
class RevisionHistoryScreen extends StatelessWidget {
  final String partTitle;
  final List<DateTime> revisions;
  const RevisionHistoryScreen(
      {super.key, required this.partTitle, required this.revisions});

  @override
  Widget build(BuildContext context) {
    final list = revisions.reversed.toList();
    return Scaffold(
      appBar: wAppBar(context, title: 'Riwayat Revisi'),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                    'Belum ada revisi. Revisi dicatat setiap kali bab ini disimpan sebagai konsep atau dipublikasikan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.grey, fontSize: 16, height: 1.4)),
              ),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, color: Color(0xFF2E2E2E)),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  const Icon(Icons.history, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fmtFull(list[i]),
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          'Pukul ${fmtClock(list[i])}${i == 0 ? '  •  Terbaru' : ''}',
                          style: const TextStyle(color: C.grey, fontSize: 15)),
                    ]),
                  ),
                ]),
              ),
            ),
    );
  }
}
