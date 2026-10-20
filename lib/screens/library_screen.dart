import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'liked_lists_screen.dart';
import 'list_screen.dart';
import 'profile_extras.dart';
import 'settings_pages.dart';
import 'story_screen.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback onFind;
  const LibraryScreen({super.key, required this.onFind});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0;
  bool _grid = true; // tampilan kotak (default) atau daftar
  int _sort = 0; // indeks di _sortLabels
  bool _edit = false; // mode edit (pilih beberapa cerita)
  final Set<String> _picked = {};

  static const _sortLabels = [
    'Baru saja dibaca',
    'Baru saja diperbarui',
    'Baru ditambahkan',
    'Judul cerita',
    'Penulis',
  ];

  List<Story> _sorted(List<Story> src) {
    final l = [...src];
    final none = DateTime(2000);
    int added(Story s) => AppState.addedOrder[s.title] ?? 0;
    switch (_sort) {
      case 0:
        l.sort((a, b) {
          final c = (AppState.lastRead[b.title] ?? none)
              .compareTo(AppState.lastRead[a.title] ?? none);
          return c != 0 ? c : added(b).compareTo(added(a));
        });
        break;
      case 1:
        l.sort((a, b) =>
            AppState.updatedOf(b).compareTo(AppState.updatedOf(a)));
        break;
      case 2:
        l.sort((a, b) => added(b).compareTo(added(a)));
        break;
      case 3:
        l.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      default:
        l.sort((a, b) =>
            a.author.toLowerCase().compareTo(b.author.toLowerCase()));
    }
    return l;
  }

  void _openSort() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 10),
            child: Row(children: [
              const Expanded(
                  child: Text('Urutkan berdasarkan',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          for (var i = 0; i < _sortLabels.length; i++)
            InkWell(
              onTap: () {
                setState(() => _sort = i);
                Navigator.pop(ctx);
              },
              child: SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(
                        child: Text(_sortLabels[i],
                            style: const TextStyle(fontSize: 18))),
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: i == _sort ? C.orange : Colors.white,
                              width: 2)),
                      child: i == _sort
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                  color: C.orange, shape: BoxShape.circle))
                          : null,
                    ),
                  ]),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _storyMenu(Story s) {
    final off = AppState.offline.value.contains(s.title);
    showIosSheet(
        context,
        [off ? 'Hapus unduhan' : 'Unduh untuk offline', 'Arsipkan', 'Hapus dari Perpustakaan'],
        (v) {
      if (v == 'Arsipkan') {
        AppState.archiveStory(s);
      } else if (v == 'Hapus dari Perpustakaan') {
        AppState.removeFromLibrary(s);
      } else {
        AppState.toggleOffline(s);
      }
    });
  }

  void _tapStory(Story s) {
    if (_edit) {
      setState(() => _picked.contains(s.title)
          ? _picked.remove(s.title)
          : _picked.add(s.title));
      return;
    }
    AppState.markRead(s);
    openStory(context, s);
  }

  void _applyPicked(bool archive) {
    final list = AppState.library.value.where((s) => _picked.contains(s.title)).toList();
    for (final s in list) {
      archive ? AppState.archiveStory(s) : AppState.removeFromLibrary(s);
    }
    setState(() {
      _picked.clear();
      _edit = false;
    });
  }

  String _status(Story s) {
    var h = 0;
    for (final c in s.title.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h % 3 == 0
        ? 'Lengkap'
        : 'Terakhir diperbarui: ${fmtDate(AppState.updatedOf(s))}';
  }

  Widget _progress(Story s, {bool menu = false}) {
    final off = AppState.offline.value.contains(s.title);
    final p = AppState.progressOf(s);
    return Row(children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(children: [
            Container(height: 3, color: const Color(0xFF3A3A3A)),
            FractionallySizedBox(
                widthFactor: p,
                child: Container(height: 3, color: C.orange)),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () => AppState.toggleOffline(s),
        child: Icon(
            off ? Icons.cloud_done_outlined : Icons.cloud_outlined,
            size: 26,
            color: Colors.white),
      ),
      if (menu) ...[
        const SizedBox(width: 10),
        GestureDetector(
            onTap: () => _storyMenu(s),
            child: const Icon(Icons.more_horiz, size: 26)),
      ],
    ]);
  }

  Widget _check(bool on) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? C.orange : const Color(0x99000000),
            border: Border.all(color: Colors.white, width: 1.8)),
        child: on ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      );

  /// Satu sel di tampilan kotak (3 kolom).
  Widget _gridCell(Story s, double w, {required bool withProgress}) {
    final on = _picked.contains(s.title);
    return SizedBox(
      width: w,
      child: GestureDetector(
        onTap: () => _tapStory(s),
        onLongPress: _edit ? null : () => _storyMenu(s),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            BookCover(s, w: w, h: w * 1.56),
            if (_edit)
              Positioned(top: 6, right: 6, child: _check(on)),
          ]),
          if (withProgress) ...[
            const SizedBox(height: 8),
            _progress(s),
            const SizedBox(height: 6),
            Text(s.title.replaceAll('\n', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14)),
          ],
        ]),
      ),
    );
  }

  Widget _gridOf(List<Story> list, {required bool withProgress}) =>
      LayoutBuilder(builder: (ctx, c) {
        const gap = 12.0;
        final w = (c.maxWidth - gap * 2) / 3;
        return Wrap(spacing: gap, runSpacing: 14, children: [
          for (final s in list) _gridCell(s, w, withProgress: withProgress),
        ]);
      });

  Widget _listOf(List<Story> list) => Column(children: [
        for (final s in list)
          InkWell(
            onTap: () => _tapStory(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_edit)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 50),
                    child: _check(_picked.contains(s.title)),
                  ),
                BookCover(s, w: 82, h: 127),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 127,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.title.replaceAll('\n', ' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(s.author,
                          style: const TextStyle(color: C.grey, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(_status(s),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: C.grey, fontSize: 15)),
                      const Spacer(),
                      _progress(s, menu: !_edit),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
      ]);

  Widget _sectionTitle(String l, [String? r]) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 12),
        child: Row(children: [
          Text(l, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (r != null)
            Text(r, style: const TextStyle(color: C.grey, fontSize: 16)),
        ]),
      );

  Widget _promo() => GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Akses offline tanpa batas belum tersedia di versi demo'))),
        child: Container(
          height: 45,
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
              color: const Color(0xFFD8CCF6),
              borderRadius: BorderRadius.circular(24)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.bolt, size: 22, color: Color(0xFF5B4B86)),
            SizedBox(width: 10),
            Text('Dapatkan akses cerita offline tanpa batas',
                style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
          ]),
        ),
      );

  Widget _currentReading(List<Story> lib) {
    final sorted = _sorted(lib);
    final off = AppState.offline.value;
    final offList = sorted.where((s) => off.contains(s.title)).toList();
    final rest = sorted.where((s) => !off.contains(s.title)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 24), children: [
      const SizedBox(height: 14),
      Row(children: [
        Text('${lib.length} cerita',
            style: const TextStyle(color: C.grey, fontSize: 16)),
        const Spacer(),
        GestureDetector(
          onTap: _openSort,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF232325),
                borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.swap_vert, size: 18),
              const SizedBox(width: 6),
              Text(_sortLabels[_sort],
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => setState(() => _grid = !_grid),
          child: Icon(_grid ? Icons.grid_view_outlined : Icons.view_list_outlined,
              size: 30),
        ),
      ]),
      if (offList.isNotEmpty) ...[
        _sectionTitle('Tersedia Offline', '${offList.length} dari ${lib.length} cerita'),
        _listOf(offList),
        _promo(),
      ],
      _sectionTitle('Cerita yang Disimpan'),
      if (rest.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Semua ceritamu tersedia offline.',
              style: TextStyle(color: C.grey, fontSize: 15)),
        )
      else
        _grid ? _gridOf(rest, withProgress: true) : _listOf(rest),
    ]);
  }

  void _help() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const FaqScreen()));

  Widget _empty() {
    if (_tab == 1) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 60),
          child: Text(
              'Hemat ruang simpan di perangkatmu dengan mengarsipkan cerita yang telah kamu baca',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, height: 1.3)),
        ),
      );
    }
    return Column(children: [
      const Spacer(flex: 3),
      const Text(
        'Kamu tidak memiliki cerita\ndi Perpustakaan',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25),
      ),
      const SizedBox(height: 22),
      GestureDetector(
        onTap: widget.onFind,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10)),
          child: const Text('Temukan Cerita Sekarang',
              style: TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ),
      ),
      const Spacer(flex: 4),
    ]);
  }

  Widget _listTile(Widget thumb, String title, Widget meta, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            thumb,
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 8),
                meta,
              ]),
            ),
          ]),
        ),
      );

  Widget _meta(String t, IconData i) => Row(children: [
        Text(t, style: const TextStyle(color: C.grey, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
                color: Color(0xFF555555), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Icon(i, size: 22, color: C.grey),
      ]);

  Widget _readingLists(List<Story> lib) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
      const SizedBox(height: 20),
      _listTile(
        Container(
          width: 115,
          height: 115,
          decoration: BoxDecoration(
              color: const Color(0xFF7A4636),
              borderRadius: BorderRadius.circular(5)),
          child: const Icon(Icons.favorite, color: C.orange, size: 30),
        ),
        'Liked reading lists',
        _meta('${AppState.likedLists.value.length} daftar', Icons.lock_outline),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LikedListsScreen())),
      ),
      const SizedBox(height: 10),
      for (final l in AppState.readingLists.value) ...[
        _listTile(
          WCollage(size: 115, stories: l.stories),
          AppState.listName(l),
          _meta('${l.stories.length} cerita',
              l.isPublic ? Icons.public : Icons.lock_outline),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      StoryListScreen(AppState.listName(l), l.stories,
                          isPublic: l.isPublic))),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }

  void _plus() => showIosSheet(context,
          const ['Buat daftar bacaan', 'Edit daftar bacaan'], (v) {
        if (v == 'Buat daftar bacaan') {
          createReadingList(context);
        } else {
          showEditReadingLists(context);
        }
      });

  void _pencil() => showIosSheet(
      context,
      const ['Kelola Arsip', 'Tampilkan sebagai Daftar', 'Urutkan berdasarkan'],
      (v) {
        if (v == 'Tampilkan sebagai Daftar') {
          setState(() => _grid = false);
        } else if (v == 'Urutkan berdasarkan') {
          _openSort();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"$v" belum tersedia di versi demo')));
        }
      });

  Widget _body() {
    final lib = AppState.library.value;
    final arc = AppState.archive.value;

    if (_tab == 2) return _readingLists(lib);

    final items = _tab == 0 ? lib : arc;
    if (items.isEmpty) return _empty();
    if (_tab == 0) return _currentReading(lib);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final s = items[i];
        return StoryRow(
          s,
          trailing: _tab == 0
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: C.grey),
                  color: C.surface,
                  onSelected: (v) {
                    if (v == 'arsip') {
                      AppState.archiveStory(s);
                    } else {
                      AppState.removeFromLibrary(s);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'arsip', child: Text('Arsipkan')),
                    PopupMenuItem(
                        value: 'hapus', child: Text('Hapus dari Perpustakaan')),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.unarchive_outlined, color: C.grey),
                  tooltip: 'Kembalikan',
                  onPressed: () => AppState.restoreStory(s)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: 28,
            child: Row(children: [
              const Text('Perpustakaan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_edit)
                GestureDetector(
                  onTap: () => setState(() {
                    _edit = false;
                    _picked.clear();
                  }),
                  child: const Text('Selesai',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                )
              else ...[
                GestureDetector(
                  onTap: _help,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.question_mark, size: 14),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _tab == 2
                      ? _plus
                      : (_tab == 0
                          ? () => setState(() => _edit = true)
                          : _pencil),
                  child: Icon(_tab == 2 ? Icons.add : Icons.edit_outlined,
                      size: 26),
                ),
              ],
            ]),
          ),
        ),
        const Divider(height: 1, color: Color(0xFF2E2E2E)),
        const SizedBox(height: 14),
        Segmented(
          labels: const ['Bacaan Saat Ini', 'Arsip', 'Daftar Bacaan'],
          index: _tab,
          height: 26,
          fontSize: 14,
          onChanged: (i) => setState(() {
            _tab = i;
            _edit = false;
            _picked.clear();
          }),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFF2E2E2E)),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([
              AppState.library,
              AppState.archive,
              AppState.offline,
              AppState.readingLists,
              AppState.likedLists,
              AppState.progressTick
            ]),
            builder: (_, __) => _body(),
          ),
        ),
        if (_edit)
          Container(
            decoration: const BoxDecoration(
                color: C.bg,
                border: Border(top: BorderSide(color: Color(0xFF2A2A2A)))),
            height: 52,
            child: Row(children: [
              Expanded(
                child: TextButton(
                    onPressed: _picked.isEmpty ? null : () => _applyPicked(true),
                    child: Text('Arsipkan (${_picked.length})',
                        style: TextStyle(
                            fontSize: 17,
                            color: _picked.isEmpty
                                ? const Color(0xFF4A4A4C)
                                : Colors.white))),
              ),
              Expanded(
                child: TextButton(
                    onPressed: _picked.isEmpty ? null : () => _applyPicked(false),
                    child: Text('Hapus',
                        style: TextStyle(
                            fontSize: 17,
                            color: _picked.isEmpty
                                ? const Color(0xFF4A4A4C)
                                : C.red))),
              ),
            ]),
          ),
      ]),
    );
  }
}
