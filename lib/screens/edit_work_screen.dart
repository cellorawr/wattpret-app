import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'media_picker.dart';
import 'new_story_screen.dart';
import 'story_screen.dart' show openStory;
import 'story_pages.dart';
import 'works_screen.dart';

/// "Edit Cerita" untuk karya yang sudah ada: sampul, judul, deskripsi, bahasa,
/// jenis cerita, tag, hak cipta, Dewasa, Lengkap, lalu "Daftar isi" (bab) dan
/// tombol "Tambahkan Bab" - seperti di aplikasi Wattpret asli.
class EditWorkScreen extends StatefulWidget {
  final Work work;
  const EditWorkScreen({super.key, required this.work});
  @override
  State<EditWorkScreen> createState() => _EditWorkScreenState();
}

class _EditWorkScreenState extends State<EditWorkScreen> {
  Work get w => widget.work;
  bool _dirty = false;
  bool _menu = false;

  static const _langs = [
    'English',
    'Bahasa Indonesia',
    'Español',
    'Français',
    'Deutsch',
    'Português'
  ];
  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<T?> _go<T>(Widget page) => Navigator.of(context, rootNavigator: true)
      .push<T>(MaterialPageRoute(builder: (_) => page));

  void _touch(VoidCallback f) => setState(() {
        f();
        _dirty = true;
      });

  Future<void> _pickCover() async {
    final r = await pickImages(context,
        cover: true,
        onRemove: w.cover == null ? null : () => _touch(() => w.cover = null));
    if (r.isEmpty || !mounted) return;
    _touch(() => w.cover = r.first);
    AppState.notifyWorks();
  }

  Future<void> _title() async {
    final r = await _go<String>(
        TextEntryPage(title: 'Judul', initial: w.title, hint: 'Judul Cerita'));
    if (r != null) _touch(() => w.title = r);
  }

  Future<void> _desc() async {
    final r = await _go<String>(TextEntryPage(
        title: 'Deskripsi',
        initial: w.synopsis,
        hint: 'Tambahkan deskripsi pada ceritamu',
        multi: true));
    if (r != null) _touch(() => w.synopsis = r);
  }

  Future<void> _lang() async {
    final r = await _go<String>(OptionPage(
        title: 'Bahasa Cerita', options: _langs, selected: w.lang, bold: false));
    if (r != null && r.isNotEmpty) _touch(() => w.lang = r);
  }

  Future<void> _unpublish() async {
    setState(() => _menu = false);
    final ok = await showIosConfirm(context,
        title: 'Batalkan publikasi?',
        message:
            'Cerita ini tidak akan lagi terlihat oleh pembaca. Kamu bisa memublikasikannya lagi kapan saja.',
        cancel: 'Batal',
        ok: 'Ya');
    if (!ok || !mounted) return;
    w.published = false;
    for (final p in w.parts) {
      p.published = false;
    }
    AppState.saveWork(w);
    setState(() {});
    _snack('Publikasi dibatalkan');
  }

  Future<void> _deleteStory() async {
    setState(() => _menu = false);
    final done = await confirmDeleteWork(context, w);
    if (done && mounted) Navigator.of(context).pop();
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            SizedBox(width: 30, child: Icon(icon, size: 26)),
            const SizedBox(width: 18),
            Text(label, style: const TextStyle(fontSize: 20)),
          ]),
        ),
      );

  void _save() {
    if (!_dirty) return;
    AppState.saveWork(w);
    setState(() => _dirty = false);
    _snack('Perubahan disimpan');
  }

  Future<void> _addPart() async {
    final p = Part(title: '');
    await _go<void>(ChapterEditorScreen(
        storyTitle: w.title, synopsis: w.synopsis, work: w, part: p));
    if (mounted) setState(() {});
  }

  Future<void> _openPart(Part p) async {
    await _go<void>(ChapterEditorScreen(
        storyTitle: w.title, synopsis: w.synopsis, work: w, part: p));
    if (mounted) setState(() {});
  }

  // ------------------------------ potongan UI ------------------------------
  Widget _switch(bool v, ValueChanged<bool> f) => Transform.scale(
        scale: 0.85,
        child: Switch(
          value: v,
          onChanged: f,
          activeColor: Colors.white,
          activeTrackColor: C.orange,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF2C2C2E),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      );

  Widget _draft() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4A4A4A), width: 1.5),
            borderRadius: BorderRadius.circular(6)),
        child: const Text('Draf',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: Colors.black,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
            icon: const Icon(Icons.close, size: 30),
            onPressed: () => Navigator.of(context).pop()),
        title: const Text('Edit Cerita',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        actions: [
          Center(
            child: GestureDetector(
              onTap: _save,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: _dirty ? Colors.white : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('Simpan',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _dirty ? Colors.black : const Color(0xFF6A6A6A))),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.add, size: 30), onPressed: _addPart),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 26),
            onPressed: () => setState(() => _menu = !_menu),
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.only(bottom: 120), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: GestureDetector(
              onTap: _pickCover,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                child: Row(children: [
                  Container(
                    width: 90,
                    height: 140,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4)),
                    child: w.cover == null
                        ? const Icon(Icons.add_circle_outline,
                            color: Color(0xFF6E6E6E), size: 30)
                        : Image.memory(w.cover!, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 24),
                  Text(w.cover == null ? 'Tambahkan sampul' : 'Ganti sampul',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2E2E2E)),
          StoryFormRow('Judul', _title,
              required: true, value: storyFormValue(w.title)),
          StoryFormRow('Deskripsi', _desc,
              required: true,
              below: w.synopsis.trim().isEmpty
                  ? null
                  : Text(w.synopsis.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF9A9A9A)))),
          StoryFormRow('Bahasa Cerita', _lang, value: storyFormValue(w.lang)),
          StoryTypeFields(work: w, onChanged: () => _touch(() {})),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Dewasa', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                      w.mature
                          ? 'Ceritamu ditandai untuk pembaca dewasa.'
                          : 'Cerita kamu sesuai untuk semua audiens. Komunitas Wattpret dapat memberi rating Dewasa pada ceritamu. Untuk informasi lebih lanjut, lihat Pedoman Konten di bagian Pengaturan.',
                      style: const TextStyle(
                          fontSize: 16, height: 1.35, color: Color(0xFF9A9A9A))),
                ]),
              ),
              const SizedBox(width: 8),
              _switch(w.mature, (v) => _touch(() => w.mature = v)),
            ]),
          ),
          const Divider(height: 1, indent: 16, color: Color(0xFF2E2E2E)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(children: [
              const Expanded(child: Text('Lengkap', style: TextStyle(fontSize: 18))),
              _switch(w.complete, (v) => _touch(() => w.complete = v)),
            ]),
          ),
          Container(height: 40, color: const Color(0xFF1B1B1B)),
          Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
            child: Row(children: [
              const Expanded(
                  child: Text('Daftar isi',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 28),
                onPressed: () async {
                  await _go<void>(StoryPartsScreen(work: w));
                  if (mounted) setState(() {});
                },
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFF2E2E2E)),
          for (final p in w.parts) ...[
            InkWell(
              onTap: () => _openPart(p),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.title.isEmpty ? 'Tanpa judul' : p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(children: [
                        if (!p.published) ...[
                          _draft(),
                          const SizedBox(width: 10),
                          Text(timeAgo(p.updated),
                              style: const TextStyle(fontSize: 17)),
                        ] else ...[
                          MiniStat(Icons.remove_red_eye_outlined, '${p.reads}'),
                          const SizedBox(width: 12),
                          MiniStat(Icons.star_border, '${p.votes}'),
                          const SizedBox(width: 12),
                          MiniStat(Icons.chat_bubble_outline, '${p.comments}'),
                        ],
                      ]),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, size: 28, color: Color(0xFFBDBDBD)),
                ]),
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2E2E2E)),
          ],
        ]),
        Positioned(
          left: 0,
          right: 0,
          bottom: 22,
          child: Center(
            child: GestureDetector(
              onTap: _addPart,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, color: Colors.black, size: 28),
                  SizedBox(width: 14),
                  Text('Tambahkan\nBab',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          height: 1.1)),
                ]),
              ),
            ),
          ),
        ),
        if (_menu) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _menu = false),
              child: Container(color: const Color(0xDB000000)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                  color: Color(0xFF1C1C1E),
                  border: Border(bottom: BorderSide(color: Color(0xFF3A3A3C)))),
              child: Column(children: [
                _menuItem(Icons.login, 'Impor', () {
                  setState(() => _menu = false);
                  _snack('Impor belum tersedia di versi demo');
                }),
                const Divider(height: 1, color: Color(0xFF2E2E30)),
                if (w.published) ...[
                  _menuItem(Icons.insert_drive_file_outlined,
                      'Batalkan publikasi', _unpublish),
                  const Divider(height: 1, color: Color(0xFF2E2E30)),
                ],
                _menuItem(Icons.visibility, 'Lihat sebagai Pembaca', () {
                  setState(() => _menu = false);
                  openStory(context, w.toStory());
                }),
                const Divider(height: 1, color: Color(0xFF2E2E30)),
                _menuItem(Icons.ios_share, 'Bagikan', () {
                  setState(() => _menu = false);
                  _snack('Tautan cerita disalin');
                }),
                const Divider(height: 1, color: Color(0xFF2E2E30)),
                _menuItem(Icons.delete_outline, 'Hapus Cerita', _deleteStory),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}
