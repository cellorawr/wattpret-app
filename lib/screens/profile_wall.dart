import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

/// Pesan di dinding profil ("Percakapan"), tersambung ke server.
/// Dipakai di profil sendiri ([mine] = true) dan profil orang lain.
///
/// Aturan hapus (ditegakkan juga oleh server):
///  - penulis pesan boleh menghapus pesannya,
///  - pemilik profil boleh menghapus pesan apa pun di dindingnya.
class ProfileWall extends StatefulWidget {
  final String username;
  final bool mine;
  const ProfileWall({super.key, required this.username, this.mine = false});

  @override
  State<ProfileWall> createState() => _ProfileWallState();
}

class _ProfileWallState extends State<ProfileWall> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _notFound = false;
  bool _sending = false;

  static const _base =
      TextStyle(fontSize: 17, height: 1.35, color: Color(0xFFDDDDDD));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final d = await Api.messages(widget.username);
      if (!mounted) return;
      setState(() {
        _items = d;
        _error = null;
        _notFound = false;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notFound = e.status == 404;
        _error = e.status == 404 ? null : e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak bisa terhubung ke server.';
        _loading = false;
      });
    }
  }

  void _toast(String t) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(t)));

  String _author(Map<String, dynamic> m) =>
      ((m['author'] as Map?)?['username'] ?? 'pengguna').toString();

  DateTime _date(Map<String, dynamic> m) =>
      DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now();

  bool _canDelete(Map<String, dynamic> m) =>
      widget.mine || _author(m) == AppState.username;

  Future<void> _compose({Map<String, dynamic>? replyTo}) async {
    if (!Api.isLoggedIn) {
      _toast('Masuk dulu untuk menulis pesan');
      return;
    }
    final text = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(
            builder: (_) => WallComposeScreen(
                replyToAuthor: replyTo == null ? null : _author(replyTo))));
    if (text == null || text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await Api.sendMessage(widget.username, text.trim(),
          parentId: replyTo == null ? null : replyTo['id'] as int);
      await _load(silent: true);
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Pesan gagal dikirim');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> m) async {
    try {
      await Api.deleteMessage(m['id'] as int);
      await _load(silent: true);
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Pesan gagal dihapus');
    }
  }

  Widget _avatar(String name, double size) => name == AppState.username
      ? Avatar(size: size)
      : LetterAvatar(name, size: size);

  Widget _reply(Map<String, dynamic> r) {
    final who = _author(r);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 4, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _avatar(who, 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(who,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text(timeAgo(_date(r)),
                  style: const TextStyle(color: C.grey, fontSize: 13)),
            ]),
            Text('${r['body']}', style: _base.copyWith(fontSize: 16)),
          ]),
        ),
        if (_canDelete(r))
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showMessageMenu(context,
                own: true, onDelete: () => _delete(r)),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.more_horiz, color: C.grey, size: 20),
            ),
          ),
      ]),
    );
  }

  Widget _post(Map<String, dynamic> m) {
    final who = _author(m);
    final replies = (m['replies'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
          color: C.bg, border: Border.all(color: const Color(0xFF242424))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _avatar(who, 48),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: who,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            const TextSpan(text: ' memosting pesan'),
                          ]),
                          style: const TextStyle(fontSize: 17)),
                      const SizedBox(height: 2),
                      Text(timeAgo(_date(m)),
                          style: const TextStyle(color: C.grey, fontSize: 15)),
                    ]),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showMessageMenu(context,
                  own: _canDelete(m), onDelete: () => _delete(m)),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.more_horiz, color: C.grey),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Text('${m['body']}', style: _base),
        ),
        for (final r in replies) _reply(r),
        InkWell(
          onTap: () => _compose(replyTo: m),
          child: Container(
            height: 44,
            color: const Color(0xFF2B2B2B),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Row(children: [
              Icon(Icons.reply, size: 22, color: Color(0xFFB0B0B0)),
              SizedBox(width: 12),
              Text('Balas',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB0B0B0))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _info(String text, {bool retry = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(children: [
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.grey, fontSize: 16)),
          if (retry) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      child: Column(children: [
        if (!_notFound)
          InkWell(
            onTap: _sending ? null : _compose,
            child: Container(
              height: 46,
              margin: const EdgeInsets.only(bottom: 13),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF242424))),
              child: Row(children: [
                const Avatar(size: 30),
                const SizedBox(width: 14),
                Text(_sending ? 'Mengirim...' : 'Posting Pesan...',
                    style: const TextStyle(color: C.grey, fontSize: 17)),
              ]),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: C.orange),
          )
        else if (_notFound)
          _info('Profil ini belum terdaftar di server, jadi pesan belum bisa dipakai.')
        else if (_error != null)
          _info(_error!, retry: true)
        else if (_items.isEmpty)
          _info(widget.mine
              ? 'Belum ada pesan di dindingmu.'
              : 'Belum ada pesan. Jadilah yang pertama menulis!')
        else
          for (final m in _items) _post(m),
      ]),
    );
  }
}

/// Layar penuh untuk menulis pesan baru atau balasan. Mengembalikan teks lewat
/// Navigator.pop (null bila dibatalkan).
class WallComposeScreen extends StatefulWidget {
  final String? replyToAuthor;
  const WallComposeScreen({super.key, this.replyToAuthor});

  @override
  State<WallComposeScreen> createState() => _WallComposeScreenState();
}

class _WallComposeScreenState extends State<WallComposeScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = _c.text.trim().isEmpty;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text(widget.replyToAuthor == null
            ? 'Pesan baru'
            : 'Balas ${widget.replyToAuthor}'),
        actions: [
          TextButton(
            onPressed: empty ? null : () => Navigator.pop(context, _c.text),
            child: Text('Kirim',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: empty ? C.grey : C.orange)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _c,
          autofocus: true,
          maxLines: null,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Tulis pesan...',
            hintStyle: TextStyle(color: C.grey),
          ),
        ),
      ),
    );
  }
}
