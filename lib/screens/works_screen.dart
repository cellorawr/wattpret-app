import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'new_story_screen.dart';
import 'publish_screens.dart';
import 'edit_work_screen.dart';

// ===========================================================================
// Hapus cerita: peringatan -> konfirmasi dengan mengetik nama pengguna.
// ===========================================================================
Future<bool> confirmDeleteWork(BuildContext context, Work w) async {
  final ok = await showIosConfirm(
    context,
    title: 'Hapus cerita?',
    message:
        'Semua jumlah telah dibaca, vote, dan komentar akan dihapus dari cerita yang sudah dipublikasikan. Tindakan ini tidak dapat dibatalkan.',
    cancel: 'Batal',
    ok: 'Ya',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;

  final c = TextEditingController();
  final done = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final match = c.text.trim() == AppState.username;
      return Dialog(
        backgroundColor: C.sheet,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Konfirmasi penghapusan',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                'Untuk menghapus "${w.title}", masukkan nama pengguna kamu (${AppState.username}).',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.35)),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              autofocus: true,
              onChanged: (_) => setS(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Nama pengguna',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF5E5E5E))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: C.orange)),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal',
                        style: TextStyle(color: C.iosBlue, fontSize: 17))),
              ),
              Expanded(
                child: TextButton(
                    onPressed: match ? () => Navigator.pop(ctx, true) : null,
                    child: Text('Hapus',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: match ? C.red : const Color(0xFF6A6A6A)))),
              ),
            ]),
          ]),
        ),
      );
    }),
  );
  c.dispose();
  if (done == true) {
    AppState.deleteWork(w);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cerita dihapus')));
    }
    return true;
  }
  return false;
}

// ===========================================================================
// "Dikerjakan oleh ..." - daftar karya (draf & terpublikasi)
// ===========================================================================
class WorksScreen extends StatelessWidget {
  final String title;
  const WorksScreen({super.key, this.title = 'Cerita'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: wAppBar(context, title: title, actions: [
        IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const NewStoryScreen()))),
      ]),
      body: ValueListenableBuilder<List<Work>>(
        valueListenable: AppState.works,
        builder: (ctx, list, _) {
          if (list.isEmpty) {
            return const Center(
                child: Text('Belum ada cerita atau draf',
                    style: TextStyle(color: C.grey, fontSize: 16)));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 6, 20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (_, i) => _WorkRow(list[i]),
          );
        },
      ),
    );
  }
}

class _WorkRow extends StatelessWidget {
  final Work w;
  const _WorkRow(this.w);

  @override
  Widget build(BuildContext context) {
    final drafts = w.draftCount;
    return InkWell(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => EditWorkScreen(work: w))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookCover(w.toStory(), w: 64, h: 100),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (w.published) ...[
                Row(children: [
                  MiniStat(Icons.remove_red_eye_outlined, '${w.reads}'),
                  const SizedBox(width: 14),
                  MiniStat(Icons.star_border, '${w.votes}'),
                  const SizedBox(width: 14),
                  MiniStat(Icons.chat_bubble_outline, '${w.comments}'),
                ]),
                const SizedBox(height: 6),
                Text(
                    drafts > 0
                        ? 'Terpublikasi • $drafts draf'
                        : 'Terpublikasi',
                    style: const TextStyle(color: C.grey, fontSize: 14)),
              ] else ...[
                Row(children: [
                  _DraftBadge(),
                  const SizedBox(width: 8),
                  Text(fmtShort(w.updated),
                      style: const TextStyle(color: C.grey, fontSize: 14)),
                ]),
              ],
            ]),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: C.grey),
            color: C.surface,
            onSelected: (v) {
              if (v == 'hapus') confirmDeleteWork(context, w);
              if (v == 'buka') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => StoryPartsScreen(work: w)));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'buka', child: Text('Kelola bab')),
              PopupMenuItem(value: 'hapus', child: Text('Hapus cerita')),
            ],
          ),
        ]),
      ),
    );
  }
}

class _DraftBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4A4A4A), width: 1.5),
            borderRadius: BorderRadius.circular(5)),
        child: const Text('Draf',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.1)),
      );
}

// ===========================================================================
// "Pilih Salah Satu" - daftar bab satu cerita (draf / terpublikasi)
// ===========================================================================
class StoryPartsScreen extends StatefulWidget {
  final Work work;
  const StoryPartsScreen({super.key, required this.work});
  @override
  State<StoryPartsScreen> createState() => _StoryPartsScreenState();
}

class _StoryPartsScreenState extends State<StoryPartsScreen> {
  final Set<Part> _sel = {};
  Work get w => widget.work;

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _delete() async {
    if (_sel.isEmpty) return;
    final ok = await showIosConfirm(context,
        title: 'Hapus bab?',
        message: w.parts.any((p) => _sel.contains(p) && p.published)
            ? 'Jumlah bacaan, vote, dan komentar bab yang sudah terbit akan ikut terhapus.'
            : 'Draf yang dipilih akan dihapus.',
        ok: 'Hapus',
        destructive: true);
    if (!ok) return;
    w.parts.removeWhere(_sel.contains);
    _sel.clear();
    if (w.parts.isEmpty) {
      AppState.deleteWork(w);
      if (mounted) Navigator.pop(context);
      return;
    }
    AppState.saveWork(w);
    setState(() {});
  }

  Future<void> _publish() async {
    final drafts = _sel.where((p) => !p.published).toList();
    if (drafts.isEmpty) {
      _snack('Pilih bab berstatus draf');
      return;
    }
    if (!w.published) {
      // Cerita belum terbit: lengkapi info cerita dulu.
      final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
          MaterialPageRoute(builder: (_) => EditStoryScreen(work: w)));
      if (ok != true || !mounted) return;
    }
    final words = drafts.fold<int>(
        0,
        (a, p) =>
            a + (p.body.trim().isEmpty ? 0 : p.body.trim().split(RegExp(r'\s+')).length));
    final go = await showPublishConfirm(context, words);
    if (go != true || !mounted) return;
    _sel.clear();
    await finishPublish(context, w, drafts);
    if (mounted) setState(() {});
  }

  void _open(Part p) {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(
            builder: (_) => ChapterEditorScreen(
                storyTitle: w.title, synopsis: w.synopsis, work: w, part: p)))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final has = _sel.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 52,
            child: Stack(alignment: Alignment.center, children: [
              const Text('Pilih Salah Satu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Selesai',
                        style: TextStyle(color: Colors.white, fontSize: 17))),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFF3A3A3C)),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: w.parts.length,
              onReorder: (a, b) {
                setState(() {
                  if (b > a) b -= 1;
                  final p = w.parts.removeAt(a);
                  w.parts.insert(b, p);
                });
                AppState.saveWork(w);
              },
              itemBuilder: (_, i) {
                final p = w.parts[i];
                final on = _sel.contains(p);
                return Container(
                  key: ObjectKey(p),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Color(0xFF2E2E30)))),
                  child: Row(children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => on ? _sel.remove(p) : _sel.add(p)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: on ? C.orange : Colors.transparent,
                              border: Border.all(
                                  color: on ? C.orange : const Color(0xFF6A6A6C),
                                  width: 1.8)),
                          child: on
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _open(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title.isEmpty ? 'Tanpa judul' : p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Row(children: [
                                  if (p.published) ...[
                                    MiniStat(Icons.remove_red_eye_outlined,
                                        '${p.reads}'),
                                    const SizedBox(width: 12),
                                    MiniStat(Icons.star_border, '${p.votes}'),
                                    const SizedBox(width: 12),
                                    MiniStat(Icons.chat_bubble_outline,
                                        '${p.comments}'),
                                  ] else ...[
                                    _DraftBadge(),
                                    const SizedBox(width: 8),
                                    Text(timeAgo(p.updated),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                  ],
                                ]),
                              ]),
                        ),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Icon(Icons.drag_handle, color: Color(0xFF8A8A8C)),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF3A3A3C)))),
            height: 52,
            child: Row(children: [
              Expanded(
                child: TextButton(
                    onPressed: has ? _delete : null,
                    style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: Text('Hapus',
                        style: TextStyle(
                            fontSize: 18,
                            color: has ? C.red : const Color(0xFF4A4A4C)))),
              ),
              Expanded(
                child: TextButton(
                    onPressed: has ? _publish : null,
                    style: TextButton.styleFrom(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: Text('Publikasikan',
                        style: TextStyle(
                            fontSize: 18,
                            color: has ? Colors.white : const Color(0xFF4A4A4C)))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
