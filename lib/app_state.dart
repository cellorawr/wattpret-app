import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'data.dart';
import 'list_sync.dart';
import 'work_sync.dart';

// ---------------------------------------------------------------------------
// Format tanggal sederhana (tanpa paket intl)
// ---------------------------------------------------------------------------
const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov',
  'Des'
];
const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus',
  'September', 'Oktober', 'November', 'Desember'
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 14 Mar 2020, 12.38
String fmtShort(DateTime d) =>
    '${d.day} ${_bulanPendek[d.month - 1]} ${d.year}, ${_two(d.hour)}.${_two(d.minute)}';

/// 6 Des 2020
String fmtDate(DateTime d) =>
    '${d.day} ${_bulanPendek[d.month - 1]} ${d.year}';

/// Jumat, 16 Oktober 2026 - 06.04  (hari, tanggal, bulan, tahun, jam)
String fmtFull(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulanPanjang[d.month - 1]} ${d.year}';

const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Sen, Nov 25, 2024  (tanggal bab di tab "Bab")
String fmtChapterDate(DateTime d) =>
    '${_hariPendek[d.weekday - 1]}, ${_bulanPendek[d.month - 1]} ${d.day}, ${d.year}';

/// Judul bab contoh untuk sebuah cerita (Prolog, [1]. ..., [2]. ...).
const _chapterWords = [
  'Awal Mula',
  'Pertemuan',
  'Yang Tak Terduga',
  'Rahasia Kecil',
  'Jalan Pulang',
  'Hujan Sore Itu',
  'Pilihan',
  'Janji',
  'Salah Paham',
  'Kabar Baru',
  'Di Persimpangan',
  'Titik Balik',
];

List<String> chapterTitles(Story s) {
  final sc = s.id == null ? null : ServerCache.chapters[s.id!];
  if (sc != null && sc.isNotEmpty) return [for (final c in sc) c.title];
  return [
    'Prolog',
    for (var i = 1; i < s.parts; i++)
      '[$i]. ${_chapterWords[(i - 1 + s.title.length) % _chapterWords.length]}',
  ];
}

DateTime chapterDate(Story s, int i) {
  final sc = s.id == null ? null : ServerCache.chapters[s.id!];
  if (sc != null && i >= 0 && i < sc.length) return sc[i].date;
  final base = DateTime(2024, 11, 25).add(Duration(days: (s.title.length * 7) % 30));
  return base.add(Duration(days: i * 2));
}

String fmtClock(DateTime d) => '${_two(d.hour)}.${_two(d.minute)}';

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return fmtDate(d);
}

// ---------------------------------------------------------------------------
// Karya tulis pengguna
// ---------------------------------------------------------------------------
class Part {
  String title, body;
  bool published;
  DateTime updated;

  /// Setiap kali bab disimpan/direvisi, waktunya dicatat di sini.
  final List<DateTime> revisions;

  /// Gambar yang disisipkan di dalam bab (dari ikon gambar / video).
  final List<Uint8List> images;

  /// Tautan video YouTube yang disisipkan di dalam bab (ikon video).
  final List<String> videos;
  int reads = 0, votes = 0, comments = 0;

  /// Penanda sinkronisasi dengan server (diisi otomatis).
  int? serverId;
  String? snap;
  int imgSynced = 0, vidSynced = 0;

  Part(
      {required this.title,
      this.body = '',
      this.published = false,
      DateTime? updated,
      List<DateTime>? revisions,
      List<Uint8List>? images,
      List<String>? videos})
      : updated = updated ?? DateTime.now(),
        revisions = revisions ?? [],
        images = images ?? [],
        videos = videos ?? [];

  void touch() {
    updated = DateTime.now();
    revisions.add(updated);
  }
}

class Work {
  String title, synopsis;
  String lang, type, rights;
  String? fandomClass;

  /// Sampul cerita yang diunggah pengguna (null = belum ada).
  Uint8List? cover;

  /// Kategori puisi / kategori nonfiksi (sesuai jenis cerita).
  String? category;
  List<String> genres, fandoms, tags, fandomTopics, fanFormats;
  bool mature, complete, published;
  final List<Part> parts;
  DateTime updated;

  /// Penanda sinkronisasi dengan server (diisi otomatis).
  int? serverId;
  String? snap, failFull;

  /// Urutan bab yang terakhir tersimpan di server (id dipisah koma).
  String? orderSnap;
  Uint8List? coverSynced;
  final Set<int> syncedPartIds = {};

  Work({
    required this.title,
    this.synopsis = '',
    this.lang = 'English',
    this.type = '',
    this.rights = 'Hak Cipta Dilindungi Undang-Undang',
    this.fandomClass,
    this.cover,
    this.category,
    List<String>? genres,
    List<String>? fandoms,
    List<String>? tags,
    List<String>? fandomTopics,
    List<String>? fanFormats,
    this.mature = false,
    this.complete = false,
    this.published = false,
    List<Part>? parts,
  })  : genres = genres ?? [],
        fandoms = fandoms ?? [],
        tags = tags ?? [],
        fandomTopics = fandomTopics ?? [],
        fanFormats = fanFormats ?? [],
        parts = parts ?? [],
        updated = DateTime.now();

  int get draftCount => parts.where((p) => !p.published).length;
  int get reads => parts.fold(0, (a, p) => a + p.reads);
  int get votes => parts.fold(0, (a, p) => a + p.votes);
  int get comments => parts.fold(0, (a, p) => a + p.comments);

  Story toStory() => Story(
      title.isEmpty ? 'Tanpa judul' : title,
      '@${AppState.username}',
      '$reads',
      parts.isEmpty ? 1 : parts.length,
      tags.isEmpty ? ['cerita'] : tags,
      const Color(0xFFFF6122),
      Colors.white,
      synopsis: synopsis,
      cover: cover,
      id: serverId);
}

// ---------------------------------------------------------------------------
// Daftar bacaan & percakapan
// ---------------------------------------------------------------------------
class ReadingList {
  String name;

  /// Daftar bawaan "<nama>'s Reading List" (dibuat otomatis oleh Wattpret).
  final bool isDefault;

  /// Jika true, daftar memakai isi Perpustakaan (tidak dipakai lagi secara
  /// bawaan, dipertahankan agar kode lama tetap jalan).
  final bool isLibrary;

  /// Publik (bisa dilihat semua orang) atau Pribadi (hanya pemilik).
  bool isPublic;
  final List<Story> own;

  /// Penanda sinkronisasi dengan server (diisi otomatis).
  int? serverId;
  String? snap;
  final Set<int> serverStoryIds = {};
  ReadingList(this.name,
      {this.isLibrary = false,
      this.isDefault = false,
      this.isPublic = true,
      List<Story>? stories})
      : own = stories ?? [];

  List<Story> get stories => isLibrary ? AppState.library.value : own;
  bool has(Story s) => stories.any((x) => x.title == s.title);
}

/// Daftar bacaan (milik siapa pun) yang disukai pengguna.
class LikedList {
  final String owner, name;
  final List<Story> Function() _stories;
  LikedList(this.owner, this.name, this._stories);
  List<Story> get stories => _stories();
}

/// Pengaturan membaca (Aa + Preferensi Membaca).
class ReaderPrefs extends ChangeNotifier {
  /// 0 = putih, 1 = hitam, 2 = krem
  int pageTheme = 1;
  bool followApp = true;
  double fontSize = 20;
  int fontIndex = 0;
  bool scrollMode = true; // false = Halaman
  bool commentsOn = true;
  bool autoScroll = false;
  double speed = 0.7; // 0 (kura-kura) .. 1 (kelinci)
  bool skipAds = true;
  bool lockOrientation = false;

  static const fonts = ['Georgia', 'Times New Roman', 'Arial'];
  String get fontName => fonts[fontIndex % fonts.length];

  void update(VoidCallback f) {
    f();
    notifyListeners();
  }
}

class Reply {
  final String author, text;
  final DateTime date;
  Reply(this.author, this.text, this.date);
}

class Message {
  final String author, text;
  final DateTime date;
  final List<Reply> replies;
  Message(this.author, this.text, this.date, {List<Reply>? replies})
      : replies = replies ?? [];
}

class Profile {
  final String name, followers;
  const Profile(this.name, this.followers);
}

class AppState {
  static String email = 'email@contoh.com';
  static String username = 'pengguna123';
  static List<String> genres = [];

  static final ValueNotifier<List<Story>> library =
      ValueNotifier<List<Story>>([]);
  static final ValueNotifier<List<Story>> archive =
      ValueNotifier<List<Story>>([]);
  static final ValueNotifier<List<Story>> myStories =
      ValueNotifier<List<Story>>([]);
  static final ValueNotifier<int> coins = ValueNotifier<int>(0);
  static final ReaderPrefs reader = ReaderPrefs();
  static final ValueNotifier<Set<String>> followed =
      ValueNotifier<Set<String>>(<String>{});
  static final ValueNotifier<Set<String>> voted =
      ValueNotifier<Set<String>>(<String>{});

  /// Profil yang kuikuti (dari server) dan jumlah pengikutku.
  static final ValueNotifier<List<Profile>> followingList =
      ValueNotifier<List<Profile>>([]);
  static final ValueNotifier<int> myFollowers = ValueNotifier<int>(0);
  static List<Profile> get following => followingList.value;

  /// Menjalankan panggilan server di latar belakang (hanya bila sudah login).
  /// Kegagalan diabaikan: tampilan tetap berjalan dengan data lokal.
  static void _bg(Future<void> Function() f) {
    if (!Api.isLoggedIn) return;
    f().catchError((_) {});
  }

  static void toggleFollow(String name) {
    final n = {...followed.value};
    if (!n.remove(name)) n.add(name);
    followed.value = n;
    final want = n.contains(name);
    _bg(() async {
      final now = await Api.toggleFollow(name);
      if (now != want) await Api.toggleFollow(name);
      await _loadFollowing();
    });
  }

  /// Daftar profil yang kuikuti + jumlah pengikutku, dari server.
  static Future<void> _loadFollowing() async {
    try {
      final fol = await Api.following();
      followingList.value = [for (final j in fol) profileFromJson(j)];
      followed.value = {for (final j in fol) (j['username'] ?? '').toString()};
    } catch (_) {}
  }

  static Profile profileFromJson(Map<String, dynamic> j) => Profile(
      (j['username'] ?? '').toString(),
      fmtCount(int.tryParse('${j['followers_count']}') ?? 0));

  static void toggleVote(Story s) {
    final n = {...voted.value};
    final nowVoted = !n.remove(s.title);
    if (nowVoted) n.add(s.title);
    final id = s.id;
    final cur = id == null ? null : Story.voteCounts[id];
    if (id != null && cur != null) {
      Story.voteCounts[id] = (cur + (nowVoted ? 1 : -1)).clamp(0, 1 << 30).toInt();
    }
    voted.value = n;
    if (id == null) return;
    final want = n.contains(s.title);
    _bg(() async {
      var r = await Api.voteStory(id);
      if ((r['voted'] == true) != want) r = await Api.voteStory(id);
      final v = int.tryParse('${r['votes']}');
      if (v != null) {
        Story.voteCounts[id] = v;
        voted.value = {...voted.value};
      }
    });
  }

  /// Menyamakan status vote cerita dengan data detail dari server.
  static void applyDetail(Story s, Map<String, dynamic> d) {
    final id = s.id;
    final vc = int.tryParse('${d['votes_count']}');
    if (id != null && vc != null) Story.voteCounts[id] = vc;
    final v = d['voted'] == true;
    if (v != voted.value.contains(s.title)) {
      final n = {...voted.value};
      v ? n.add(s.title) : n.remove(s.title);
      voted.value = n;
    } else if (vc != null) {
      voted.value = {...voted.value};
    }
  }

  /// Mengambil perpustakaan, arsip, unduhan, progres, dan daftar ikuti dari server.
  static Future<void> syncFromServer() async {
    if (!Api.isLoggedIn) return;
    try {
      final lib = await Api.library();
      final arc = await Api.library(archived: true);
      library.value = [for (final j in lib) Story.fromJson(j)];
      archive.value = [for (final j in arc) Story.fromJson(j)];
      for (final s in library.value) {
        addedOrder.putIfAbsent(s.title, () => _counter++);
      }
      final off = <String>{};
      for (final j in [...lib, ...arc]) {
        final t = (j['title'] ?? '').toString();
        if (j['offline'] == true) off.add(t);
        final p = double.tryParse('${j['progress']}');
        if (p != null && p > 0) readProgress[t] = p;
        final lr = DateTime.tryParse('${j['last_read_at']}');
        if (lr != null) lastRead[t] = lr.toLocal();
      }
      offline.value = off;
      progressTick.value++;
      await _loadFollowing();
    } catch (_) {
      // server tidak terjangkau: biarkan data yang ada
    }
    try {
      await WorkSync.loadFromServer();
    } catch (_) {}
    await _loadProfile();
    await _loadCoins();
    try {
      await ListSync.loadFromServer();
    } catch (_) {}
    ListSync.start();
    WorkSync.start();
  }

  // --- profil: bio, foto profil, gambar latar (tersimpan di server) ---
  static bool _profileHooked = false;
  static bool _applyingProfile = false;

  static void _hookProfile() {
    if (_profileHooked) return;
    _profileHooked = true;
    bio.addListener(() {
      if (_applyingProfile) return;
      final v = bio.value;
      _bg(() async {
        await Api.updateProfile(bio: v);
      });
    });
    avatarBytes.addListener(() {
      if (_applyingProfile) return;
      final b = avatarBytes.value;
      _bg(() async {
        if (b == null) {
          await Api.deleteAvatar();
        } else {
          await Api.uploadAvatar(b);
        }
      });
    });
    coverBytes.addListener(() {
      if (_applyingProfile) return;
      final b = coverBytes.value;
      _bg(() async {
        if (b == null) {
          await Api.deleteCover();
        } else {
          await Api.uploadCover(b);
        }
      });
    });
  }

  static Future<void> _loadProfile() async {
    _hookProfile();
    _applyingProfile = true;
    try {
      final me = await Api.me();
      username = (me['username'] ?? username).toString();
      email = (me['email'] ?? email).toString();
      bio.value = (me['bio'] ?? '').toString();
      myFollowers.value = int.tryParse('${me['followers_count']}') ?? 0;
      avatarBytes.value =
          me['avatar_url'] != null ? await Api.myImage() : null;
      coverBytes.value =
          me['cover_url'] != null ? await Api.myImage(cover: true) : null;
    } catch (_) {
      // server tidak terjangkau: biarkan data yang ada
    } finally {
      _applyingProfile = false;
    }
  }

  /// Dipanggil saat keluar akun.
  static void resetSession() {
    WorkSync.stop();
    ListSync.stop();
    coins.value = 0;
    dailyClaimed = false;
    readingLists.value = [ReadingList('', isDefault: true)];
    likedLists.value = [];
    _applyingProfile = true;
    bio.value = '';
    avatarBytes.value = null;
    coverBytes.value = null;
    _applyingProfile = false;
    works.value = [];
    myStories.value = [];
    library.value = [];
    archive.value = [];
    followed.value = <String>{};
    followingList.value = [];
    myFollowers.value = 0;
    voted.value = <String>{};
    offline.value = <String>{};
    readProgress.clear();
    lastRead.clear();
    addedOrder.clear();
    progressTick.value++;
  }
  static final ValueNotifier<String> bio = ValueNotifier<String>('');
  /// Foto profil & gambar latar hasil kamera / galeri (null = bawaan).
  static final ValueNotifier<Uint8List?> avatarBytes = ValueNotifier<Uint8List?>(null);
  static final ValueNotifier<Uint8List?> coverBytes = ValueNotifier<Uint8List?>(null);
  static bool dailyClaimed = false;

  // --- karya (draf + terpublikasi) ---
  static final ValueNotifier<List<Work>> works = ValueNotifier<List<Work>>([]);

  /// Cerita yang baru saja dipublikasikan (memicu banner "Ditambahkan ke Karya").
  static final ValueNotifier<Work?> justPublished = ValueNotifier<Work?>(null);

  /// Minta MainShell pindah ke tab tertentu (3 = Tulis). -1 = tidak ada.
  static final ValueNotifier<int> tabRequest = ValueNotifier<int>(-1);

  static void notifyWorks() {
    works.value = [...works.value];
    WorkSync.schedule();
  }

  static void saveWork(Work w) {
    w.updated = DateTime.now();
    if (!works.value.contains(w)) {
      works.value = [w, ...works.value];
    } else {
      notifyWorks();
    }
    syncMyStories();
    WorkSync.schedule();
  }

  static void deleteWork(Work w) {
    works.value = works.value.where((x) => x != w).toList();
    syncMyStories();
    final id = w.serverId;
    if (id != null) WorkSync.markDeleted(id);
  }

  static void syncMyStories() {
    myStories.value = [
      for (final w in works.value)
        if (w.published) w.toStory()
    ];
  }

  // --- daftar bacaan ---
  static final ValueNotifier<List<ReadingList>> readingLists =
      ValueNotifier<List<ReadingList>>([
    ReadingList('', isDefault: true),
  ]);

  // --- daftar bacaan yang disukai (pribadi, tersembunyi dari profil) ---
  static final ValueNotifier<List<LikedList>> likedLists =
      ValueNotifier<List<LikedList>>([]);

  static bool isListLiked(String owner, String name) =>
      likedLists.value.any((x) => x.owner == owner && x.name == name);

  /// Suka / batal suka sebuah daftar bacaan. [stories] dibaca langsung dari
  /// daftar aslinya sehingga ikut berubah bila isinya berubah.
  static void toggleListLike(
      String owner, String name, List<Story> Function() stories) {
    if (isListLiked(owner, name)) {
      likedLists.value = likedLists.value
          .where((x) => !(x.owner == owner && x.name == name))
          .toList();
    } else {
      likedLists.value = [...likedLists.value, LikedList(owner, name, stories)];
    }
    ListSync.pushLike(owner, name, isListLiked(owner, name));
  }

  static String listName(ReadingList l) =>
      l.isDefault ? "$username's Reading List" : l.name;

  /// Tambah / hapus cerita dari sebuah daftar bacaan.
  static void toggleInList(ReadingList l, Story s) {
    if (l.has(s)) {
      l.own.removeWhere((x) => x.title == s.title);
    } else {
      l.own.add(s);
    }
    readingLists.value = [...readingLists.value];
  }

  // --- perpustakaan: unduhan offline, terakhir dibaca ---
  static final ValueNotifier<Set<String>> offline =
      ValueNotifier<Set<String>>(<String>{});
  static final Map<String, DateTime> lastRead = {};
  static final Map<String, int> addedOrder = {};
  static int _counter = 0;

  static void markRead(Story s) {
    lastRead[s.title] = DateTime.now();
    library.value = [...library.value];
  }

  static void toggleOffline(Story s) {
    final n = {...offline.value};
    if (!n.remove(s.title)) n.add(s.title);
    offline.value = n;
    final id = s.id;
    if (id == null) return;
    final want = n.contains(s.title);
    _bg(() async {
      final now = await Api.toggleOffline(id);
      if (now != want) await Api.toggleOffline(id);
    });
  }

  /// Perkiraan tanggal pembaruan cerita (data contoh, tetap per judul).
  static DateTime updatedOf(Story s) {
    var h = 0;
    for (final c in s.title.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return DateTime(2026, 10, 16).subtract(Duration(days: h % 700));
  }

  /// Progres baca nyata (0..1) per cerita, diisi oleh pembaca.
  static final Map<String, double> readProgress = {};
  static final ValueNotifier<int> progressTick = ValueNotifier<int>(0);

  static void setProgress(Story s, double v) {
    v = v.clamp(0.0, 1.0).toDouble();
    final old = readProgress[s.title] ?? 0.0;
    if ((old - v).abs() < 0.002) return;
    readProgress[s.title] = v;
    progressTick.value++;
    _pushProgress(s, v);
  }

  static final Map<int, Timer> _progTimers = {};

  /// Kirim progres baca ke server (ditunda 2 detik supaya tidak berondong).
  static void _pushProgress(Story s, double v) {
    final id = s.id;
    if (id == null || !Api.isLoggedIn) return;
    _progTimers[id]?.cancel();
    _progTimers[id] = Timer(const Duration(seconds: 2), () {
      final chs = ServerCache.chapters[id];
      int? cid;
      if (chs != null && chs.isNotEmpty) {
        cid = chs[(v * chs.length).floor().clamp(0, chs.length - 1).toInt()].id;
      }
      _bg(() => Api.setProgress(id, v, chapterId: cid));
    });
  }

  static double progressOf(Story s) => readProgress[s.title] ?? 0.0;

  // --- percakapan di profil ---
  static final ValueNotifier<List<Message>> messages =
      ValueNotifier<List<Message>>([
    Message(
        'kirana_w',
        'Hai kak, mampir yuk ke ceritaku, mana tau kepincut. Vote dan komen jika berkenan ✨\nhttps://www.wattpret.com/story/000000001',
        DateTime(2026, 10, 3)),
    Message('raflisetia',
        'Hai, mampir ke ceritaku ya, makasih!\nhttps://www.wattpret.com/story/000000002',
        DateTime(2026, 9, 21)),
  ]);

  static bool inLibrary(Story s) =>
      library.value.any((x) => x.title == s.title);

  static void _localAdd(Story s) {
    if (!inLibrary(s)) {
      addedOrder[s.title] = _counter++;
      library.value = [...library.value, s];
    }
  }

  static void _localRemove(Story s) {
    library.value = library.value.where((x) => x.title != s.title).toList();
  }

  static void addToLibrary(Story s) {
    _localAdd(s);
    final id = s.id;
    if (id == null) return;
    _bg(() async {
      final now = await Api.toggleLibrary(id);
      if (!now) await Api.toggleLibrary(id);
    });
  }

  static void removeFromLibrary(Story s) {
    _localRemove(s);
    final id = s.id;
    if (id == null) return;
    _bg(() async {
      final now = await Api.toggleLibrary(id);
      if (now) await Api.toggleLibrary(id);
    });
  }

  static void archiveStory(Story s) {
    _localRemove(s);
    if (!archive.value.any((x) => x.title == s.title)) {
      archive.value = [...archive.value, s];
    }
    final id = s.id;
    if (id == null) return;
    _bg(() async {
      final now = await Api.toggleArchive(id);
      if (!now) await Api.toggleArchive(id);
    });
  }

  static void restoreStory(Story s) {
    archive.value = archive.value.where((x) => x.title != s.title).toList();
    _localAdd(s);
    final id = s.id;
    if (id == null) return;
    _bg(() async {
      final now = await Api.toggleArchive(id);
      if (now) await Api.toggleArchive(id);
    });
  }

  /// Koin & status hadiah harian diambil dari server (sumber yang benar).
  static Future<void> _loadCoins() async {
    try {
      final d = await Api.coins();
      coins.value = int.tryParse('${d['coins']}') ?? coins.value;
      dailyClaimed = d['daily_claimed'] == true;
    } catch (_) {}
  }

  static bool claimDaily() {
    if (dailyClaimed) return false;
    dailyClaimed = true;
    coins.value += 10;
    _bg(() async {
      try {
        await Api.claimDaily();
      } on ApiException catch (_) {}
      await _loadCoins();
    });
    return true;
  }

  /// Membeli koin (simulasi): tampil langsung, lalu disimpan ke server.
  static void buyCoins(int n) {
    coins.value += n;
    _bg(() async {
      try {
        await Api.buyCoins(n);
      } catch (_) {}
      await _loadCoins();
    });
  }
}
