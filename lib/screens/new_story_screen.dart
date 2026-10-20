import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'media_picker.dart';
import 'part_screens.dart';
import 'youtube_search_screen.dart';
import 'publish_screens.dart';
import 'story_pages.dart';

/// Langkah 1: "Tambahkan Informasi Cerita" (sampul, judul, deskripsi).
class NewStoryScreen extends StatefulWidget {
  const NewStoryScreen({super.key});
  @override
  State<NewStoryScreen> createState() => _NewStoryScreenState();
}

class _NewStoryScreenState extends State<NewStoryScreen> {
  final _title = TextEditingController();
  final _syn = TextEditingController();
  Uint8List? _cover;

  @override
  void dispose() {
    _title.dispose();
    _syn.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final r = await pickImages(context,
        cover: true,
        onRemove: _cover == null ? null : () => setState(() => _cover = null));
    if (r.isNotEmpty && mounted) setState(() => _cover = r.first);
  }

  void _next() {
    Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(
        builder: (_) => ChapterEditorScreen(
            storyTitle: _title.text.trim(),
            synopsis: _syn.text.trim(),
            cover: _cover)));
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Color(0xFFA0A0A0), fontSize: 18, fontWeight: FontWeight.w700),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      );

  @override
  Widget build(BuildContext context) {
    final filled = _title.text.trim().isNotEmpty;
    const line = Divider(height: 1, indent: 16, color: Color(0xFF2E2E2E));
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close, size: 30),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop()),
        title: const Text('Tambahkan Informasi Cerita',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _next,
            child: Text(filled ? 'Lanjut' : 'Lewati',
                style: TextStyle(
                    fontSize: 16,
                    color: filled ? Colors.white : const Color(0xFF9A9A9A))),
          ),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFF2E2E2E))),
      ),
      body: ListView(padding: EdgeInsets.zero, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: GestureDetector(
            onTap: _pickCover,
            child: Row(children: [
              Container(
                width: 62,
                height: 97,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(5)),
                child: _cover == null
                    ? const Icon(Icons.add_circle_outline,
                        color: Color(0xFF6E6E6E), size: 24)
                    : Image.memory(_cover!, fit: BoxFit.cover),
              ),
              const SizedBox(width: 20),
              Text(_cover == null ? 'Tambahkan sampul' : 'Ganti sampul',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        line,
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            decoration: _dec('Judul Cerita'),
          ),
        ),
        line,
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: TextField(
            controller: _syn,
            minLines: 1,
            maxLines: 6,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: _dec('Tambahkan deskripsi pada ceritamu'),
          ),
        ),
      ]),
    );
  }
}

/// Langkah 2: editor bab ("Part 1").
/// Menu dropdown pada judul bab: Simpan sebagai konsep, Pratinjau, Riwayat Revisi.
class ChapterEditorScreen extends StatefulWidget {
  final String storyTitle, synopsis;

  /// Sampul yang dipilih di langkah 1 (Tambahkan Informasi Cerita).
  final Uint8List? cover;

  /// Diisi jika membuka kembali bab yang sudah ada (draf / terpublikasi).
  final Work? work;
  final Part? part;
  const ChapterEditorScreen(
      {super.key,
      this.storyTitle = '',
      this.synopsis = '',
      this.cover,
      this.work,
      this.part});
  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen> {
  late final _chTitle = TextEditingController(text: widget.part?.title ?? '');
  late final _body = TextEditingController(text: widget.part?.body ?? '');
  late final Part _part = widget.part ?? Part(title: '');
  final _undo = UndoHistoryController();
  final _bodyFocus = FocusNode();
  final _titleFocus = FocusNode();
  Work? _work;
  Uint8List? _cover;
  bool _poll = false;
  bool _menu = false;

  // Pemformatan teks (toolbar di atas keyboard)
  bool _fmtOpen = false, _bold = false, _italic = false, _underline = false;
  TextAlign _align = TextAlign.left;

  @override
  void initState() {
    super.initState();
    _work = widget.work;
    _cover = widget.work?.cover ?? widget.cover;
  }

  @override
  void dispose() {
    _chTitle.dispose();
    _body.dispose();
    _undo.dispose();
    _bodyFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      _chTitle.text.trim().isNotEmpty ||
      _body.text.trim().isNotEmpty ||
      _part.images.isNotEmpty ||
      _part.videos.isNotEmpty;

  int get _wordCount {
    final t = _body.text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  String get _partLabel {
    final w = _work;
    if (w == null) return 'Part 1';
    final i = w.parts.indexOf(_part);
    return 'Part ${(i < 0 ? w.parts.length + 1 : i + 1)}';
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _syncPart() {
    _part.title = _chTitle.text.trim();
    _part.body = _body.text.trim();
  }

  /// Membuat/mengambil Work untuk bab ini dan memasukkan bab ke dalamnya.
  Work _ensureWork() {
    final t = widget.storyTitle.isNotEmpty
        ? widget.storyTitle
        : (_chTitle.text.trim().isNotEmpty ? _chTitle.text.trim() : 'Tanpa judul');
    final w = _work ??= Work(title: t, synopsis: widget.synopsis, cover: _cover);
    w.cover = _cover;
    if (!w.parts.contains(_part)) w.parts.add(_part);
    return w;
  }

  void _saveDraft() {
    setState(() => _menu = false);
    if (!_canPublish) {
      _snack('Tulis judul atau isi bab dulu');
      return;
    }
    _syncPart();
    final w = _ensureWork();
    _part.touch();
    AppState.saveWork(w);
    _snack('Disimpan sebagai konsep');
  }

  void _preview() {
    setState(() => _menu = false);
    _syncPart();
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => PartPreviewScreen(
            storyTitle: _work?.title ?? widget.storyTitle,
            title: _part.title,
            body: _part.body,
            images: _part.images,
            videos: _part.videos)));
  }

  void _history() {
    setState(() => _menu = false);
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => RevisionHistoryScreen(
            partTitle: _part.title, revisions: _part.revisions)));
  }

  void _back() {
    // Seperti aplikasi asli: tulisan otomatis tersimpan sebagai draf.
    if (_canPublish) {
      _syncPart();
      final w = _ensureWork();
      _part.touch();
      AppState.saveWork(w);
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _publish() async {
    setState(() => _menu = false);
    FocusScope.of(context).unfocus();
    if (!_canPublish) {
      _snack('Tulis judul atau isi bab dulu');
      return;
    }
    _syncPart();
    final w = _ensureWork();
    if (!w.published) {
      // Cerita belum terbit: lengkapi "Edit Cerita" dulu, lalu konfirmasi.
      final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
          MaterialPageRoute(builder: (_) => EditStoryScreen(work: w)));
      if (ok != true || !mounted) return;
    }
    final go = await showPublishConfirm(context, _wordCount);
    if (go != true || !mounted) return;
    await finishPublish(context, w, [_part]);
  }

  // ------------------------------ potongan UI ------------------------------
  /// Ikon gambar dan video sama-sama memasukkan gambar ke dalam bab.
  Future<void> _addImages() async {
    final r = await pickImages(context, multi: true);
    if (r.isEmpty || !mounted) return;
    setState(() => _part.images.addAll(r));
  }

  /// Ikon video membuka halaman "Telusuri YouTube"; video yang dipilih
  /// disisipkan sebagai kartu video di dalam bab.
  Future<void> _addVideo() async {
    final url = await openYoutubeSearch(context);
    if (url == null || !mounted) return;
    setState(() => _part.videos.add(url));
  }

  Widget _videoBlock(int i) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: YoutubeCard(_part.videos[i],
            onRemove: () => setState(() => _part.videos.removeAt(i))),
      );

  /// Ganti / hapus sampul lewat tombol pensil di banner.
  Future<void> _pickBannerCover() async {
    final r = await pickImages(context,
        cover: true,
        onRemove: _cover == null
            ? null
            : () {
                setState(() => _cover = null);
                _work?.cover = null;
                AppState.notifyWorks();
              });
    if (r.isEmpty || !mounted) return;
    setState(() => _cover = r.first);
    _work?.cover = r.first;
    AppState.notifyWorks();
  }

  Widget _imageBlock(int i) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(_part.images[i],
                width: double.infinity, fit: BoxFit.fitWidth),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _part.images.removeAt(i)),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                    color: Color(0xCC000000), shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 20, color: Colors.white),
              ),
            ),
          ),
        ]),
      );

  Widget _mediaButton(IconData i) => Expanded(
        child: InkWell(
          onTap: i == Icons.videocam ? _addVideo : _addImages,
          child: SizedBox(
              height: 66,
              child: Icon(i, size: 34, color: const Color(0xFFDADADA))),
        ),
      );

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            Icon(icon, size: 24),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 20)),
          ]),
        ),
      );

  /// Banner sampul cerita (muncul setelah cerita dibuat), dengan tombol pensil.
  Widget _coverBanner() => Container(
        height: 150,
        width: double.infinity,
        color: const Color(0xFF6A6A6A),
        child: Stack(alignment: Alignment.center, children: [
          if (_cover == null)
            const WLogo(size: 130)
          else
            Positioned.fill(child: Image.memory(_cover!, fit: BoxFit.cover)),
          Positioned(
            right: 14,
            bottom: 12,
            child: GestureDetector(
              onTap: _pickBannerCover,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: Color(0xFFB9B9B9), shape: BoxShape.circle),
                child: const Icon(Icons.edit_outlined,
                    size: 22, color: Color(0xFF1E1E1E)),
              ),
            ),
          ),
        ]),
      );

  // Toolbar oranye di atas keyboard (undo, redo, format, gambar, video, tutup).
  Widget _formatIcon(Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
        Text('A',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: c,
                height: 1,
                fontFamily: 'Georgia')),
        const SizedBox(width: 2),
        Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Container(
                width: 9,
                height: 2,
                margin: const EdgeInsets.symmetric(vertical: 1.5),
                color: c),
        ]),
      ]);

  Widget _tbBtn(Widget child, VoidCallback? onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: SizedBox(height: 44, child: Center(child: child)),
        ),
      );

  Widget _toolbar() {
    const o = C.orange;
    const dim = Color(0xFF7A7A7C);
    return ValueListenableBuilder<UndoHistoryValue>(
      valueListenable: _undo,
      builder: (_, v, __) => Container(
        color: const Color(0xFF3A3A3C),
        child: Row(children: [
          _tbBtn(Icon(Icons.undo, size: 28, color: v.canUndo ? o : dim),
              v.canUndo ? _undo.undo : null),
          _tbBtn(Icon(Icons.redo, size: 28, color: v.canRedo ? o : dim),
              v.canRedo ? _undo.redo : null),
          _tbBtn(_formatIcon(_fmtOpen ? Colors.white : o),
              () => setState(() => _fmtOpen = !_fmtOpen)),
          _tbBtn(const Icon(Icons.image, size: 30, color: o), _addImages),
          _tbBtn(const Icon(Icons.videocam, size: 32, color: o), _addVideo),
          _tbBtn(const Icon(Icons.keyboard_hide_outlined, size: 28, color: dim),
              () => FocusScope.of(context).unfocus()),
        ]),
      ),
    );
  }

  Widget _fmtBtn(IconData i, bool on, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          width: 36,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
              color: on ? C.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(5)),
          child: Icon(i, size: 22, color: Colors.white),
        ),
      );

  Widget _fmtPopup() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _fmtBtn(Icons.format_bold, _bold, () => setState(() => _bold = !_bold)),
            _fmtBtn(Icons.format_italic, _italic,
                () => setState(() => _italic = !_italic)),
            _fmtBtn(Icons.format_underlined, _underline,
                () => setState(() => _underline = !_underline)),
            const SizedBox(width: 6),
            _fmtBtn(Icons.format_align_left, _align == TextAlign.left,
                () => setState(() => _align = TextAlign.left)),
            _fmtBtn(Icons.format_align_center, _align == TextAlign.center,
                () => setState(() => _align = TextAlign.center)),
            _fmtBtn(Icons.format_align_right, _align == TextAlign.right,
                () => setState(() => _align = TextAlign.right)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 134),
          child: Transform.translate(
              offset: const Offset(0, -4),
              child: const Icon(Icons.arrow_drop_down,
                  size: 26, color: Color(0xFF3A3A3C))),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final dim = _menu ? const Color(0xFF6E6E6E) : Colors.white;
    final kb = MediaQuery.of(context).viewInsets.bottom > 0;
    final bodyStyle = kSerif.copyWith(
        fontSize: 17,
        height: 1.5,
        fontWeight: _bold ? FontWeight.w800 : FontWeight.w400,
        fontStyle: _italic ? FontStyle.italic : FontStyle.normal,
        decoration: _underline ? TextDecoration.underline : TextDecoration.none);
    return Scaffold(
      appBar: wAppBar(
        context,
        onLeading: _back,
        titleWidget: GestureDetector(
          onTap: () => setState(() => _menu = !_menu),
          behavior: HitTestBehavior.opaque,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_partLabel,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: dim)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, size: 24, color: dim),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: _publish,
            child: Text('Publikasikan',
                style: TextStyle(
                    fontSize: 16,
                    color: (_canPublish && !_menu)
                        ? Colors.white
                        : const Color(0xFF6E6E6E))),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            ListView(padding: EdgeInsets.zero, children: [
              if (_work != null) _coverBanner(),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 26, bottom: 34),
                  width: 258,
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF262626)),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    _mediaButton(Icons.image),
                    Container(width: 1, height: 66, color: const Color(0xFF262626)),
                    _mediaButton(Icons.videocam),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _chTitle,
                  focusNode: _titleFocus,
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.center,
                  style: kSerif,
                  decoration: InputDecoration(
                    hintText: 'Judul bab',
                    hintStyle: kSerif.copyWith(color: const Color(0xFF3B3B3B)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: Color(0xFFCFCFCF)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: TextField(
                  controller: _body,
                  focusNode: _bodyFocus,
                  undoController: _undo,
                  onChanged: (_) => setState(() {}),
                  minLines: 4,
                  maxLines: null,
                  textAlign: _align,
                  style: bodyStyle,
                  decoration: InputDecoration(
                    hintText: 'Mulai tulis ceritamu',
                    hintStyle: kSerif.copyWith(
                        fontSize: 17, color: const Color(0xFF3B3B3B)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              for (var i = 0; i < _part.images.length; i++) _imageBlock(i),
              for (var i = 0; i < _part.videos.length; i++) _videoBlock(i),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 60),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => setState(() => _poll = !_poll),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: _poll ? C.orange : Colors.white, width: 1.2),
                          borderRadius: BorderRadius.circular(30)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.playlist_add,
                            size: 22, color: _poll ? C.orange : Colors.white),
                        const SizedBox(width: 6),
                        Text(_poll ? 'Polling ditambahkan' : 'Tambahkan polling',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: _poll ? C.orange : Colors.white)),
                      ]),
                    ),
                  ),
                ),
              ),
            ]),
            // Jumlah kata di pojok kanan bawah.
            Positioned(
              right: 16,
              bottom: 8,
              child: Text('$_wordCount kata',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9A9A9A))),
            ),
            if (kb && _fmtOpen)
              Positioned(left: 10, bottom: 18, child: _fmtPopup()),
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
                    _menuItem(Icons.save_alt, 'Simpan sebagai konsep', _saveDraft),
                    const Divider(height: 1, color: Color(0xFF2E2E30)),
                    _menuItem(Icons.visibility, 'Pratinjau', _preview),
                    const Divider(height: 1, color: Color(0xFF2E2E30)),
                    _menuItem(Icons.history, 'Riwayat Revisi', _history),
                  ]),
                ),
              ),
            ],
          ]),
        ),
        if (kb) _toolbar(),
      ]),
    );
  }
}

/// Langkah 3: "Edit Cerita" - muncul setelah menekan Publikasikan pertama kali.
/// "Simpan & Terbitkan" memeriksa isian lalu kembali ke editor bab untuk
/// konfirmasi publikasi.
class EditStoryScreen extends StatefulWidget {
  final Work work;
  const EditStoryScreen({super.key, required this.work});
  @override
  State<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends State<EditStoryScreen> {
  Work get w => widget.work;

  static const _langs = [
    'English',
    'Bahasa Indonesia',
    'Español',
    'Français',
    'Deutsch',
    'Português'
  ];

  bool get _isFan => w.type == 'Fiksi Penggemar';
  bool get _isFiction => w.type == 'Fiksi';

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<T?> _go<T>(Widget page) =>
      Navigator.of(context, rootNavigator: true)
          .push<T>(MaterialPageRoute(builder: (_) => page));

  Future<void> _editTitle() async {
    final r = await _go<String>(TextEntryPage(
        title: 'Judul', initial: w.title, hint: 'Judul Cerita'));
    if (r != null) setState(() => w.title = r);
  }

  Future<void> _editDesc() async {
    final r = await _go<String>(TextEntryPage(
        title: 'Deskripsi',
        initial: w.synopsis,
        hint: 'Tambahkan deskripsi pada ceritamu',
        multi: true));
    if (r != null) setState(() => w.synopsis = r);
  }

  Future<void> _editLang() async {
    final r = await _go<String>(OptionPage(
        title: 'Bahasa Cerita',
        options: _langs,
        selected: w.lang,
        bold: false));
    if (r != null && r.isNotEmpty) setState(() => w.lang = r);
  }

  void _publish() {
    final missing = <String>[];
    if (w.title.trim().isEmpty) missing.add('Judul');
    if (w.synopsis.trim().isEmpty) missing.add('Deskripsi');
    if (w.type.isEmpty) missing.add('Jenis cerita');
    if (_isFan && w.fandoms.isEmpty) missing.add('Fandom #1');
    if (_isFiction && w.genres.isEmpty) missing.add('Genre #1');
    if (w.tags.isEmpty) missing.add('Tag');
    if (missing.isNotEmpty) {
      _snack('Lengkapi dulu: ${missing.join(', ')}');
      return;
    }
    AppState.saveWork(w);
    Navigator.of(context, rootNavigator: true).pop(true);
  }

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

  Future<void> _pickCover() async {
    final r = await pickImages(context,
        cover: true,
        onRemove: w.cover == null
            ? null
            : () {
                setState(() => w.cover = null);
                AppState.notifyWorks();
              });
    if (r.isEmpty || !mounted) return;
    setState(() => w.cover = r.first);
    AppState.notifyWorks();
  }

  Widget _cover() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: GestureDetector(
          onTap: _pickCover,
          child: Row(children: [
            Container(
              width: 46,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(4)),
              child: w.cover == null
                  ? const Icon(Icons.add_circle_outline,
                      color: Color(0xFF6E6E6E), size: 22)
                  : Image.memory(w.cover!, fit: BoxFit.cover),
            ),
            const SizedBox(width: 20),
            Text(w.cover == null ? 'Tambahkan sampul' : 'Ganti sampul',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: wAppBar(
        context,
        title: 'Edit Cerita',
        leading: Icons.close,
        centerTitle: false,
        actions: [
          // Tombol kecil bergaya pil (tinggi 30), bukan setinggi AppBar.
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: _publish,
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Text('Simpan & Terbitkan',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(padding: EdgeInsets.zero, children: [
        _cover(),
        const Divider(height: 1, color: Color(0xFF2E2E2E)),
        StoryFormRow('Judul', _editTitle,
            required: true, value: storyFormValue(w.title)),
        StoryFormRow('Deskripsi', _editDesc,
            required: true,
            below: w.synopsis.trim().isEmpty
                ? null
                : Text(w.synopsis.replaceAll('\n', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF9A9A9A)))),
        StoryFormRow('Bahasa Cerita', _editLang, value: storyFormValue(w.lang)),
        StoryTypeFields(work: w, onChanged: () => setState(() {})),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
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
            _switch(w.mature, (v) => setState(() => w.mature = v)),
          ]),
        ),
        const Divider(height: 1, indent: 16, color: Color(0xFF2E2E2E)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(children: [
            const Expanded(child: Text('Lengkap', style: TextStyle(fontSize: 18))),
            _switch(w.complete, (v) => setState(() => w.complete = v)),
          ]),
        ),
        const Divider(height: 1, indent: 16, color: Color(0xFF2E2E2E)),
        const SizedBox(height: 30),
      ]),
    );
  }
}
