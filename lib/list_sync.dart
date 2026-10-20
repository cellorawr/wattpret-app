import 'dart:async';

import 'api_service.dart';
import 'app_state.dart';
import 'data.dart';

/// Menyinkronkan daftar bacaan (dan daftar yang disukai) dengan server.
///
/// Semua perubahan lewat AppState.readingLists dikirim otomatis ke server
/// (ditunda 2 detik). Tidak perlu mengubah layar-layar yang sudah ada.
class ListSync {
  static bool _enabled = false;
  static bool _hooked = false;
  static bool _loading = false;
  static bool _busy = false;
  static bool _again = false;
  static Timer? _timer;

  /// Daftar yang sudah ada di server (untuk mendeteksi daftar yang dihapus).
  static final Set<ReadingList> _tracked = {};

  /// 'pemilik/nama' -> id daftar di server (daftar yang disukai).
  static final Map<String, int> _likedIds = {};

  static bool _b(dynamic v) => v == true || v == 1 || v == '1';

  static String _snap(ReadingList l) => '${l.name}\u0001${l.isPublic}';

  static Set<int> _ids(ReadingList l) =>
      {for (final s in l.own) if (s.id != null) s.id!};

  // ------------------------------------------------------------ ambil
  static Future<void> loadFromServer() async {
    _loading = true;
    try {
      final known = <int, Story>{
        for (final s in [
          ...AppState.library.value,
          ...AppState.archive.value,
          ...AppState.myStories.value
        ])
          if (s.id != null) s.id!: s
      };
      Story conv(dynamic j) {
        final m = Map<String, dynamic>.from(j as Map);
        final id = int.tryParse('${m['id']}');
        return (id != null ? known[id] : null) ?? Story.fromJson(m);
      }

      final raw = await Api.myReadingLists();
      final out = <ReadingList>[];
      _tracked.clear();
      for (final j in raw) {
        final isDef = _b(j['is_default']);
        final l = ReadingList(isDef ? '' : (j['name'] ?? '').toString(),
            isDefault: isDef,
            isPublic: _b(j['is_public']),
            stories: [for (final s in (j['stories'] as List? ?? const [])) conv(s)]);
        l.serverId = int.tryParse('${j['id']}');
        l.snap = _snap(l);
        l.serverStoryIds
          ..clear()
          ..addAll(_ids(l));
        _tracked.add(l);
        out.add(l);
      }
      if (out.isNotEmpty) AppState.readingLists.value = out;

      try {
        final liked = await Api.likedLists();
        _likedIds.clear();
        final ll = <LikedList>[];
        for (final j in liked) {
          final o = j['owner'];
          final owner = o is Map ? (o['username'] ?? '').toString() : '';
          final name = (j['name'] ?? '').toString();
          final id = int.tryParse('${j['id']}');
          if (id != null) _likedIds['$owner/$name'] = id;
          final stories = [for (final s in (j['stories'] as List? ?? const [])) conv(s)];
          ll.add(LikedList(owner, name, () => stories));
        }
        AppState.likedLists.value = ll;
      } catch (_) {}
    } finally {
      _loading = false;
    }
  }

  // ------------------------------------------------------------ kirim
  static void start() {
    _enabled = true;
    if (!_hooked) {
      _hooked = true;
      AppState.readingLists.addListener(schedule);
    }
  }

  static void stop() {
    _enabled = false;
    _timer?.cancel();
    _tracked.clear();
    _likedIds.clear();
  }

  static void schedule() {
    if (!_enabled || _loading) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), push);
  }

  static Future<void> push() async {
    if (!_enabled || !Api.isLoggedIn) return;
    if (_busy) {
      _again = true;
      return;
    }
    _busy = true;
    try {
      final now = AppState.readingLists.value;

      // daftar yang dihapus di aplikasi
      for (final l in _tracked.toList()) {
        if (now.contains(l)) continue;
        _tracked.remove(l);
        final id = l.serverId;
        if (id != null && !l.isDefault) {
          try {
            await Api.deleteReadingList(id);
          } catch (_) {}
        }
      }

      for (final l in List<ReadingList>.of(now)) {
        try {
          if (l.serverId == null) {
            if (l.isDefault || l.name.trim().isEmpty) continue;
            final r = await Api.createReadingList(l.name.trim(), isPublic: l.isPublic);
            l.serverId = int.parse('${r['id']}');
            l.snap = _snap(l);
            _tracked.add(l);
          } else if (l.snap != _snap(l)) {
            await Api.updateReadingList(l.serverId!,
                name: l.isDefault ? null : l.name, isPublic: l.isPublic);
            l.snap = _snap(l);
          }

          final id = l.serverId!;
          final cur = _ids(l);
          for (final sid in cur.difference(l.serverStoryIds)) {
            final added = await Api.toggleStoryInList(id, sid);
            if (!added) await Api.toggleStoryInList(id, sid);
            l.serverStoryIds.add(sid);
          }
          for (final sid in l.serverStoryIds.difference(cur).toList()) {
            final added = await Api.toggleStoryInList(id, sid);
            if (added) await Api.toggleStoryInList(id, sid);
            l.serverStoryIds.remove(sid);
          }
        } catch (_) {
          // gagal: dicoba lagi pada perubahan berikutnya
        }
      }
    } finally {
      _busy = false;
      if (_again) {
        _again = false;
        schedule();
      }
    }
  }

  /// Suka / batal suka daftar bacaan milik orang lain (usaha terbaik).
  static void pushLike(String owner, String name, bool want) {
    if (!Api.isLoggedIn) return;
    () async {
      try {
        var id = _likedIds['$owner/$name'];
        if (id == null) {
          for (final j in await Api.readingListsOf(owner)) {
            if ((j['name'] ?? '').toString() == name) {
              id = int.tryParse('${j['id']}');
            }
          }
        }
        if (id == null) return;
        _likedIds['$owner/$name'] = id;
        final now = await Api.toggleListLike(id);
        if (now != want) await Api.toggleListLike(id);
      } catch (_) {}
    }();
  }
}
