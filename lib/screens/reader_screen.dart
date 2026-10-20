import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'settings_pages.dart' show PremiumScreen;

/// Pembaca bab ala aplikasi Wattpret asli (mode gulir / halaman, tema halaman,
/// komentar per paragraf, kartu penulis, catatan penulis, bar Vote/Bagikan).
class ReaderScreen extends StatefulWidget {
  final Story story;
  final int chapter;
  const ReaderScreen(this.story, {super.key, this.chapter = -1});
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with TickerProviderStateMixin {
  late int _ch; // bab yang sedang terlihat
  late int _start; // bab pertama yang dimuat di daftar gulir
  int _loaded = 1; // jumlah bab yang sudah dimuat berurutan
  final Map<int, GlobalKey> _keys = {};
  final GlobalKey _viewKey = GlobalKey();
  static final Map<String, List<_Cmt>> _store = {};
  GlobalKey _chKey(int c) => _keys.putIfAbsent(c, () => GlobalKey());
  bool _aa = false;
  bool _toastGone = false;
  bool _allowPop = false;
  bool _moved = false; // progres baru disimpan setelah pembaca benar-benar bergerak
  double _resumeFrac = 0;
  final _scroll = ScrollController();
  final _pageCtl = PageController();
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  int _pageCount = 1;
  Timer? _timer;
  ReaderPrefs get _p => AppState.reader;
  Story get s => widget.story;

  @override
  void initState() {
    super.initState();
    final max = s.parts < 1 ? 0 : s.parts - 1;
    if (widget.chapter < 0) {
      // lanjutkan dari posisi terakhir dibaca
      final x = AppState.progressOf(s) * (s.parts < 1 ? 1 : s.parts);
      _ch = x.floor().clamp(0, max).toInt();
      _resumeFrac = (x - _ch).clamp(0.0, 1.0).toDouble();
    } else {
      _ch = widget.chapter > max ? max : widget.chapter;
    }
    ServerCache.tick.addListener(_onServer);
    _p.addListener(_syncTimer);
    _start = _ch;
    _p.addListener(_onPrefs);
    _scroll.addListener(_onScroll);
    _pageCtl.addListener(() {
      _moved = true;
      _updateProgress();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppState.markRead(s);
      _syncTimer();
      _resume();
      _updateProgress();
    });
  }

  void _onServer() {
    if (mounted) setState(() {});
  }

  /// Paragraf isi bab dari server. null = pakai teks contoh lokal,
  /// daftar kosong = masih memuat.
  List<String>? _serverParas(int ch) {
    final id = s.id;
    if (id == null) return null;
    final chs = ServerCache.chapters[id];
    if (chs == null || ch < 0 || ch >= chs.length) return null;
    final cid = chs[ch].id;
    if (ServerCache.failed.contains(cid)) return null;
    final body = ServerCache.bodies[cid];
    if (body == null) {
      ServerCache.loadBody(cid);
      return const [];
    }
    var parts = body.split(RegExp(r'\n\s*\n'));
    if (parts.length == 1) parts = body.split('\n');
    final out = parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return out.isEmpty ? const ['(Bab ini belum ada isinya.)'] : out;
  }

  @override
  void dispose() {
    ServerCache.tick.removeListener(_onServer);
    _p.removeListener(_syncTimer);
    _p.removeListener(_onPrefs);
    _timer?.cancel();
    _scroll.dispose();
    _pageCtl.dispose();
    _progress.dispose();
    _anim.dispose();
    _animPrev.dispose();
    _wheelTimer?.cancel();
    super.dispose();
  }

  // ------------------------ indikator progres baca ------------------------
  /// Posisi (relatif ke atas area baca) dan tinggi sebuah bab yang sedang terbangun.
  ({double top, double h})? _metrics(int c) {
    final ctx = _keys[c]?.currentContext;
    final vctx = _viewKey.currentContext;
    if (ctx == null || vctx == null) return null;
    final rb = ctx.findRenderObject();
    final vb = vctx.findRenderObject();
    if (rb is! RenderBox || vb is! RenderBox) return null;
    if (!rb.attached || !vb.attached || !rb.hasSize) return null;
    final top = rb.localToGlobal(Offset.zero, ancestor: vb).dy;
    return (top: top, h: rb.size.height);
  }

  double get _viewH {
    final vctx = _viewKey.currentContext;
    final sz = vctx?.size;
    return sz?.height ?? 0;
  }

  double get _viewW {
    final vctx = _viewKey.currentContext;
    final sz = vctx?.size;
    return sz?.width ?? 0;
  }

  /// Panjang sumbu perpindahan bab: tinggi (mode gulir) / lebar (mode halaman).
  double get _len => _p.scrollMode ? _viewH : _viewW;

  /// Menghitung bab yang sedang dibaca dan seberapa jauh di dalam bab itu (0..1),
  /// lalu menyimpan progres seluruh cerita untuk indikator di Perpustakaan.
  void _updateProgress() {
    if (!mounted) return;
    var cur = _ch;
    double frac = 0;
    if (_p.scrollMode) {
      if (!_scroll.hasClients) return;
      final vh = _viewH;
      var seen = false;
      cur = _start;
      for (var c = _start; c < _start + _loaded; c++) {
        final m = _metrics(c);
        if (m == null) {
          if (!seen) {
            cur = c;
            frac = 1;
            continue;
          }
          break;
        }
        seen = true;
        if (m.top <= vh * 0.4) {
          cur = c;
          final range = m.h - vh;
          frac = range <= 0 ? 1 : (-m.top / range).clamp(0.0, 1.0).toDouble();
        } else {
          break;
        }
      }
      if (cur != _ch) {
        setState(() => _ch = cur);
        AppState.markRead(s);
      }
    } else if (_pageCtl.hasClients && _pageCount > 1) {
      frac = ((_pageCtl.page ?? 0) / (_pageCount - 1)).clamp(0.0, 1.0).toDouble();
    }
    if (frac != _progress.value) _progress.value = frac;
    final parts = s.parts < 1 ? 1 : s.parts;
    if (_moved) AppState.setProgress(s, (cur + frac) / parts);
  }

  void _resume() {
    if (_resumeFrac <= 0) return;
    if (_p.scrollMode) {
      final m = _metrics(_ch);
      if (m == null || !_scroll.hasClients) return;
      final range = m.h - _viewH;
      if (range <= 0) return;
      final pos = _scroll.position;
      _scroll.jumpTo((pos.pixels + m.top + _resumeFrac * range)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent)
          .toDouble());
    } else if (_pageCtl.hasClients && _pageCount > 1) {
      _pageCtl.jumpToPage((_resumeFrac * (_pageCount - 1)).round());
    }
  }

  void _onScroll() {
    _moved = true;
    if (!_p.scrollMode || !_scroll.hasClients) return;
    _updateProgress();
  }

  void _onPrefs() {
    if (!_p.scrollMode && (_loaded > 1 || _start != _ch)) {
      _start = _ch;
      _loaded = 1;
    }
    _resetProgressSoon();
  }

  void _resetProgressSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateProgress());
  }

  /// Geser indikator untuk melompat ke bagian lain bab yang sedang dibaca.
  void _seek(double f) {
    _moved = true;
    f = f.clamp(0.0, 1.0).toDouble();
    if (_p.scrollMode) {
      if (!_scroll.hasClients) return;
      final m = _metrics(_ch);
      if (m == null) return;
      final range = m.h - _viewH;
      if (range <= 0) return;
      final pos = _scroll.position;
      final target = pos.pixels + m.top + f * range;
      _scroll.jumpTo(
          target.clamp(pos.minScrollExtent, pos.maxScrollExtent).toDouble());
    } else if (_pageCtl.hasClients && _pageCount > 1) {
      _pageCtl.jumpToPage((f * (_pageCount - 1)).round());
    }
    _updateProgress();
  }

  Widget _progressBar() {
    const thumb = 16.0;
    return Container(
      color: _barBg,
      height: 20,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        double fromDx(double dx) =>
            ((dx - thumb / 2) / (w - thumb)).clamp(0.0, 1.0).toDouble();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _seek(fromDx(d.localPosition.dx)),
          onHorizontalDragUpdate: (d) => _seek(fromDx(d.localPosition.dx)),
          child: ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, v, __) {
              final x = v * (w - thumb) + thumb / 2;
              return Stack(clipBehavior: Clip.none, children: [
                // jalur abu-abu (belum dibaca)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 9,
                  child: Container(
                      height: 3,
                      color: _dark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFD0D0D0)),
                ),
                // bagian yang sudah dibaca (berwarna)
                Positioned(
                  left: 0,
                  top: 9,
                  child: Container(width: x, height: 3, color: C.orange),
                ),
                Positioned(
                  left: x - thumb / 2,
                  top: 2,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: C.orange, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 3)
                        ]),
                  ),
                ),
              ]);
            },
          ),
        );
      }),
    );
  }

  // ---------------------- keluar dari pembaca ----------------------
  /// Jika cerita belum ada di perpustakaan, tanyakan dulu (Ya / Tidak / Batal).
  void _leave() {
    if (_allowPop || AppState.inLibrary(s)) {
      Navigator.of(context).pop();
      return;
    }
    showIosSheet(context, const ['Ya', 'Tidak'], (v) {
      if (!mounted) return;
      if (v == 'Ya') AppState.addToLibrary(s);
      _allowPop = true;
      Navigator.of(context).pop();
    }, title: 'Tambahkan ke perpustakaan?');
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (_p.autoScroll && _p.scrollMode) {
      _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
        if (!_scroll.hasClients) return;
        final pos = _scroll.position;
        final next = pos.pixels + 0.4 + _p.speed * 2.6;
        if (next >= pos.maxScrollExtent) {
          _scroll.jumpTo(pos.maxScrollExtent);
        } else {
          _scroll.jumpTo(next);
        }
      });
    }
  }

  // ----------------------------- tema -----------------------------
  int get _theme => _p.followApp ? 1 : _p.pageTheme;
  bool get _dark => _theme == 1;
  Color get _bg => const [Colors.white, C.bg, C.sepia][_theme];
  Color get _fg =>
      const [Color(0xFF1B1B1B), Colors.white, Color(0xFF2B2417)][_theme];
  Color get _muted => _dark ? const Color(0xFF8A8A8A) : const Color(0xFF7A7A7A);
  Color get _barBg => _dark ? C.bg : const Color(0xFFF4F4F4);

  TextStyle _style({bool bold = false, double? size, bool italic = false}) =>
      TextStyle(
        fontFamily: _p.fontName,
        fontFamilyFallback: const ['Times New Roman', 'serif'],
        fontSize: size ?? _p.fontSize,
        height: 1.55,
        color: _fg,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  // ----------------------------- data -----------------------------
  List<String> get _titles => chapterTitles(s);
  String _chapterName(int ch) {
    final t = _titles[ch < _titles.length ? ch : 0];
    final m = RegExp(r'^\[(\d+)\]\.\s*(.*)$').firstMatch(t);
    if (m == null) return t;
    return '${m.group(1)!.padLeft(2, '0')}. ${m.group(2)}';
  }

  /// Judul header: hanya nomor & judul bab, mis. "[2]. Who Is She?".
  String _rawTitle(int ch) => _titles[ch < _titles.length ? ch : 0];
  String get _appBarTitle => _rawTitle(_ch);

  int _cnt(int ch, int i) =>
      ((s.title.length * 31 + ch * 17 + i * 13) % 19) + 1;
  int _totalFor(int ch) => 120 + (s.title.length * 37 + ch * 19) % 880;

  // ------------------------------ komentar ------------------------------
  static const _names = [
    'angkaganteng', 'vinnnncf', 'moonsaurus_', 'ketikmalam', 'kirana_w', 'raflisetia'
  ];
  static const _texts = [
    'Gemes banget bagian ini 😭',
    'Lanjut thor, penasaran parah!!',
    'Aku sampe baca ulang 3x wkwk',
    'Ini relate banget sama aku',
    'Plot twist-nya nggak kebayang 😱',
    'Suka banget gaya tulisanmu kak ✨',
    'Hahaha ngakak di sini',
    'Tolong jangan digantung ya 🥹',
  ];

  // ------------------- komentar dari server -------------------
  final Map<int, Map<String, int>> _cc = {};
  final Set<int> _ccBusy = {};

  static String _paraOf(String ck) => ck.substring(ck.indexOf(':') + 1);

  /// id bab di server untuk kunci komentar [ck] ("<indeks bab>:<paragraf>").
  /// null = cerita contoh lokal (komentar contoh dipakai).
  int? _srvCid(String ck) {
    final id = s.id;
    if (id == null) return null;
    final chs = ServerCache.chapters[id];
    final ch = int.tryParse(ck.split(':').first);
    if (chs == null || ch == null || ch < 0 || ch >= chs.length) return null;
    return chs[ch].id;
  }

  Future<void> _loadCounts(int cid) async {
    if (_cc.containsKey(cid) || !_ccBusy.add(cid)) return;
    try {
      _cc[cid] = await Api.commentCounts(cid);
    } catch (_) {
      _cc[cid] = {};
    } finally {
      _ccBusy.remove(cid);
      if (mounted) setState(() {});
    }
  }

  int _srvCount(int cid, String para) {
    _loadCounts(cid);
    return _cc[cid]?[para] ?? 0;
  }

  int _commentTotal(int ch) {
    final cid = _srvCid('$ch:all');
    if (cid == null) return _totalFor(ch) + _added('$ch:all').length;
    _loadCounts(cid);
    return (_cc[cid] ?? const <String, int>{}).values.fold(0, (a, b) => a + b);
  }

  void _bumpCount(int cid, String para, int d) {
    final m = _cc.putIfAbsent(cid, () => {});
    m[para] = (m[para] ?? 0) + d;
  }

  _Cmt _cmtFromJson(Map<String, dynamic> j) {
    final u = j['user'];
    return _Cmt(
        u is Map ? (u['username'] ?? '').toString() : '',
        (j['body'] ?? '').toString(),
        DateTime.tryParse('${j['created_at']}')?.toLocal() ?? DateTime.now(),
        id: int.tryParse('${j['id']}'));
  }

  String _ckey(String ck) => '${s.title}|$ck';
  List<_Cmt> _added(String ck) => _store[_ckey(ck)] ?? const [];

  /// Komentar contoh yang tetap per paragraf (maks. 20 ditampilkan).
  List<_Cmt> _seed(String ck, int n) {
    final h = ck.codeUnits.fold<int>(s.title.length, (a, b) => (a * 31 + b) & 0xffff);
    final shown = n > 20 ? 20 : n;
    return [
      for (var i = 0; i < shown; i++)
        _Cmt(_names[(h + i) % _names.length], _texts[(h + i * 3) % _texts.length],
            DateTime.now().subtract(Duration(hours: 3 + i * 7 + h % 5))),
    ];
  }

  /// Layar komentar penuh (per paragraf bila [quote] diisi, selain itu per bab).
  void _openComments(String ck, int seedCount, {String? quote}) {
    final ctrl = TextEditingController();
    final liked = <String>{};
    final ch = _ch;
    final cid = _srvCid(ck);
    final para = _paraOf(ck);
    var srvList = <_Cmt>[];
    var srvLoading = cid != null;
    var closed = false;
    StateSetter? pageSet;
    if (cid != null) {
      Api.comments(cid, paragraph: para)
          .then((list) {
            srvList = [for (final j in list) _cmtFromJson(j)];
          })
          .catchError((_) {})
          .whenComplete(() {
            srvLoading = false;
            if (!closed) pageSet?.call(() {});
          });
    }
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setPage) {
        pageSet = setPage;
        final added = cid != null ? <_Cmt>[] : _added(ck).reversed.toList();
        final seeds = cid != null ? <_Cmt>[] : _seed(ck, seedCount);
        final entries = <(_Cmt, String)>[
          for (final c in srvList) (c, 'c${c.id}'),
          for (final a in added) (a, 'a${a.date.microsecondsSinceEpoch}'),
          for (var i = 0; i < seeds.length; i++) (seeds[i], 's$i'),
        ];

        Future<void> send() async {
          final txt = ctrl.text.trim();
          if (txt.isEmpty) return;
          if (cid != null) {
            try {
              final r = await Api.addComment(cid, txt, paragraph: para);
              ctrl.clear();
              if (ctx.mounted) FocusScope.of(ctx).unfocus();
              srvList.insert(0, _Cmt(AppState.username, txt, DateTime.now(),
                  id: int.tryParse('${r['id']}')));
              _bumpCount(cid, para, 1);
              if (!closed) setPage(() {});
              if (mounted) setState(() {});
            } on ApiException catch (e) {
              _snack(e.message);
            } catch (_) {
              _snack('Komentar gagal dikirim. Periksa koneksi ke server.');
            }
            return;
          }
          _store.putIfAbsent(_ckey(ck), () => []).add(
              _Cmt(AppState.username, txt, DateTime.now()));
          ctrl.clear();
          FocusScope.of(ctx).unfocus();
          setPage(() {});
          if (mounted) setState(() {});
        }

        void append(String t) {
          ctrl.text = ctrl.text + t;
          ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        }

        Widget sticker(Widget child, String insert) => GestureDetector(
              onTap: () => append(insert),
              child: Container(
                width: 42,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFF0E0E0E),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFF3A3A3C))),
                child: child,
              ),
            );

        Widget row((_Cmt, String) e) {
          final c = e.$1;
          final isLiked = liked.contains(e.$2);
          final seedIdx =
              e.$2.startsWith('s') ? int.tryParse(e.$2.substring(1)) ?? 0 : 0;
          final likes = (seedIdx % 5 == 3 ? 1 : 0) + (isLiked ? 1 : 0);
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              c.author == AppState.username
                  ? const Avatar(size: 32)
                  : LetterAvatar(c.author, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.author,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(c.text, style: const TextStyle(fontSize: 17, height: 1.25)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(timeAgo(c.date),
                        style: const TextStyle(fontSize: 14, color: C.grey)),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        ctrl.text = '@${c.author} ';
                        ctrl.selection =
                            TextSelection.collapsed(offset: ctrl.text.length);
                      },
                      child: const Text('Balas',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: C.premium)),
                    ),
                  ]),
                ]),
              ),
              GestureDetector(
                onTap: () => setPage(() {
                  isLiked ? liked.remove(e.$2) : liked.add(e.$2);
                }),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 26, color: isLiked ? C.red : Colors.white),
                    if (likes > 0)
                      Text('$likes', style: const TextStyle(fontSize: 14)),
                  ]),
                ),
              ),
            ]),
          );
        }

        const line = Color(0xFF2A2A2A);
        return Scaffold(
          backgroundColor: C.bg,
          resizeToAvoidBottomInset: true,
          body: Column(children: [
            Container(
              color: C.bg,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 62,
                  child: Row(children: [
                    IconButton(
                        icon: const Icon(Icons.close, size: 30),
                        onPressed: () => Navigator.pop(ctx)),
                    Expanded(
                        child: Text(_rawTitle(ch),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700))),
                    IconButton(
                        icon: const Icon(Icons.ios_share, size: 28),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: quote ?? _rawTitle(ch)));
                          _snack('Disalin');
                        }),
                  ]),
                ),
              ),
            ),
            const Divider(height: 1, color: line),
            Expanded(
              child: ListView(padding: EdgeInsets.zero, children: [
                if (quote != null)
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        color: Color(0xFF1B1B1B),
                        border: Border(bottom: BorderSide(color: line))),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Text(quote,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, height: 1.3, color: Color(0xFFE6E6E6))),
                  ),
                Container(
                  color: const Color(0xFF1B1B1B),
                  padding: EdgeInsets.fromLTRB(
                      12, quote != null ? 20 : 15, 12, quote != null ? 18 : 20),
                  child: Column(children: [
                    if (quote != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 0, bottom: 20),
                      child: SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            sticker(
                                const Icon(Icons.add_reaction_outlined, size: 26),
                                '😊'),
                            sticker(const Text('🐷', style: TextStyle(fontSize: 24)),
                                '🐷'),
                            sticker(
                                const Text("I CAN'T",
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFFFB020))),
                                "I can't"),
                            sticker(const Text('🐨', style: TextStyle(fontSize: 24)),
                                '🐨'),
                            sticker(const Text('🐸', style: TextStyle(fontSize: 24)),
                                '🐸'),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.only(left: 22, right: 6),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF3A3A3C))),
                      child: Row(children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            onSubmitted: (_) => send(),
                            textInputAction: TextInputAction.send,
                            style: const TextStyle(fontSize: 17),
                            decoration: const InputDecoration(
                                hintText: 'Tulis komentar...',
                                hintStyle:
                                    TextStyle(color: C.grey, fontSize: 17),
                                border: InputBorder.none,
                                isCollapsed: true),
                          ),
                        ),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: ctrl,
                          builder: (_, v, __) {
                            final on = v.text.trim().isNotEmpty;
                            return GestureDetector(
                              onTap: send,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: on
                                        ? C.premium
                                        : const Color(0xFF3A3A55)),
                                child: Icon(Icons.send_outlined,
                                    size: 20,
                                    color: on
                                        ? Colors.black
                                        : const Color(0xFF8A8AA8)),
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                  ]),
                ),
                Container(
                  color: Colors.black,
                  child: Column(children: [
                    const SizedBox(height: 10),
                    Row(children: const [
                      SizedBox(width: 32),
                      Expanded(child: Divider(color: Color(0xFF444444), height: 1)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 66),
                          child: Text('Iklan',
                              style: TextStyle(
                                  color: Color(0xFF7A7A7A), fontSize: 14))),
                      Expanded(child: Divider(color: Color(0xFF444444), height: 1)),
                      SizedBox(width: 32),
                    ]),
                    const SizedBox(height: 70),
                    if (entries.isEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Text(
                              srvLoading
                                  ? 'Memuat komentar...'
                                  : 'Belum ada komentar. Jadilah yang pertama!',
                              style: const TextStyle(color: C.grey, fontSize: 16)))
                    else
                      for (final e in entries) row(e),
                    const SizedBox(height: 14),
                    Row(children: const [
                      SizedBox(width: 32),
                      Expanded(child: Divider(color: Color(0xFF444444), height: 1)),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 66),
                          child: Text('Iklan',
                              style: TextStyle(
                                  color: Color(0xFF7A7A7A), fontSize: 14))),
                      Expanded(child: Divider(color: Color(0xFF444444), height: 1)),
                      SizedBox(width: 32),
                    ]),
                    const SizedBox(height: 60),
                  ]),
                ),
              ]),
            ),
          ]),
        );
      }),
    )).then((_) => closed = true);
  }

  static const _paras = [
    'Pagi itu udara terasa lebih sejuk dari biasanya. Di halaman pertama '
        'kisah ini, semuanya masih tampak sederhana dan tenang, seolah tidak '
        'ada yang akan berubah.',
    'Namun seperti yang sering terjadi, hal-hal kecil diam-diam membawa '
        'perubahan besar. Sebuah percakapan singkat, sebuah tatapan, atau '
        'sepucuk pesan yang datang di waktu yang tidak terduga.',
    'Ia menarik napas dalam-dalam, lalu melangkah maju. Apa pun yang '
        'menunggu di depan sana, ia tahu bahwa perjalanan ini harus dimulai '
        'dari satu langkah kecil.',
    '"Kamu yakin mau lanjut?" tanya seseorang dari belakang. Ia menoleh, '
        'tersenyum tipis, lalu mengangguk pelan.',
    'Hari itu berakhir dengan langit jingga yang pelan-pelan berubah ungu. '
        'Dan untuk pertama kalinya, ia merasa semua ini baru permulaan.',
  ];

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _goTo(int i, {bool toEnd = false}) {
    setState(() {
      _ch = i;
      _start = i;
      _loaded = 1;
      _toastGone = false;
    });
    _moved = true;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (_pageCtl.hasClients) _pageCtl.jumpToPage(0);
    _progress.value = 0;
    AppState.markRead(s);
    _resetProgressSoon();
    if (toEnd) {
      // pindah ke bab sebelumnya: mulai dari ujung bab itu
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_p.scrollMode) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
            _updateProgress();
          }
        } else if (_pageCtl.hasClients) {
          _pageCtl.jumpToPage(_pageCount - 1);
          _updateProgress();
        }
      });
    }
  }

  // ------------- tarik di ujung bab -> halaman bab berikutnya naik dari bawah -------------
  // Seperti di aplikasi asli: di ujung bab layar berhenti, tombol "Lanjutkan
  // membaca" menempel di bawah. Terus tarik/gulir -> halaman bab berikutnya
  // naik dari bawah menutupi bab lama. Berlaku untuk sentuhan, drag mouse,
  // roda mouse, dan trackpad.
  // Kecepatan jari: dipakai supaya geser cepat (flick) -> pindah bab cepat,
  // geser pelan -> mengikuti jari dan selesai pelan, seperti di HP.
  VelocityTracker _vt = VelocityTracker.withKind(PointerDeviceKind.touch);
  double _lastVy = 0; // px/detik; negatif = jari bergerak ke atas
  double _lastVx = 0; // px/detik; negatif = jari bergerak ke kiri
  /// + = jari bergerak mundur (ke bawah / ke kanan) sesuai mode baca.
  double get _bwdVel => _p.scrollMode ? _lastVy : _lastVx;
  static const double _flingV = 500; // di atas ini dianggap flick

  void _ptrDown(PointerDownEvent e) {
    _vt = VelocityTracker.withKind(e.kind);
    _lastVy = 0;
    _lastVx = 0;
    _vt.addPosition(e.timeStamp, e.position);
  }

  void _ptrMove(PointerMoveEvent e) => _vt.addPosition(e.timeStamp, e.position);

  void _ptrUp(PointerUpEvent e) {
    _vt.addPosition(e.timeStamp, e.position);
    final v = _vt.getVelocity().pixelsPerSecond;
    _lastVy = v.dy;
    _lastVx = v.dx;
  }

  void _ptrCancel(PointerCancelEvent e) {
    _lastVy = 0;
    _lastVx = 0;
  }

  /// Lama animasi menyelesaikan/membatalkan panel: makin cepat jari, makin cepat.
  Duration _finishDur(double remainingPx, double speed) {
    final v = speed.abs() < 1400 ? 1400.0 : speed.abs();
    final ms = (remainingPx / v * 1000).round().clamp(110, 380).toInt();
    return Duration(milliseconds: ms);
  }

  static const double _pullNeeded = 70; // jarak tarik minimum (piksel), seperti aslinya: sedikit tarik saja cukup
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  double _pullPx = 0;
  Timer? _wheelTimer;
  bool _leaving = false;

  // ---- tarik ke bawah di awal bab -> bab sebelumnya turun dari atas ----
  late final AnimationController _animPrev = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  double _pullPrevPx = 0;
  bool _leavingPrev = false;
  bool get _hasPrev => _ch > 0;
  bool get _atTop =>
      _scroll.hasClients &&
      _scroll.position.pixels <= _scroll.position.minScrollExtent + 1;

  void _pullPrevBy(double dy, double vh) {
    if (!_hasPrev || _leavingPrev || vh <= 0) return;
    _pullPrevPx = (_pullPrevPx + dy).clamp(0.0, vh).toDouble();
    _animPrev.value = _pullPrevPx / vh;
  }

  void _releasePrev() {
    if (_pullPrevPx <= 0 || _leavingPrev) return;
    final down = _bwdVel; // + = jari bergerak mundur
    final vh = _len;
    if (down >= -_flingV && (_pullPrevPx >= _pullNeeded || down > _flingV)) {
      _leavingPrev = true;
      _animPrev
          .animateTo(1.0,
              duration: _finishDur(vh * (1 - _animPrev.value), down),
              curve: Curves.easeOut)
          .whenComplete(() {
        if (!mounted) return;
        _leavingPrev = false;
        _pullPrevPx = 0;
        _goTo(_ch - 1, toEnd: true);
        _animPrev.value = 0;
      });
    } else {
      _pullPrevPx = 0;
      _animPrev.animateTo(0,
          duration: _finishDur(vh * _animPrev.value, down),
          curve: Curves.easeOut);
    }
  }

  int get _total => _titles.length > s.parts ? _titles.length : s.parts;
  bool get _hasNext => _ch < _total - 1;
  bool get _atEnd =>
      _scroll.hasClients &&
      _scroll.position.pixels >= _scroll.position.maxScrollExtent - 1;

  void _pullBy(double dy, double vh) {
    if (!_hasNext || _leaving || vh <= 0) return;
    _pullPx = (_pullPx + dy).clamp(0.0, vh).toDouble();
    _anim.value = _pullPx / vh;
  }

  void _releasePull() {
    if (_pullPx <= 0 || _leaving) return;
    final up = -_bwdVel; // + = jari bergerak maju
    if (up >= -_flingV && (_pullPx >= _pullNeeded || up > _flingV)) {
      _completeNext(speed: up);
    } else {
      _pullPx = 0;
      _anim.animateTo(0,
          duration: _finishDur(_len * _anim.value, up),
          curve: Curves.easeOut);
    }
  }

  void _completeNext({double speed = 0}) {
    if (!_hasNext) {
      _snack('Ini bab terakhir yang tersedia');
      return;
    }
    if (_leaving) return;
    _leaving = true;
    _anim
        .animateTo(1.0,
            duration: _finishDur(_len * (1 - _anim.value), speed),
            curve: Curves.easeOut)
        .whenComplete(() {
      if (!mounted) return;
      _leaving = false;
      _pullPx = 0;
      _goTo(_ch + 1);
      _anim.value = 0;
    });
  }

  bool _onScrollNote(ScrollNotification n) {
    // Mode gulir memantau gulir vertikal, mode halaman memantau geser mendatar.
    final horiz = n.metrics.axis == Axis.horizontal;
    if (_p.scrollMode == horiz) return false;
    final vh = _len;
    if (n is OverscrollNotification) {
      // Sudah di ujung bab: panel bab berikutnya mengikuti jari 1:1.
      if (n.dragDetails != null && n.overscroll > 0) {
        _pullBy(n.overscroll, vh);
      }
      // Sudah di awal bab: tarik ke bawah -> bab sebelumnya turun dari atas.
      if (n.dragDetails != null && n.overscroll < 0) {
        _pullPrevBy(-n.overscroll, vh);
      }
    } else if (n is ScrollUpdateNotification) {
      if (n.dragDetails != null && _pullPrevPx > 0 && (n.scrollDelta ?? 0) > 0) {
        _pullPrevBy(-n.scrollDelta!, vh);
      }
      // Jari digeser balik ke bawah saat panel ditarik: panel turun dulu.
      if (n.dragDetails != null && _pullPx > 0 && (n.scrollDelta ?? 0) < 0) {
        _pullBy(n.scrollDelta!, vh);
      }
    } else if (n is ScrollEndNotification) {
      _releasePull();
      _releasePrev();
    }
    return false;
  }

  bool get _atFirstPage =>
      _pageCtl.hasClients && (_pageCtl.page ?? 0) <= 0.01;
  bool get _atLastPage =>
      _pageCtl.hasClients && (_pageCtl.page ?? 0) >= _pageCount - 1 - 0.01;

  void _onWheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final d = _p.scrollMode ? e.scrollDelta.dy : e.scrollDelta.dx;
    if (d == 0) return;
    final atStart = _p.scrollMode ? _atTop : _atFirstPage;
    final atEnd = _p.scrollMode ? _atEnd : _atLastPage;
    if (_hasPrev && !_leavingPrev && ((atStart && d < 0) || _pullPrevPx > 0)) {
      _pullPrevBy(-d, _len);
      _wheelTimer?.cancel();
      _wheelTimer = Timer(const Duration(milliseconds: 260), () {
        _lastVy = 0;
        _lastVx = 0;
        _releasePrev();
      });
      return;
    }
    if (!_hasNext || _leaving) return;
    if ((atEnd && d > 0) || _pullPx > 0) {
      _pullBy(d, _len);
      _wheelTimer?.cancel();
      _wheelTimer = Timer(const Duration(milliseconds: 260), () {
        _lastVy = 0;
        _lastVx = 0;
        _releasePull();
      });
    }
  }

  /// Mode halaman: halaman pertama/terakhir sebuah bab yang bergeser mendatar
  /// menutupi bab yang sedang dibaca (dari kanan = bab berikutnya,
  /// dari kiri = bab sebelumnya).
  Widget _slidePanel(int ch, double v, double w, double h,
      {required bool fromRight}) {
    final pages = _pagesFor(ch);
    final pg = fromRight ? pages.first : pages.last;
    final dx = (fromRight ? 1 : -1) * w * (1 - v);
    return Transform.translate(
      offset: Offset(dx, 0),
      child: SizedBox(
        width: w,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(color: _bg, boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 16)
          ]),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(children: pg),
            ),
          ),
        ),
      ),
    );
  }

  /// Halaman bab berikutnya yang naik dari bawah.
  Widget _nextPanel(double v, double vh) {
    const head = 64.0;
    return ClipRect(
      child: ColoredBox(
        color: _bg,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: vh,
          maxHeight: vh,
          child: Stack(children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, head * (1 - v)),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(children: _items(_ch + 1, vh: vh)),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: head,
              child: Opacity(
                opacity: (1 - v).clamp(0.0, 1.0).toDouble(),
                child: Container(
                  color: C.bg,
                  alignment: Alignment.center,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Lanjutkan membaca',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 22),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Bab sebelumnya yang turun dari atas (ujung bab itu menempel di tepi bawah).
  Widget _prevPanel(double v, double vh) {
    const head = 64.0;
    return ClipRect(
      child: ColoredBox(
        color: _bg,
        child: OverflowBox(
          alignment: Alignment.bottomCenter,
          minHeight: vh,
          maxHeight: vh,
          child: Stack(children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, -head * (1 - v)),
                child: SingleChildScrollView(
                  reverse: true,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(children: _items(_ch - 1, vh: vh)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: head,
              child: Opacity(
                opacity: (1 - v).clamp(0.0, 1.0).toDouble(),
                child: Container(
                  color: C.bg,
                  alignment: Alignment.center,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.keyboard_arrow_up,
                            color: Colors.white, size: 22),
                        Text('Bab sebelumnya',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // --------------------------- potongan UI ---------------------------
  Widget _pad(Widget w) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: w);

  Widget _bubble(int n, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF8E8E93),
                borderRadius: BorderRadius.circular(7)),
            child: Text('$n',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Positioned(
            left: 3,
            bottom: -6,
            child: CustomPaint(
                size: const Size(9, 7),
                painter: _TailPainter(const Color(0xFF8E8E93))),
          ),
        ]),
      );

  Widget _plusBubble(VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _muted, width: 1.6)),
          child: Icon(Icons.add, size: 17, color: _muted),
        ),
      );

  Widget _para(String t,
      {required String ck,
      int count = 0,
      bool plus = false,
      bool bold = false,
      bool center = false,
      double? size}) {
    final cid = _srvCid(ck);
    final total = cid != null
        ? _srvCount(cid, _paraOf(ck))
        : count + _added(ck).length;
    final show = _p.commentsOn; // tombol + / jumlah komentar di tiap paragraf
    void open() => _openComments(ck, count, quote: t);
    return _pad(Padding(
      padding: EdgeInsets.only(bottom: _p.fontSize * 1.1),
      child: SizedBox(
        width: double.infinity,
        child: Stack(children: [
          Padding(
            padding: EdgeInsets.only(right: _p.commentsOn ? 38 : 0),
            child: Text(t,
                textAlign: center ? TextAlign.center : TextAlign.start,
                style: _style(bold: bold, size: size)),
          ),
          if (show)
            Positioned(
                right: 0,
                bottom: 0,
                child: total == 0 ? _plusBubble(open) : _bubble(total, open)),
        ]),
      ),
    ));
  }

  Widget _statsRow(int ch) {
    Widget item(IconData i, String t) => Row(children: [
          Icon(i, size: 16, color: _muted),
          const SizedBox(width: 7),
          Text(t, style: TextStyle(color: _muted, fontSize: 14)),
        ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        item(Icons.remove_red_eye, s.views),
        const SizedBox(width: 38),
        item(Icons.star, votesOf(s)),
        const SizedBox(width: 38),
        item(Icons.comment, '${_commentTotal(ch)}'),
      ]),
    );
  }

  /// [vh] > 0 = mode gulir (tanpa tombol lanjut statis, bab berikutnya ditarik
  /// dari ujung bab). Mode halaman memakai 0 dan tetap punya tombol lanjut.
  List<Widget> _items(int ch, {double vh = 0}) {
    final i0 = ch % _paras.length;
    String para(int k) => _paras[(i0 + k) % _paras.length];
    final srv = _serverParas(ch);
    final List<Widget> body;
    if (srv == null) {
      body = [
        _para(para(0), ck: '$ch:0', count: _cnt(ch, 0)),
        _para(para(1), ck: '$ch:1'),
        _para(para(2), ck: '$ch:2', count: _cnt(ch, 2)),
        _para(para(3), ck: '$ch:3'),
        _para(para(4), ck: '$ch:4', count: _cnt(ch, 4)),
      ];
    } else if (srv.isEmpty) {
      body = [_para('Memuat bab...', ck: '$ch:0')];
    } else {
      body = [
        for (var k = 0; k < srv.length; k++)
          _para(srv[k], ck: '$ch:$k', count: k % 2 == 0 ? _cnt(ch, k) : 0),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 0),
        child: Text(_chapterName(ch),
            textAlign: TextAlign.center,
            style: _style(size: _p.fontSize + 6)),
      ),
      _statsRow(ch),
      ...body,
      _para('Bersambung ke bab berikutnya...', ck: '$ch:z5', count: _cnt(ch, 5)),
      _para('Catatan Penulis:', ck: '$ch:z6', plus: true, bold: true),
      _para('Terima kasih sudah membaca sampai sini! Jangan lupa tinggalkan '
          'vote dan komentar ya.', ck: '$ch:z7', plus: true),
      _para('Simpan di perpustakaan kalian biar nggak ketinggalan update. '
          'Dan follow penulis dulu, yuk!', ck: '$ch:z8', count: _cnt(ch, 7)),
      const SizedBox(height: 40),
    ];
  }

  Widget _content() {
    if (_p.scrollMode) {
      // Satu bab per tampilan; di ujung bab, tarik/gulir terus untuk membuka
      // halaman bab berikutnya (lihat _onScrollNote / _onWheel).
      return Listener(
        onPointerDown: _ptrDown,
        onPointerMove: _ptrMove,
        onPointerUp: _ptrUp,
        onPointerCancel: _ptrCancel,
        onPointerSignal: _onWheel,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNote,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: LayoutBuilder(builder: (context, box) => ListView.builder(
              controller: _scroll,
              physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.zero,
              itemCount: 1,
              itemBuilder: (_, __) => KeyedSubtree(
                  key: _chKey(_ch),
                  child: Column(
                      children: _items(_ch, vh: box.maxHeight))),
            )),
          ),
        ),
      );
    }
    // Mode Halaman: satu bab dibagi menjadi beberapa halaman yang digeser
    // mendatar. Di halaman terakhir, geser terus ke kiri -> bab berikutnya masuk
    // dari kanan; di halaman pertama, geser ke kanan -> bab sebelumnya masuk
    // dari kiri (lihat _onScrollNote / _onWheel).
    final pages = _pagesFor(_ch);
    _pageCount = pages.length;
    return Listener(
      onPointerDown: _ptrDown,
      onPointerMove: _ptrMove,
      onPointerUp: _ptrUp,
      onPointerCancel: _ptrCancel,
      onPointerSignal: _onWheel,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNote,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: PageView(
            controller: _pageCtl,
            physics: const PageScrollPhysics(
                parent: ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics())),
            children: [
              for (var i = 0; i < pages.length; i++)
                SingleChildScrollView(
                    key: ValueKey('page-$_ch-$i'),
                    child: Column(children: pages[i])),
            ],
          ),
        ),
      ),
    );
  }

  /// Isi sebuah bab yang dipotong menjadi halaman-halaman (mode halaman).
  List<List<Widget>> _pagesFor(int ch) {
    final items = _items(ch);
    final pages = <List<Widget>>[];
    const per = 4;
    for (var i = 0; i < items.length; i += per) {
      pages.add(items.sublist(i, i + per > items.length ? items.length : i + per));
    }
    return pages;
  }

  // ----------------------------- app bar -----------------------------
  Widget _appBar() {
    final off = AppState.offline.value.contains(s.title);
    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Stack(alignment: Alignment.center, children: [
            // Judul selalu di tengah layar; terlalu panjang -> titik-titik (...)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 112),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openToc,
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text(_appBarTitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              height: 1.15,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 24),
                  ]),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 27),
                  onPressed: _leave),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(
                      off ? Icons.cloud_done_outlined : Icons.cloud_outlined,
                      size: 26),
                  onPressed: () {
                    AppState.toggleOffline(s);
                    _snack(off ? 'Unduhan dihapus' : 'Tersedia offline');
                    setState(() {});
                  },
                ),
                GestureDetector(
                  onTap: () => setState(() => _aa = !_aa),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(6, 0, 18, 0),
                    child: Text('Aa',
                        style:
                            TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  /// Daftar isi layar penuh: cover + judul novel di atas, lalu daftar bab.
  void _openToc() {
    final titles = _titles;
    const rowH = 50.0;
    final ctl = ScrollController(
        initialScrollOffset: (_ch * rowH - 120).clamp(0.0, double.infinity));
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(
        backgroundColor: C.bg,
        body: Column(children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 62,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                    icon: const Icon(Icons.close, size: 30),
                    onPressed: () => Navigator.pop(ctx)),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          Expanded(
            child: ListView(
              controller: ctl,
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 22),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BookCover(s, w: 76, h: 118),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.title.replaceAll('\n', ' '),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  Text('By ${s.author}',
                                      style: const TextStyle(
                                          fontSize: 17, color: C.grey)),
                                ]),
                          ),
                        ),
                      ]),
                ),
                for (var i = 0; i < titles.length; i++)
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (i != _ch) _goTo(i);
                    },
                    child: SizedBox(
                      height: rowH,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(children: [
                          Expanded(
                            child: Text(titles[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: i == _ch
                                        ? C.orange
                                        : const Color(0xFFEDEDED))),
                          ),
                          const SizedBox(width: 10),
                          Text(fmtChapterDate(chapterDate(s, i)),
                              style: const TextStyle(
                                  color: Color(0xFFDDDDDD), fontSize: 14.5)),
                        ]),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ]),
      ),
    ));
  }

  // ----------------------------- panel "Aa" -----------------------------
  Widget _aaPanel() {
    final panelBg = _dark ? C.bg : Colors.white;
    final btnBg = _dark ? const Color(0xFF2C2C2C) : const Color(0xFFEFEFEF);
    final ink = _dark ? Colors.white : Colors.black;
    final border = _dark ? const Color(0xFF5A5A5A) : const Color(0xFFBDBDBD);

    Widget swatch(int i, Color c) => Expanded(
          child: GestureDetector(
            onTap: () => _p.update(() {
              _p.followApp = false;
              _p.pageTheme = i;
            }),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                  color: c,
                  border: Border.all(
                      color: _theme == i ? C.orange : Colors.transparent,
                      width: 2.5)),
            ),
          ),
        );

    Widget btn(String t, VoidCallback f, {bool big = false}) => Expanded(
          child: GestureDetector(
            onTap: f,
            child: Container(
              height: big ? 64 : 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: btnBg, border: Border.all(color: border)),
              child: Text(t, style: TextStyle(fontSize: 21, color: ink)),
            ),
          ),
        );

    return Material(
      color: panelBg,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Warna halaman',
                  style: TextStyle(fontSize: 14, color: _muted))),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
                child: Text('Ikuti pengaturan aplikasi Wattpret',
                    style: TextStyle(fontSize: 17, color: ink))),
            _toggle(_p.followApp, (v) => _p.update(() => _p.followApp = v)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            swatch(0, Colors.white),
            swatch(1, C.bg),
            swatch(2, C.sepia),
          ]),
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Font', style: TextStyle(fontSize: 15, color: ink))),
          const SizedBox(height: 8),
          Row(children: [
            btn('Aa-', () => _p.update(() {
                  _p.fontSize = (_p.fontSize - 1).clamp(14, 30).toDouble();
                })),
            btn('Aa+', () => _p.update(() {
                  _p.fontSize = (_p.fontSize + 1).clamp(14, 30).toDouble();
                })),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            btn(_p.fontName,
                () => _p.update(() => _p.fontIndex = (_p.fontIndex + 1) % ReaderPrefs.fonts.length),
                big: true),
          ]),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              setState(() => _aa = false);
              _openPrefs();
            },
            child: Text('Pengaturan Lainnya...',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
          ),
        ]),
      ),
    );
  }

  Widget _toggle(bool v, ValueChanged<bool> f) => Switch(
        value: v,
        onChanged: f,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFE8703A),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFF3A3A3C),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      );

  // ------------------------ Preferensi Membaca ------------------------
  void _openPrefs() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: _p,
        builder: (_, __) {
          Widget row(Widget child, {double h = 62}) => Container(
                constraints: BoxConstraints(minHeight: h),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2C),
                    border: Border(bottom: BorderSide(color: Color(0xFF3A3A3C)))),
                alignment: Alignment.center,
                child: child,
              );
          Widget sw(String t, bool v, ValueChanged<bool> f) => row(Row(children: [
                Expanded(child: Text(t, style: const TextStyle(fontSize: 18))),
                _toggle(v, f),
              ]));
          return Container(
            decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 62,
                  child: Stack(alignment: Alignment.center, children: [
                    const Text('Preferensi Membaca',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: () => Navigator.pop(ctx)),
                    ),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFF2E2E2E)),
                const SizedBox(height: 18),
                sw('Kunci Orientasi Layar', _p.lockOrientation,
                    (v) => _p.update(() => _p.lockOrientation = v)),
                sw('Komentar dalam Paragraf dan Reaksi', _p.commentsOn,
                    (v) => _p.update(() => _p.commentsOn = v)),
                row(Row(children: [
                  const Expanded(
                      child: Text('Mode Baca', style: TextStyle(fontSize: 18))),
                  SizedBox(
                    width: 190,
                    child: Segmented(
                      labels: const ['Halaman', 'Gulir'],
                      index: _p.scrollMode ? 1 : 0,
                      onChanged: (i) => _p.update(() => _p.scrollMode = i == 1),
                      bg: const Color(0xFF1C1C1E),
                      selBg: const Color(0xFF6B6B70),
                      height: 40,
                      fontSize: 15,
                    ),
                  ),
                ])),
                sw('Gulir Otomatis', _p.autoScroll,
                    (v) => _p.update(() => _p.autoScroll = v)),
                row(
                    Row(children: [
                      const Text('🐢', style: TextStyle(fontSize: 22)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(ctx).copyWith(
                            trackHeight: 4,
                            activeTrackColor: const Color(0xFF8A4B2E),
                            inactiveTrackColor: const Color(0xFF8A4B2E),
                            thumbColor: const Color(0xFF8E8E93),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                              value: _p.speed,
                              onChanged: (v) => _p.update(() => _p.speed = v)),
                        ),
                      ),
                      const Text('🐇', style: TextStyle(fontSize: 22)),
                    ]),
                    h: 66),
                Container(
                  color: const Color(0xFF2A2A2C),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('Preferensi Lewati Iklan',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('BARU',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        const Text(
                            'Jika diaktifkan, kamu bisa mendapatkan Lewati Iklan di antara bab cerita saat kamu membaca',
                            style: TextStyle(
                                fontSize: 15, height: 1.3, color: Color(0xFFA8A8A8))),
                        const SizedBox(height: 10),
                        const Text('Info selengkapnya',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    _toggle(_p.skipAds, (v) => _p.update(() => _p.skipAds = v)),
                  ]),
                ),
                const SizedBox(height: 90),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------- bawah -----------------------------
  Widget _toast() => GestureDetector(
        onTap: () {
          AppState.addToLibrary(s);
          setState(() => _toastGone = true);
          _snack('Ditambahkan ke Perpustakaan');
        },
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.black, borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            BookCover(s, w: 42, h: 62),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Menyukai cerita ini?',
                        style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Tambah ke Perpustakaan',
                        style: TextStyle(fontSize: 17, color: Colors.white)),
                  ]),
            ),
            const Icon(Icons.add, size: 34, color: Colors.white),
          ]),
        ),
      );

  Widget _bottomBar() {
    final voted = AppState.voted.value.contains(s.title);
    final ink = _dark ? const Color(0xFFD8D8D8) : const Color(0xFF444444);
    Widget item(Widget icon, String label, VoidCallback f, {Color? color}) =>
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: f,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              icon,
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: color ?? _muted)),
            ]),
          ),
        );
    return Container(
      color: _barBg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(children: [
            item(
                Icon(voted ? Icons.star : Icons.star_border,
                    size: 28, color: voted ? C.orange : ink),
                votesOf(s),
                () => AppState.toggleVote(s)),
            item(_BubbleIcon(size: 26, color: ink),
                '${_totalFor(_ch) + _added('$_ch:all').length}',
                () => _openComments('$_ch:all', _totalFor(_ch))),
            item(const Icon(Icons.bolt, size: 28, color: C.premium), 'Tanpa Iklan',
                () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const PremiumScreen())),
                color: C.premium),
            item(Icon(Icons.send_outlined, size: 25, color: ink), 'Bagikan',
                _showShare),
            SizedBox(
              width: 52,
              child: IconButton(
                icon: Icon(Icons.more_vert, color: ink),
                onPressed: _showActions,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ------------------------------ bagikan ------------------------------
  String get _shareLink {
    final slug = s.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'https://www.wattpret.com/story/$slug';
  }

  /// Menu kecil di atas bilah bawah: WhatsApp, Kirim ke Profil, Salin Tautan, Facebook.
  void _showShare() {
    final link = _shareLink;
    final text =
        'Baca "${s.title.replaceAll('\n', ' ')}" oleh ${s.author} di Wattpret\n$link';
    // tinggi progres (20) + bilah bawah (60) + area aman
    final bottom = 80 + MediaQuery.of(context).padding.bottom + 6;
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        Future<void> open(String url) async {
          Navigator.pop(ctx);
          try {
            final ok = await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
            if (!ok && mounted) _snack('Tidak bisa membuka aplikasinya');
          } catch (_) {
            if (mounted) _snack('Tidak bisa membuka aplikasinya');
          }
        }

        Widget circle(Color bg, Widget child) => Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: child,
            );

        Widget row(Widget icon, String label, VoidCallback f,
                {bool last = false}) =>
            InkWell(
              onTap: f,
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    border: last
                        ? null
                        : const Border(
                            bottom: BorderSide(color: Colors.white70, width: 0.7))),
                child: Row(children: [
                  icon,
                  const SizedBox(width: 14),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.white)),
                ]),
              ),
            );

        return Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(left: 60, right: 10, bottom: bottom),
            child: Material(
              color: const Color(0xFF121212),
              elevation: 10,
              borderRadius: BorderRadius.circular(6),
              clipBehavior: Clip.antiAlias,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                row(
                    circle(const Color(0xFF4CB927),
                        const Icon(Icons.call, size: 24, color: Colors.white)),
                    'WhatsApp',
                    () => open('https://wa.me/?text=${Uri.encodeComponent(text)}')),
                row(
                    circle(const Color(0xFFFF9A1F),
                        const Icon(Icons.person, size: 26, color: Colors.white)),
                    'Kirim ke Profil', () {
                  Navigator.pop(ctx);
                  _snack('Dikirim ke profilmu');
                }),
                row(
                    circle(const Color(0xFF444444),
                        Transform.rotate(
                            angle: -0.785,
                            child: const Icon(Icons.link,
                                size: 24, color: Colors.white))),
                    'Salin Tautan', () {
                  Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(ctx);
                  _snack('Tautan disalin');
                }),
                row(
                    circle(const Color(0xFF3B5998),
                        const Text('f',
                            style: TextStyle(
                                fontSize: 28,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: Colors.white))),
                    'Facebook',
                    () => open(
                        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}'),
                    last: true),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------ tindakan ------------------------------
  void _showActions() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 14, 8),
            child: Row(children: [
              const Expanded(
                  child: Text('Tindakan',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800))),
              IconButton(
                  icon: const Icon(Icons.close, size: 30),
                  onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(ctx);
              _snack('Terima kasih, laporanmu diterima');
            },
            child: const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 30),
              child: Row(children: [
                Icon(Icons.flag_outlined, size: 32),
                SizedBox(width: 20),
                Text('Laporkan', style: TextStyle(fontSize: 20)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [_p, AppState.library, AppState.voted, AppState.followed]),
      builder: (context, _) {
        final showToast = !_toastGone && !AppState.inLibrary(s);
        return PopScope(
          canPop: _allowPop || AppState.inLibrary(s),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave();
          },
          child: LightCounter(
          enabled: LightScope.of(context) && !_p.followApp,
          child: Scaffold(
          backgroundColor: _bg,
          body: Column(children: [
            _appBar(),
            Expanded(
              child: Stack(children: [
                Positioned.fill(
                    child: ColoredBox(key: _viewKey, color: _bg, child: _content())),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, c) => IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (_, __) {
                          final v = _anim.value;
                          if (v <= 0.001 || !_hasNext) {
                            return const SizedBox.shrink();
                          }
                          if (!_p.scrollMode) {
                            return _slidePanel(_ch + 1, v, c.maxWidth,
                                c.maxHeight,
                                fromRight: true);
                          }
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                                height: c.maxHeight * v,
                                width: double.infinity,
                                child: _nextPanel(v, c.maxHeight)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, c) => IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _animPrev,
                        builder: (_, __) {
                          final v = _animPrev.value;
                          if (v <= 0.001 || !_hasPrev) {
                            return const SizedBox.shrink();
                          }
                          if (!_p.scrollMode) {
                            return _slidePanel(_ch - 1, v, c.maxWidth,
                                c.maxHeight,
                                fromRight: false);
                          }
                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                                height: c.maxHeight * v,
                                width: double.infinity,
                                child: _prevPanel(v, c.maxHeight)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (showToast)
                  Positioned(left: 8, right: 8, bottom: 6, child: _toast()),
                if (_aa)
                  Positioned(top: 0, left: 0, right: 0, child: _aaPanel()),
              ]),
            ),
            _progressBar(),
            _bottomBar(),
          ]),
          )),
        );
      },
    );
  }
}

/// Ikon komentar: gelembung bulat dengan ekor di kiri bawah.
class _BubbleIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _BubbleIcon({required this.size, required this.color});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _BubblePainter(color));
}

class _BubblePainter extends CustomPainter {
  final Color color;
  _BubblePainter(this.color);
  @override
  void paint(Canvas canvas, Size sz) {
    final w = sz.width, h = sz.height;
    final c = Offset(w * 0.5, h * 0.47);
    final r = w * 0.40;
    Offset pt(double deg) {
      final t = deg * 3.141592653589793 / 180;
      return Offset(c.dx + r * _cos(t), c.dy + r * _sin(t));
    }

    final path = Path()
      ..moveTo(pt(150).dx, pt(150).dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), 150 * 3.141592653589793 / 180,
          315 * 3.141592653589793 / 180, false)
      ..lineTo(w * 0.14, h * 0.92)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.075
          ..strokeJoin = StrokeJoin.round);
  }

  double _cos(double t) => math.cos(t);
  double _sin(double t) => math.sin(t);

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.color != color;
}

class _TailPainter extends CustomPainter {
  final Color color;
  _TailPainter(this.color);
  @override
  void paint(Canvas canvas, Size sz) {
    canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(sz.width, 0)
          ..lineTo(0, sz.height)
          ..close(),
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => old.color != color;
}

class _Cmt {
  final String author, text;
  final DateTime date;
  final int? id;
  _Cmt(this.author, this.text, this.date, {this.id});
}
