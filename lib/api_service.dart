import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Klien REST API untuk backend Laravel (wattpret-api).
///
/// Chrome/desktop  : http://127.0.0.1:8000/api
/// Emulator Android: http://10.0.2.2:8000/api   (10.0.2.2 = localhost laptop)
/// HP asli         : ganti [_deviceHost] dengan IP laptop, mis. 192.168.1.10
class Api {
  static const String _deviceHost = '10.0.2.2';
  static String get host => kIsWeb ? '127.0.0.1:8000' : '$_deviceHost:8000';
  static String get base => 'http://$host/api';

  static String? token;

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Panggil sekali di main() sebelum runApp agar login tetap tersimpan.
  static Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
  }

  static Future<void> _saveToken(String? t) async {
    token = t;
    final p = await SharedPreferences.getInstance();
    if (t == null) {
      await p.remove('token');
    } else {
      await p.setString('token', t);
    }
  }

  static dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    String msg = 'Terjadi kesalahan (${r.statusCode})';
    if (body is Map) {
      if (body['errors'] is Map && (body['errors'] as Map).isNotEmpty) {
        msg = (body['errors'] as Map).values.first.first.toString();
      } else if (body['message'] != null) {
        msg = body['message'].toString();
      }
    }
    throw ApiException(msg, r.statusCode);
  }

  static Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse('$base$path').replace(queryParameters: (q == null || q.isEmpty) ? null : q);

  static Future<dynamic> _get(String path, [Map<String, String>? q]) async =>
      _decode(await http.get(_uri(path, q), headers: _headers));

  static Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async =>
      _decode(await http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  static Future<dynamic> _put(String path, [Map<String, dynamic>? body]) async =>
      _decode(await http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  static Future<dynamic> _delete(String path, [Map<String, dynamic>? body]) async =>
      _decode(await http.delete(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  /// Upload gambar (field "image"), mis. dari image_picker: `await xfile.readAsBytes()`.
  static Future<dynamic> _upload(String path, Uint8List bytes,
      {String filename = 'photo.jpg', Map<String, String>? fields}) async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers['Accept'] = 'application/json'
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..fields.addAll(fields ?? {})
      ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    return _decode(await http.Response.fromStream(await req.send()));
  }

  static List<Map<String, dynamic>> _list(dynamic d) =>
      List<Map<String, dynamic>>.from((d as List).map((e) => Map<String, dynamic>.from(e)));

  static Map<String, dynamic> _map(dynamic d) => Map<String, dynamic>.from(d as Map);

  /// Daftar berpaginasi Laravel -> ambil isi "data".
  static List<Map<String, dynamic>> _page(dynamic d) => _list(d['data']);

  // ================================================================ AKUN
  static bool get isLoggedIn => token != null;

  /// Mengembalikan {user, verification_code}. verification_code hanya ada saat APP_DEBUG=true.
  static Future<Map<String, dynamic>> register(String email, String username, String password,
      {List<String>? genres}) async {
    final d = await _post('/register', {
      'email': email,
      'username': username,
      'password': password,
      if (genres != null) 'genres': genres,
    });
    await _saveToken(d['token']);
    return _map(d);
  }

  /// [login] boleh email atau nama pengguna. Mengembalikan user.
  static Future<Map<String, dynamic>> login(String login, String password) async {
    final d = await _post('/login', {'login': login, 'password': password});
    await _saveToken(d['token']);
    return _map(d['user']);
  }

  static Future<void> logout() async {
    try {
      await _post('/logout');
    } finally {
      await _saveToken(null);
    }
  }

  static Future<Map<String, dynamic>> me() async => _map(await _get('/me'));

  static Future<Map<String, dynamic>> updateProfile(
          {String? bio,
          String? username,
          String? email,
          List<String>? genres,
          String? currentPassword}) async =>
      _map(await _put('/me', {
        if (bio != null) 'bio': bio,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (genres != null) 'genres': genres,
        if (currentPassword != null) 'current_password': currentPassword,
      }));

  static Future<void> changePassword(String current, String newPassword) async =>
      _put('/me/password', {'current_password': current, 'password': newPassword});

  /// Mengembalikan debug_code (hanya saat APP_DEBUG=true), selain itu null.
  static Future<String?> forgotPassword(String email) async =>
      (await _post('/forgot-password', {'email': email}))['debug_code']?.toString();

  static Future<void> resetPassword(String email, String code, String newPassword) async =>
      _post('/reset-password', {'email': email, 'code': code, 'password': newPassword});

  static Future<void> verifyEmail(String code) async => _post('/verify-email', {'code': code});

  static Future<String?> resendVerification() async =>
      (await _post('/verify-email/resend'))['verification_code']?.toString();

  static Future<void> deleteAccount(String password) async {
    await _delete('/me', {'password': password});
    await _saveToken(null);
  }

  // Foto profil / sampul profil (bytes dari image_picker)
  static Future<Map<String, dynamic>> uploadAvatar(Uint8List bytes) async => _map(await _upload('/me/avatar', bytes));
  static Future<Map<String, dynamic>> uploadCover(Uint8List bytes) async => _map(await _upload('/me/cover', bytes));
  /// Mengambil foto profil / sampul milik sendiri sebagai bytes (null bila belum ada).
  static Future<Uint8List?> myImage({bool cover = false}) async {
    final r = await http.get(_uri(cover ? '/me/cover' : '/me/avatar'),
        headers: {'Accept': '*/*', if (token != null) 'Authorization': 'Bearer $token'});
    return r.statusCode == 200 ? r.bodyBytes : null;
  }

  static Future<void> deleteAvatar() async => _delete('/me/avatar');
  static Future<void> deleteCover() async => _delete('/me/cover');

  // Pengaturan (JSON bebas: darkMode, blockedTags, reader prefs, dst.)
  static Future<Map<String, dynamic>> settings() async => _map((await _get('/settings'))['data'] ?? {});
  static Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> data) async =>
      _map((await _put('/settings', {'data': data}))['data']);

  // ============================================================ CERITA
  /// Field cerita: id, title, synopsis, category, tags (csv), cover_color, cover_url,
  /// views, votes_count, chapters_count, author{username, avatar_url}.
  static Future<List<Map<String, dynamic>>> stories(
          {String? category, String? q, String? tag, String? author, String? sort, int page = 1}) async =>
      _page(await _get('/stories', {
        if (category != null) 'category': category,
        if (q != null && q.isNotEmpty) 'q': q,
        if (tag != null) 'tag': tag,
        if (author != null) 'author': author,
        if (sort != null) 'sort': sort, // popular | votes
        'page': '$page',
      }));

  static Future<List<Map<String, dynamic>>> ranking({String? category}) async =>
      _list(await _get('/ranking', {if (category != null) 'category': category}));

  static Future<List<Map<String, dynamic>>> categories() async => _list(await _get('/categories'));

  /// type: title | tag | profile. Mengembalikan daftar hasil.
  static Future<List<Map<String, dynamic>>> search(String q, {String type = 'title'}) async =>
      _list((await _get('/search', {'q': q, 'type': type}))['results']);

  /// Detail cerita + daftar bab + {voted, in_library, progress, is_owner}.
  static Future<Map<String, dynamic>> story(int id) async => _map(await _get('/stories/$id'));

  static Future<List<Map<String, dynamic>>> myStories() async => _list(await _get('/my-stories'));

  static Future<Map<String, dynamic>> createStory({
    required String title,
    String? synopsis,
    String? category,
    List<String>? tags,
    List<String>? genres,
    String? lang,
    String? type,
    String? rights,
    bool? mature,
    bool? complete,
    bool published = true,
    Map<String, dynamic>? meta,
  }) async =>
      _map(await _post('/stories', {
        'title': title,
        if (synopsis != null) 'synopsis': synopsis,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
        if (genres != null) 'genres': genres,
        if (lang != null) 'lang': lang,
        if (type != null) 'type': type,
        if (rights != null) 'rights': rights,
        if (mature != null) 'mature': mature,
        if (complete != null) 'complete': complete,
        'published': published,
        if (meta != null) 'meta': meta,
      }));

  static Future<Map<String, dynamic>> updateStory(int id, Map<String, dynamic> fields) async =>
      _map(await _put('/stories/$id', fields));

  static Future<void> deleteStory(int id) async => _delete('/stories/$id');

  static Future<Map<String, dynamic>> uploadStoryCover(int id, Uint8List bytes) async =>
      _map(await _upload('/stories/$id/cover', bytes));

  /// return {voted, votes}
  static Future<Map<String, dynamic>> voteStory(int id) async => _map(await _post('/stories/$id/vote'));

  // ================================================================ BAB
  static Future<Map<String, dynamic>> addChapter(int storyId, String title, String body,
          {bool published = true}) async =>
      _map(await _post('/stories/$storyId/chapters', {'title': title, 'body': body, 'published': published}));

  /// Isi bab + {prev_id, next_id, votes_count, comments_count, voted, media[]}.
  static Future<Map<String, dynamic>> chapter(int id) async => _map(await _get('/chapters/$id'));

  static Future<Map<String, dynamic>> updateChapter(int id, {String? title, String? body, bool? published}) async =>
      _map(await _put('/chapters/$id', {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (published != null) 'published': published,
      }));

  static Future<void> deleteChapter(int id) async => _delete('/chapters/$id');

  static Future<List<Map<String, dynamic>>> chapterRevisions(int id) async => _list(await _get('/chapters/$id/revisions'));

  static Future<Map<String, dynamic>> voteChapter(int id) async => _map(await _post('/chapters/$id/vote'));

  static Future<List<Map<String, dynamic>>> comments(int chapterId, {String? paragraph}) async =>
      _page(await _get('/chapters/$chapterId/comments', {if (paragraph != null) 'paragraph': paragraph}));

  static Future<Map<String, dynamic>> addComment(int chapterId, String body,
          {int? parentId, String? paragraph}) async =>
      _map(await _post('/chapters/$chapterId/comments', {
        'body': body,
        if (parentId != null) 'parent_id': parentId,
        if (paragraph != null) 'paragraph': paragraph,
      }));

  /// Jumlah komentar per paragraf: {"all": 2, "3": 1, ...}
  static Future<Map<String, int>> commentCounts(int chapterId) async {
    final d = await _get('/chapters/$chapterId/comment-counts');
    if (d is! Map) return {};
    return {for (final e in d.entries) e.key.toString(): int.tryParse('${e.value}') ?? 0};
  }

  static Future<void> deleteComment(int id) async => _delete('/comments/$id');

  static Future<Map<String, dynamic>> addChapterImage(int chapterId, Uint8List bytes) async =>
      _map(await _upload('/chapters/$chapterId/media', bytes, fields: {'type': 'image'}));

  static Future<Map<String, dynamic>> addChapterVideo(int chapterId, String url) async =>
      _map(await _post('/chapters/$chapterId/media', {'type': 'video', 'url': url}));

  static Future<void> deleteMedia(int id) async => _delete('/media/$id');

  /// Isi gambar bab dari server (null bila tidak ada).
  static Future<Uint8List?> mediaBytes(int id) async {
    try {
      final r = await http.get(_uri('/media/$id/file'), headers: {'Accept': '*/*'});
      return r.statusCode == 200 ? r.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan urutan bab (daftar id bab sesuai urutan baru).
  static Future<void> reorderChapters(int storyId, List<int> ids) async =>
      _put('/stories/$storyId/chapters/order', {'ids': ids});

  // ======================================================== PERPUSTAKAAN
  /// sort: recent | added | title. Tiap item memuat archived, offline, progress, last_read_at.
  static Future<List<Map<String, dynamic>>> library({bool archived = false, String sort = 'recent'}) async =>
      _list(await _get('/library', {'archived': archived ? '1' : '0', 'sort': sort}));

  /// return true bila sekarang ada di perpustakaan
  static Future<bool> toggleLibrary(int storyId) async => (await _post('/library/$storyId'))['in_library'] == true;
  static Future<bool> toggleArchive(int storyId) async => (await _post('/library/$storyId/archive'))['archived'] == true;
  static Future<bool> toggleOffline(int storyId) async => (await _post('/library/$storyId/offline'))['offline'] == true;

  /// progress 0..1
  static Future<void> setProgress(int storyId, double progress, {int? chapterId}) async =>
      _put('/stories/$storyId/progress', {'progress': progress, if (chapterId != null) 'chapter_id': chapterId});

  static Future<List<Map<String, dynamic>>> allProgress() async => _list(await _get('/progress'));

  static Future<List<Map<String, dynamic>>> updates() async => _list(await _get('/updates'));

  // ======================================================= DAFTAR BACAAN
  static Future<List<Map<String, dynamic>>> myReadingLists() async => _list(await _get('/reading-lists'));

  static Future<List<Map<String, dynamic>>> readingListsOf(String username) async =>
      _list(await _get('/users/$username/reading-lists'));

  static Future<Map<String, dynamic>> readingList(int id) async => _map(await _get('/reading-lists/$id'));

  static Future<Map<String, dynamic>> createReadingList(String name, {bool isPublic = true}) async =>
      _map(await _post('/reading-lists', {'name': name, 'is_public': isPublic}));

  static Future<Map<String, dynamic>> updateReadingList(int id, {String? name, bool? isPublic}) async =>
      _map(await _put('/reading-lists/$id', {
        if (name != null) 'name': name,
        if (isPublic != null) 'is_public': isPublic,
      }));

  static Future<void> deleteReadingList(int id) async => _delete('/reading-lists/$id');

  /// return true bila cerita sekarang ada di daftar
  static Future<bool> toggleStoryInList(int listId, int storyId) async =>
      (await _post('/reading-lists/$listId/stories/$storyId'))['added'] == true;

  static Future<bool> toggleListLike(int listId) async => (await _post('/reading-lists/$listId/like'))['liked'] == true;

  static Future<List<Map<String, dynamic>>> likedLists() async => _list(await _get('/liked-lists'));

  // ============================================================== SOSIAL
  static Future<Map<String, dynamic>> profile(String username) async => _map(await _get('/users/$username'));

  static Future<List<Map<String, dynamic>>> following() async => _list(await _get('/following'));
  static Future<List<Map<String, dynamic>>> followersOf(String username) async => _list(await _get('/users/$username/followers'));
  static Future<List<Map<String, dynamic>>> followingOf(String username) async => _list(await _get('/users/$username/following'));
  static Future<List<Map<String, dynamic>>> suggestions() async => _list(await _get('/users/suggestions'));

  /// return true bila sekarang mengikuti
  static Future<bool> toggleFollow(String username) async => (await _post('/users/$username/follow'))['following'] == true;

  static Future<List<Map<String, dynamic>>> messages(String username) async => _list(await _get('/users/$username/messages'));

  static Future<Map<String, dynamic>> sendMessage(String username, String body, {int? parentId}) async =>
      _map(await _post('/users/$username/messages', {'body': body, if (parentId != null) 'parent_id': parentId}));

  static Future<void> deleteMessage(int id) async => _delete('/messages/$id');

  /// Aktivitas terbaru dari orang yang kuikuti (cerita baru & bab baru).
  static Future<List<Map<String, dynamic>>> feed() async => _list(await _get('/feed'));

  // ========================================================= NOTIFIKASI
  static Future<List<Map<String, dynamic>>> notifications() async => _list(await _get('/notifications'));
  static Future<int> unreadCount() async => (await _get('/notifications/unread-count'))['unread'] as int;
  static Future<void> markAllRead() async => _post('/notifications/read-all');

  // ================================================================ KOIN
  /// {coins, daily_claimed}
  static Future<Map<String, dynamic>> coins() async => _map(await _get('/coins'));

  /// Melempar ApiException(409) bila hari ini sudah diambil.
  static Future<Map<String, dynamic>> claimDaily() async => _map(await _post('/coins/claim-daily'));
  static Future<Map<String, dynamic>> buyCoins(int amount) async => _map(await _post('/coins/purchase', {'amount': amount}));
  static Future<Map<String, dynamic>> spendCoins(int amount) async => _map(await _post('/coins/spend', {'amount': amount}));
}

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}
