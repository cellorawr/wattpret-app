import 'dart:async';
import 'api_service.dart';
import 'app_state.dart';
import 'data.dart';

/// Menyamakan "Karya" (cerita yang ditulis pengguna) dengan server.
/// Perubahan di aplikasi dikirim otomatis di latar belakang; saat login,
/// karya milik akun diambil dari server.
class WorkSync {
  static Timer? _timer, _debounce;
  static bool _busy = false;
  static final Set<int> _deleted = {};

  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => run());
  }

  static void stop() {
    _timer?.cancel();
    _debounce?.cancel();
    _timer = null;
    _deleted.clear();
  }

  static void schedule() {
    if (!Api.isLoggedIn) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1200), run);
  }

  static void markDeleted(int serverId) {
    _deleted.add(serverId);
    schedule();
  }

  // ---------------------------------------------------------------- util
  static List<String> _csv(dynamic v) => (v ?? '')
      .toString()
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  static String _storySnap(Work w) => [
        w.title, w.synopsis, w.lang, w.type, w.rights, w.genres.join(','),
        w.tags.join(','), w.mature, w.complete, w.published, w.category ?? '',
        w.fandomClass ?? '', w.fandoms.join(','), w.fandomTopics.join(','),
        w.fanFormats.join(','),
      ].join('\u0001');

  static String _partSnap(Part p) => '${p.title}\u0001${p.body}\u0001${p.published}';

  /// Urutan bab saat ini (hanya id server), mis. "12,15,14".
  static String _order(Work w) => w.parts.map((p) => p.serverId ?? 0).join(',');

  static String _full(Work w) =>
      _storySnap(w) + '\u0002' + w.parts.map(_partSnap).join('\u0003');

  static String? _category(Work w) {
    if (w.genres.isNotEmpty) return w.genres.first;
    return w.category;
  }

  static Map<String, dynamic> _meta(Work w) => {
        'category': w.category,
        'fandomClass': w.fandomClass,
        'fandoms': w.fandoms,
        'fandomTopics': w.fandomTopics,
        'fanFormats': w.fanFormats,
      };

  static Map<String, dynamic> _fields(Work w) => {
        'title': w.title.trim(),
        'synopsis': w.synopsis,
        'category': _category(w),
        'tags': w.tags,
        'genres': w.genres,
        'lang': w.lang,
        'type': w.type,
        'rights': w.rights,
        'mature': w.mature,
        'complete': w.complete,
        'published': w.published,
        'meta': _meta(w),
      };

  // ---------------------------------------------------------------- kirim
  static Future<void> run() async {
    if (_busy || !Api.isLoggedIn) return;
    _busy = true;
    var changed = false;
    try {
      for (final id in _deleted.toList()) {
        try {
          await Api.deleteStory(id);
        } catch (_) {}
        _deleted.remove(id);
        changed = true;
      }
      for (final w in List<Work>.from(AppState.works.value)) {
        if (w.serverId == null && w.title.trim().isEmpty) continue;
        final full = _full(w);
        final hasCover = w.cover != null && !identical(w.cover, w.coverSynced);
        final mediaPending = w.parts.any((p) =>
            p.imgSynced < p.images.length || p.vidSynced < p.videos.length);
        if (w.serverId != null &&
            w.snap == _storySnap(w) &&
            !hasCover &&
            !mediaPending &&
            w.parts.every((p) => p.serverId != null && p.snap == _partSnap(p)) &&
            w.syncedPartIds.length == w.parts.length &&
            w.orderSnap == _order(w)) {
          continue; // tidak ada perubahan
        }
        if (w.failFull == full && !hasCover && !mediaPending) continue;
        try {
          await _pushWork(w);
          w.failFull = null;
          changed = true;
        } catch (_) {
          w.failFull = full;
        }
      }
    } finally {
      _busy = false;
    }
    if (changed) ServerStories.load();
  }

  static Future<void> _pushWork(Work w) async {
    if (w.serverId == null) {
      final r = await Api.createStory(
        title: w.title.trim(),
        synopsis: w.synopsis,
        category: _category(w),
        tags: w.tags,
        genres: w.genres,
        lang: w.lang,
        type: w.type,
        rights: w.rights,
        mature: w.mature,
        complete: w.complete,
        published: w.published,
        meta: _meta(w),
      );
      w.serverId = int.parse('${r['id']}');
      w.snap = _storySnap(w);
    } else if (w.snap != _storySnap(w)) {
      if (w.title.trim().isNotEmpty) {
        await Api.updateStory(w.serverId!, _fields(w));
        w.snap = _storySnap(w);
      }
    }
    final sid = w.serverId!;

    if (w.cover != null && !identical(w.cover, w.coverSynced)) {
      await Api.uploadStoryCover(sid, w.cover!);
      w.coverSynced = w.cover;
    }

    final present = <int>{};
    for (final p in List<Part>.from(w.parts)) {
      final title = p.title.trim().isEmpty ? 'Tanpa judul' : p.title.trim();
      if (p.serverId == null) {
        final c = await Api.addChapter(sid, title, p.body, published: p.published);
        p.serverId = int.parse('${c['id']}');
        p.snap = _partSnap(p);
        w.syncedPartIds.add(p.serverId!);
      } else if (p.snap != _partSnap(p)) {
        await Api.updateChapter(p.serverId!,
            title: title, body: p.body, published: p.published);
        p.snap = _partSnap(p);
      }
      present.add(p.serverId!);
      while (p.imgSynced < p.images.length) {
        await Api.addChapterImage(p.serverId!, p.images[p.imgSynced]);
        p.imgSynced++;
      }
      while (p.vidSynced < p.videos.length) {
        await Api.addChapterVideo(p.serverId!, p.videos[p.vidSynced]);
        p.vidSynced++;
      }
    }
    for (final id in w.syncedPartIds.toList()) {
      if (!present.contains(id)) {
        try {
          await Api.deleteChapter(id);
        } catch (_) {}
        w.syncedPartIds.remove(id);
      }
    }

    // Urutan bab (hasil tukar posisi) ikut disimpan ke server.
    final order = _order(w);
    if (w.orderSnap != order && w.parts.every((p) => p.serverId != null)) {
      await Api.reorderChapters(sid, [for (final p in w.parts) p.serverId!]);
      w.orderSnap = order;
    }
  }

  // ---------------------------------------------------------------- ambil
  /// Mengambil karya milik akun (termasuk draf) dari server.
  static Future<void> loadFromServer() async {
    final list = await Api.myStories();
    final out = <Work>[];
    for (final j in list) {
      final id = int.tryParse('${j['id']}');
      if (id == null || AppState.works.value.any((w) => w.serverId == id)) {
        continue;
      }
      final d = await Api.story(id);
      final Map<String, dynamic> meta =
          j['meta'] is Map ? Map<String, dynamic>.from(j['meta']) : <String, dynamic>{};
      List<String> ml(String k) =>
          meta[k] is List ? [for (final x in meta[k]) x.toString()] : <String>[];
      final w = Work(
        title: (j['title'] ?? '').toString(),
        synopsis: (j['synopsis'] ?? '').toString(),
        lang: (j['lang'] ?? 'English').toString(),
        type: (j['type'] ?? '').toString(),
        rights: (j['rights'] ?? 'Hak Cipta Dilindungi Undang-Undang').toString(),
        fandomClass: meta['fandomClass']?.toString(),
        category: meta['category']?.toString(),
        genres: _csv(j['genres']),
        tags: _csv(j['tags']),
        fandoms: ml('fandoms'),
        fandomTopics: ml('fandomTopics'),
        fanFormats: ml('fanFormats'),
        mature: j['mature'] == true,
        complete: j['complete'] == true,
        published: j['published'] == true,
      );
      for (final c in (d['chapters'] as List? ?? const [])) {
        final cid = int.parse('${c['id']}');
        final full = await Api.chapter(cid);
        final p = Part(
          title: (full['title'] ?? '').toString(),
          body: (full['body'] ?? '').toString(),
          published: full['published'] == true,
          updated: DateTime.tryParse('${full['updated_at']}')?.toLocal(),
        );
        p.serverId = cid;
        p.snap = _partSnap(p);
        // Gambar & video yang disisipkan di bab ikut dipulihkan.
        for (final m in (full['media'] as List? ?? const [])) {
          if (m is! Map) continue;
          if (m['type'] == 'image') {
            final mid = int.tryParse('${m['id']}');
            final bytes = mid == null ? null : await Api.mediaBytes(mid);
            if (bytes != null) p.images.add(bytes);
          } else if (m['type'] == 'video') {
            final u = (m['url'] ?? m['file_url'] ?? '').toString();
            if (u.isNotEmpty) p.videos.add(u);
          }
        }
        p.imgSynced = p.images.length;
        p.vidSynced = p.videos.length;
        w.syncedPartIds.add(cid);
        w.parts.add(p);
      }
      w.serverId = id;
      w.snap = _storySnap(w);
      w.orderSnap = _order(w);
      w.updated = DateTime.tryParse('${j['updated_at']}')?.toLocal() ?? w.updated;
      out.add(w);
    }
    AppState.works.value = [...AppState.works.value, ...out];
    AppState.syncMyStories();
  }
}
