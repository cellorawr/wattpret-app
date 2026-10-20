import 'package:flutter/material.dart';
import 'ranking_screen.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'other_profile_screen.dart';
import 'reader_screen.dart';
import 'reading_list_sheets.dart';

export 'reader_screen.dart' show ReaderScreen;

void openStory(BuildContext context, Story s) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoryScreen(s)));
}

String _oneLine(String t) => t.replaceAll('\n', ' ');

int _hash(String t) {
  var h = 0;
  for (final c in t.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

bool _isComplete(Story s) => _hash(s.title) % 3 == 0;

String _genreOf(Story s) {
  for (final c in kCategories) {
    if (storiesFor(c).any((x) => x.title == s.title)) return c;
  }
  return 'Romansa';
}

String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

/// Halaman detail cerita (tab Ringkasan / Bab), meniru aplikasi Wattpret asli.
class StoryScreen extends StatefulWidget {
  final Story story;
  const StoryScreen(this.story, {super.key});
  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  int _tab = 0;
  bool _more = false;
  int _rec = 0;
  Story get s => widget.story;

  @override
  void initState() {
    super.initState();
    ServerCache.tick.addListener(_onServer);
    if (s.id != null) {
      ServerCache.loadDetail(s.id!).then((d) {
        if (d != null) AppState.applyDetail(s, d);
      });
    }
  }

  void _onServer() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ServerCache.tick.removeListener(_onServer);
    super.dispose();
  }

  String get _synopsis => s.synopsis.isNotEmpty
      ? s.synopsis
      : '#${_cap(s.tags.first)}Series1\n\n'
          '"Pertunangan kita ini harus dirahasiakan!"\n\n'
          'Sebuah cerita ${s.tags.first} yang mengajakmu mengikuti perjalanan '
          'para tokohnya, bab demi bab. Mulai baca sekarang, tambahkan ke '
          'Perpustakaan, dan jangan lupa tinggalkan komentarmu.';

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _read([int chapter = -1]) async {
    // pastikan daftar bab dari server sudah ada sebelum pembaca dibuka
    if (s.id != null) {
      final d = await ServerCache.loadDetail(s.id!);
      if (d != null) AppState.applyDetail(s, d);
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => ReaderScreen(s, chapter: chapter)));
  }

  // ------------------------------ bagian atas ------------------------------
  Widget _topBar() => SafeArea(
        bottom: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 48,
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back, size: 26),
                  onPressed: () => Navigator.pop(context)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 26),
                onPressed: () => showIosSheet(
                    context,
                    [
                      'Bagikan cerita',
                      AppState.inLibrary(s)
                          ? 'Hapus dari Perpustakaan'
                          : 'Tambah ke Perpustakaan',
                    ], (v) {
                  if (v == 'Bagikan cerita') {
                    Clipboard.setData(ClipboardData(
                        text:
                            'Baca "${_oneLine(s.title)}" oleh ${s.author} di Wattpret'));
                    _snack('Info cerita disalin');
                  } else if (AppState.inLibrary(s)) {
                    AppState.removeFromLibrary(s);
                    _snack('Dihapus dari Perpustakaan');
                  } else {
                    AppState.addToLibrary(s);
                    _snack('Ditambahkan ke Perpustakaan');
                  }
                }),
              ),
            ]),
          ),
          const Divider(height: 1, color: C.line),
        ]),
      );

  Widget _header() {
    final votes = votesOf(s);
    Widget stat(IconData i, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 22, color: const Color(0xFFE6E6E6)),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 16, color: Color(0xFFE6E6E6))),
        ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BookCover(s, w: 98, h: 155),
        const SizedBox(width: 18),
        Expanded(
          child: SizedBox(
            height: 155,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_oneLine(s.title),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => openProfile(context, s.author),
                child: Row(children: [
                  LetterAvatar(s.author, size: 26),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(s.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17, color: Color(0xFFD0D0D0))),
                  ),
                ]),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  stat(Icons.remove_red_eye_outlined, s.views),
                  const SizedBox(width: 14),
                  stat(Icons.star_border, votes),
                  const SizedBox(width: 14),
                  stat(Icons.format_list_bulleted, '${s.parts} bab'),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tabs() => Container(
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = i),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: _tab == i ? C.orange : Colors.transparent,
                              width: 3))),
                  child: Text(i == 0 ? 'Ringkasan' : 'Bab',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _tab == i ? Colors.white : C.grey)),
                ),
              ),
            ),
        ]),
      );

  // ------------------------------ tab Ringkasan ------------------------------
  Widget _chip(String t) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFF232323), borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: const TextStyle(fontSize: 16)),
      );

  Widget _summary() {
    final complete = _isComplete(s);
    final h = _hash(s.title);
    final date = AppState.updatedOf(s);
    final tags = s.tags.take(3).toList();
    final genre = _genreOf(s);
    final recs = allStories.where((x) => x.title != s.title).toList();
    final start = recs.isEmpty ? 0 : h % recs.length;
    final list = [
      for (var i = 0; i < 6 && i < recs.length; i++) recs[(start + i) % recs.length]
    ];
    final rec = list.isEmpty ? null : list[_rec % list.length];
    Widget infoRow(IconData icon, Widget child, {double top = 0}) => Padding(
          padding: EdgeInsets.fromLTRB(16, top, 16, 0),
          child: Row(children: [
            Icon(icon, size: 26),
            const SizedBox(width: 14),
            Flexible(child: child),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      infoRow(
          Icons.menu_book_outlined,
          Text(complete ? 'Lengkap' : 'Bersambung',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          top: 24),
      infoRow(
          Icons.campaign_outlined,
          Text('Publikasi terakhir ${fmtDate(date)}',
              style: const TextStyle(fontSize: 17, color: Color(0xFFE0E0E0))),
          top: 22),
      infoRow(
          Icons.info_outline,
          Text('Fiksi  •  $genre',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, color: Color(0xFFE0E0E0))),
          top: 22),
      const SizedBox(height: 24),
      const Divider(height: 1, color: C.line),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Row(children: [
          const Text('Tag', style: TextStyle(fontSize: 16, color: C.grey)),
          const SizedBox(width: 14),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final t in tags) _chip(t),
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('Lebih banyak',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text(_synopsis,
            maxLines: _more ? null : 4,
            overflow: _more ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, height: 1.35, color: Color(0xFFE0E0E0))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: GestureDetector(
          onTap: () => setState(() => _more = !_more),
          child: Text(_more ? 'Tampilkan lebih sedikit' : 'Baca selengkapnya',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(height: 20),
      const Divider(height: 1, color: C.line),
      InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StoryRankingScreen(s, genre: genre.toLowerCase()))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(children: [
            Text('#${(h % 9) + 1}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFF232323),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(s.tags.first, style: const TextStyle(fontSize: 16)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 26),
          ]),
        ),
      ),
      const PremiumCard(),
      const Divider(height: 1, color: C.line),
      if (rec != null) ...[
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 14),
          child: Text('Kamu mungkin juga menyukai ini',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        ),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12),
            children: [
              for (var i = 0; i < list.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _rec = i),
                  child: Padding(
                    padding: EdgeInsets.only(right: 10, top: i == _rec % list.length ? 0 : 6),
                    child: BookCover(list[i],
                        w: i == _rec % list.length ? 100 : 90,
                        h: i == _rec % list.length ? 150 : 138),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 4, 0),
          child: Row(children: [
            Expanded(
              child: Text(_oneLine(rec.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 24),
              onPressed: () => showAddToSheet(context, rec),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(children: [
            const Icon(Icons.format_list_bulleted, size: 18, color: C.grey),
            const SizedBox(width: 8),
            Text('${rec.parts} bab',
                style: const TextStyle(fontSize: 15, color: C.grey)),
            const SizedBox(width: 10),
            const Text('•', style: TextStyle(color: C.grey)),
            const SizedBox(width: 10),
            Text(_isComplete(rec) ? 'Lengkap' : 'Bersambung',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: C.grey)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text(
              rec.synopsis.isNotEmpty
                  ? rec.synopsis
                  : 'Sebuah cerita ${rec.tags.first} oleh ${rec.author}. Mulai baca dan temukan kisahnya.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFFBDBDBD))),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => openStory(context, rec),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Detail lebih lanjut',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 22),
              ]),
            ),
          ),
        ),
      ],
      const SizedBox(height: 20),
    ]);
  }

  // ------------------------------ tab Bab ------------------------------
  Widget _chapters() {
    final titles = chapterTitles(s);
    return Column(children: [
      for (var i = 0; i < titles.length; i++)
        InkWell(
          onTap: () => _read(i),
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: C.line))),
            child: Row(children: [
              Expanded(
                child: Text(titles[i],
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Text(fmtChapterDate(chapterDate(s, i)),
                  style: const TextStyle(fontSize: 14, color: C.grey)),
            ]),
          ),
        ),
      const SizedBox(height: 20),
    ]);
  }

  // ------------------------------ tombol bawah ------------------------------
  Widget _bottom() => Container(
        color: C.bg,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: Listenable.merge([AppState.library, AppState.readingLists]),
            builder: (_, __) {
              final started = AppState.lastRead.containsKey(s.title);
              return Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _read,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30)),
                      child: Text(started ? 'Lanjutkan membaca' : 'Mulai membaca',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => showAddToSheet(context, s),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4)),
                    child: const Icon(Icons.add, size: 30),
                  ),
                ),
              ]);
            },
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        _topBar(),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            _header(),
            const SizedBox(height: 18),
            _tabs(),
            if (_tab == 0) _summary() else _chapters(),
          ]),
        ),
        const Divider(height: 1, color: C.line),
        _bottom(),
      ]),
    );
  }
}
