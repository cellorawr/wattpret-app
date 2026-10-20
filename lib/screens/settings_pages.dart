import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'camera_capture_screen.dart';

// =============================================================================
// Halaman-halaman pengaturan, bantuan, dan sumber daya penulis.
// Semua tampilan mengikuti screenshot aplikasi asli (tampilan_revisi_wattpad).
// =============================================================================

/// Penyimpanan sederhana (di memori) untuk isian di halaman pengaturan.
class SettingsStore {
  static final ValueNotifier<String> displayName = ValueNotifier('');
  static final ValueNotifier<bool> showDisplayName = ValueNotifier(false);
  static final ValueNotifier<String> location = ValueNotifier('');
  static final ValueNotifier<String> website = ValueNotifier('');
  static final ValueNotifier<String> pronoun = ValueNotifier('Netral');
  static final ValueNotifier<String> storyLang = ValueNotifier('Bahasa Indonesia');
  static final ValueNotifier<String> darkMode = ValueNotifier('Otomatis');
  static final ValueNotifier<bool> adult = ValueNotifier(false);
  static final ValueNotifier<List<String>> blockedTags =
      ValueNotifier<List<String>>([]);
  static final ValueNotifier<DateTime?> birth = ValueNotifier<DateTime?>(null);
  static final ValueNotifier<bool> shake = ValueNotifier(true);
  static final ValueNotifier<bool> helpShake = ValueNotifier(false);
  static final ValueNotifier<bool> facebook = ValueNotifier(false);
  static final Map<String, Set<String>> notif = {};
}

const _grpBg = Color(0xFF1C1C1E);
const _divC = Color(0xFF2E2E2E);
const _grey = Color(0xFF8E8E93);
const _tealSw = Color(0xFF2FA89B);

void _snack(BuildContext c, String t) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t)));

/// Membuka Pusat Bantuan Wattpret di browser / tab baru.
Future<void> _openHelpCenter(BuildContext c) async {
  final uri = Uri.parse('https://support.wattpad.com/hc/id');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && c.mounted) _snack(c, 'Tidak bisa membuka Pusat Bantuan');
}

PreferredSizeWidget _bar(BuildContext c, String t,
        {List<Widget>? actions, bool divider = true}) =>
    AppBar(
      leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.pop(c)),
      title: Text(t,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      actions: actions,
      bottom: divider
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: _divC))
          : null,
    );

Widget _topAction(String t, VoidCallback f) => TextButton(
    onPressed: f,
    child: Text(t,
        style: const TextStyle(
            color: _grey, fontSize: 16, fontWeight: FontWeight.w600)));

Widget _group(List<Widget> rows, {Color bg = _grpBg}) => Container(
      decoration: BoxDecoration(
          color: bg,
          border: const Border.symmetric(
              horizontal: BorderSide(color: _divC))),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 14, color: _divC),
          rows[i],
        ],
      ]),
    );

Widget _navRow(String t,
        {String? value,
        VoidCallback? onTap,
        Color? color,
        bool chevron = true}) =>
    InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(children: [
          if (value == null)
            Expanded(
                child: Text(t, style: TextStyle(fontSize: 17, color: color)))
          else ...[
            Text(t, style: TextStyle(fontSize: 17, color: color)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 16, color: _grey))),
          ],
          if (chevron) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 26, color: _grey),
          ],
        ]),
      ),
    );

Widget _sw(bool v, ValueChanged<bool> f,
        {Color active = const Color(0xFFE8703A)}) =>
    Switch(
      value: v,
      onChanged: f,
      activeColor: Colors.white,
      activeTrackColor: active,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFF3A3A3C),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );

Widget _swRow(String t, bool v, ValueChanged<bool> f,
        {Color active = const Color(0xFFE8703A)}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(children: [
        Expanded(child: Text(t, style: const TextStyle(fontSize: 17))),
        _sw(v, f, active: active),
      ]),
    );

Widget _field(TextEditingController c, String hint,
        {bool obscure = false,
        bool autofocus = false,
        TextInputType? type,
        ValueChanged<String>? onChanged}) =>
    TextField(
      controller: c,
      obscureText: obscure,
      autofocus: autofocus,
      keyboardType: type,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5C5C60), fontSize: 17),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      ),
    );

Widget _forgot(BuildContext c) => Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(c).push(MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen())),
          child: const Text('Lupa kata sandi?',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBDBDBD))),
        ),
      ),
    );

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

// ------------------------------ Lembar foto ---------------------------------
/// Ambil gambar dari kamera / galeri lalu pasang sebagai foto profil atau
/// gambar latar (tampil di halaman profil dan semua avatar).
Future<void> _pickPhoto(BuildContext c, ImageSource src,
    {required bool cover}) async {
  try {
    Uint8List? bytes;
    final desktopOrWeb = kIsWeb ||
        const {TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macOS}
            .contains(defaultTargetPlatform);
    if (src == ImageSource.camera && desktopOrWeb) {
      // image_picker di web/desktop hanya membuka pemilih berkas, jadi pakai
      // layar kamera langsung agar benar-benar masuk ke kamera.
      bytes = await Navigator.of(c, rootNavigator: true).push<Uint8List>(
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const CameraCaptureScreen()));
    } else {
      final x = await ImagePicker().pickImage(
          source: src,
          preferredCameraDevice: CameraDevice.front,
          maxWidth: cover ? 1600 : 900,
          maxHeight: cover ? 1600 : 900,
          imageQuality: 88);
      bytes = await x?.readAsBytes();
    }
    if (bytes == null) return; // dibatalkan
    if (cover) {
      AppState.coverBytes.value = bytes;
    } else {
      AppState.avatarBytes.value = bytes;
    }
    if (c.mounted) {
      _snack(c, cover ? 'Gambar latar diperbarui' : 'Foto profil diperbarui');
    }
  } catch (_) {
    if (c.mounted) {
      _snack(
          c,
          src == ImageSource.camera
              ? 'Tidak bisa membuka kamera. Periksa izin kamera.'
              : 'Tidak bisa membuka galeri. Periksa izin foto.');
    }
  }
}

void showPhotoSheet(BuildContext c, {bool cover = false}) {
  Widget btn(BuildContext ctx, String t, ImageSource src) => InkWell(
        onTap: () {
          Navigator.pop(ctx);
          _pickPhoto(c, src, cover: cover);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          child: Text(t,
              style: const TextStyle(fontSize: 20, color: C.iosBlue)),
        ),
      );
  showModalBottomSheet<void>(
    context: c,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: const Color(0xFF262628),
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              btn(ctx, 'Mengambil Foto', ImageSource.camera),
              const Divider(height: 1, color: _divC),
              btn(ctx, 'Pilih yang sudah ada', ImageSource.gallery),
              if ((cover ? AppState.coverBytes : AppState.avatarBytes).value !=
                  null) ...[
                const Divider(height: 1, color: _divC),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    (cover ? AppState.coverBytes : AppState.avatarBytes).value =
                        null;
                    _snack(c, 'Dikembalikan ke bawaan');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    child: const Text('Hapus foto',
                        style: TextStyle(fontSize: 20, color: C.red)),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                  color: const Color(0xFF262628),
                  borderRadius: BorderRadius.circular(14)),
              child: const Text('Batal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: C.iosBlue)),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ================================== PROFIL ===================================
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  void _push(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  // Ukuran mengikuti contoh: baris setinggi 44, teks ~17, foto kecil 30.
  static const double _rowH = 44;
  static const _label = TextStyle(fontSize: 19, color: Color(0xFFEDEDED));
  static const _value = TextStyle(fontSize: 19, color: _grey);

  Widget _row(String label, {String? value, VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _rowH,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text(label, style: _label),
              if (value != null) ...[
                const SizedBox(width: 14),
                Expanded(
                    child: Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: _value)),
              ],
            ]),
          ),
        ),
      );

  Widget _photoRow(Widget thumb, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _rowH,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(children: [
              thumb,
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Profil'),
      body: ListView(padding: EdgeInsets.zero, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 30, 16, 9),
          child: Text.rich(TextSpan(
              style: const TextStyle(
                  fontSize: 17, height: 1.4, color: Color(0xFFDDDDDD)),
              children: [
                const TextSpan(
                    text:
                        'Informasi yang kamu masukkan di sini akan terlihat oleh pengguna lain. Pelajari lebih lanjut tentang berbagi informasi dengan aman '),
                TextSpan(
                    text: 'di sini',
                    style: const TextStyle(
                        color: Color(0xFF9B8CE0),
                        decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _snack(context,
                          'Bagikan informasi pribadi seperlunya saja')),
                const TextSpan(text: '.'),
              ])),
        ),
        _group([
          _photoRow(const Avatar(size: 30), 'Perbarui foto',
              () => showPhotoSheet(context)),
          ValueListenableBuilder(
            valueListenable: AppState.coverBytes,
            builder: (_, bytes, __) => _photoRow(
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: bytes != null
                      ? LightCounter(
                          child: Image.memory(bytes,
                              width: 30, height: 30, fit: BoxFit.cover))
                      : Container(
                          width: 30, height: 30, color: const Color(0xFF4F6B4A)),
                ),
                'Atur Gambar Latar Belakang',
                () => showPhotoSheet(context, cover: true)),
          ),
        ]),
        const SizedBox(height: 35),
        _group([
          // Nama Tampilan: hanya bisa diisi bila tombol di bawahnya menyala.
          // Bila mati, labelnya redup dan nama tidak ditampilkan.
          ListenableBuilder(
            listenable: Listenable.merge(
                [SettingsStore.showDisplayName, SettingsStore.displayName]),
            builder: (_, __) {
              final on = SettingsStore.showDisplayName.value;
              return InkWell(
                onTap: on
                    ? () => _push(
                        context,
                        TextEditScreen(
                            title: 'Nama Tampilan',
                            initial: SettingsStore.displayName.value,
                            onSave: (t) => SettingsStore.displayName.value = t))
                    : null,
                child: SizedBox(
                  height: _rowH,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Text('Nama Tampilan',
                          style: on
                              ? _label
                              : _label.copyWith(color: const Color(0xFF555558))),
                      if (on) ...[
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(SettingsStore.displayName.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: _value)),
                      ],
                    ]),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: SettingsStore.showDisplayName,
            builder: (_, v, __) => SizedBox(
              height: _rowH,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Row(children: [
                  const Expanded(
                      child: Text('Tunjukkan Nama Tampilan', style: _label)),
                  _sw(v, (x) => SettingsStore.showDisplayName.value = x,
                      active: _tealSw),
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 35),
        _group([
          _row('Lokasi',
              value: SettingsStore.location.value,
              onTap: () => _push(
                  context,
                  TextEditScreen(
                      title: 'Lokasi',
                      initial: SettingsStore.location.value,
                      onSave: (t) => SettingsStore.location.value = t))),
          _row('Bio',
              value: AppState.bio.value,
              onTap: () => _push(
                  context,
                  TextEditScreen(
                      title: 'Bio',
                      initial: AppState.bio.value,
                      multiline: true,
                      onSave: (t) => AppState.bio.value = t))),
          ValueListenableBuilder<String>(
            valueListenable: SettingsStore.pronoun,
            builder: (_, v, __) => _row('Kata Ganti',
                value: v,
                onTap: () => _push(context, const PronounScreen())),
          ),
          _row('Situs Web Pribadi',
              value: SettingsStore.website.value,
              onTap: () => _push(
                  context,
                  TextEditScreen(
                      title: 'Situs Web Pribadi',
                      initial: SettingsStore.website.value,
                      onSave: (t) => SettingsStore.website.value = t))),
        ]),
      ]),
    );
  }
}

class TextEditScreen extends StatefulWidget {
  final String title, initial;
  final bool multiline;
  final ValueChanged<String> onSave;
  const TextEditScreen(
      {super.key,
      required this.title,
      required this.initial,
      required this.onSave,
      this.multiline = false});
  @override
  State<TextEditScreen> createState() => _TextEditScreenState();
}

class _TextEditScreenState extends State<TextEditScreen> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, widget.title, actions: [
        _topAction('Simpan', () {
          widget.onSave(_c.text.trim());
          Navigator.pop(context);
        }),
      ]),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: TextField(
          controller: _c,
          autofocus: true,
          maxLines: widget.multiline ? null : 1,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }
}

class PronounScreen extends StatelessWidget {
  const PronounScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Ubah Kata Ganti'),
      body: ValueListenableBuilder<String>(
        valueListenable: SettingsStore.pronoun,
        builder: (_, cur, __) => ListView(children: [
          const SizedBox(height: 26),
          _group([
            for (final p in const ['Laki-laki', 'Perempuan', 'Netral'])
              InkWell(
                onTap: () => SettingsStore.pronoun.value = p,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  child: Row(children: [
                    Expanded(
                        child: Text(p,
                            style: TextStyle(
                                fontSize: 17,
                                color: p == cur
                                    ? C.orange
                                    : const Color(0xFFBDBDBD)))),
                    if (p == cur)
                      const Icon(Icons.check_circle_outline,
                          color: C.orange, size: 28),
                  ]),
                ),
              ),
          ], bg: C.bg),
        ]),
      ),
    );
  }
}

// ================================== AKUN =====================================
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _push(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  String _birth(DateTime? d) =>
      d == null ? 'Belum diatur' : '${d.day} ${_months[d.month - 1]} ${d.year}';

  void _close(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: const Text('Tutup Akun'),
        content: const Text(
            'Menutup akun akan menghapus profil dan ceritamu. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _snack(context, 'Fitur tutup akun belum tersedia di versi demo');
              },
              child: const Text('Tutup Akun', style: TextStyle(color: C.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Akun'),
      body: ListenableBuilder(
        listenable: Listenable.merge(
            [SettingsStore.birth, SettingsStore.storyLang]),
        builder: (_, __) => ListView(padding: EdgeInsets.zero, children: [
          const SizedBox(height: 26),
          _group([
            _navRow('Nama Pengguna',
                value: AppState.username,
                onTap: () => _push(context, const ChangeUsernameScreen())),
            _navRow('Email',
                value: AppState.email,
                onTap: () => _push(context, const ChangeEmailScreen())),
            _navRow('Kata Sandi',
                value: '• • • • • • •',
                onTap: () => _push(context, const ChangePasswordScreen())),
          ]),
          const SizedBox(height: 30),
          _group([
            _navRow('Tanggal Lahir',
                value: _birth(SettingsStore.birth.value),
                onTap: () => _push(context, const BirthdayScreen())),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 30, 14, 10),
            child: Text('PREFERENSI CERITA',
                style: TextStyle(color: _grey, fontSize: 14)),
          ),
          _group([
            _navRow('Pengaturan Bacaan',
                onTap: () => _push(context, const ReadingPrefsScreen())),
            _navRow('Bahasa cerita',
                value: SettingsStore.storyLang.value,
                onTap: () => _push(context, const StoryLanguageScreen())),
          ]),
          const SizedBox(height: 30),
          _group([
            _navRow('Tutup Akun',
                color: const Color(0xFFE5779A),
                chevron: false,
                onTap: () => _close(context)),
          ]),
        ]),
      ),
    );
  }
}

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});
  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameState();
}

class _ChangeUsernameState extends State<ChangeUsernameScreen> {
  final _n = TextEditingController();
  final _p = TextEditingController();

  @override
  void dispose() {
    _n.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final u = _n.text.trim();
    if (u.length < 2 || !RegExp(r'^[A-Za-z0-9_]+$').hasMatch(u)) {
      _snack(context, 'Nama pengguna hanya huruf, angka, dan garis bawah (min. 2)');
      return;
    }
    if (_p.text.isEmpty) {
      _snack(context, 'Masukkan kata sandimu saat ini');
      return;
    }
    if (Api.isLoggedIn) {
      try {
        await Api.updateProfile(username: u, currentPassword: _p.text);
      } on ApiException catch (e) {
        if (mounted) _snack(context, e.message);
        return;
      } catch (_) {
        if (mounted) _snack(context, 'Tidak bisa terhubung ke server');
        return;
      }
    }
    AppState.username = u;
    if (!mounted) return;
    Navigator.pop(context);
    _snack(context, 'Nama pengguna diperbarui');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Ubah Nama Pengguna',
          actions: [_topAction('Selesai', _done)]),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 26),
        _group([
          _field(_n, 'Nama Pengguna Baru', autofocus: true),
          _field(_p, 'Kata Sandi Saat Ini', obscure: true),
        ]),
        _forgot(context),
      ]),
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});
  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailState();
}

class _ChangeEmailState extends State<ChangeEmailScreen> {
  final _e1 = TextEditingController();
  final _e2 = TextEditingController();
  final _p = TextEditingController();

  @override
  void dispose() {
    _e1.dispose();
    _e2.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final e = _e1.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      _snack(context, 'Format email belum benar');
      return;
    }
    if (e != _e2.text.trim()) {
      _snack(context, 'Konfirmasi email tidak cocok');
      return;
    }
    if (_p.text.isEmpty) {
      _snack(context, 'Masukkan kata sandimu saat ini');
      return;
    }
    if (Api.isLoggedIn) {
      try {
        await Api.updateProfile(email: e, currentPassword: _p.text);
      } on ApiException catch (err) {
        if (mounted) _snack(context, err.message);
        return;
      } catch (_) {
        if (mounted) _snack(context, 'Tidak bisa terhubung ke server');
        return;
      }
    }
    AppState.email = e;
    if (!mounted) return;
    Navigator.pop(context);
    _snack(context, 'Email diperbarui');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Ubah Email', actions: [_topAction('Selesai', _done)]),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 26),
        _group([
          _field(_e1, 'Email Baru',
              autofocus: true, type: TextInputType.emailAddress),
          _field(_e2, 'Konfirmasi Email Baru', type: TextInputType.emailAddress),
        ]),
        const SizedBox(height: 28),
        _group([_field(_p, 'Kata Sandi Saat Ini', obscure: true)]),
        _forgot(context),
      ]),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePasswordScreen> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _conf = TextEditingController();
  bool _hCur = true, _hNew = true, _hConf = true;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _conf.dispose();
    super.dispose();
  }

  bool get _valid {
    final p = _new.text;
    final u = AppState.username.toLowerCase();
    return RegExp(r'\d').hasMatch(p) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(p) &&
        RegExp(r'[a-z]').hasMatch(p) &&
        RegExp(r'[A-Z]').hasMatch(p) &&
        p.length >= 10 &&
        (u.isEmpty || !p.toLowerCase().contains(u));
  }

  void _done() {
    if (_cur.text.isEmpty) {
      _snack(context, 'Masukkan kata sandimu saat ini');
      return;
    }
    if (!_valid) {
      _snack(context, 'Kata sandi baru belum memenuhi persyaratan');
      return;
    }
    if (_new.text != _conf.text) {
      _snack(context, 'Konfirmasi kata sandi tidak cocok');
      return;
    }
    Navigator.pop(context);
    _snack(context, 'Kata sandi diperbarui');
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 26, 14, 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, color: _grey)),
      );

  Widget _pw(TextEditingController c, String hint, bool hidden,
          VoidCallback toggle) =>
      Row(children: [
        Expanded(
            child: _field(c, hint,
                obscure: hidden, onChanged: (_) => setState(() {}))),
        GestureDetector(
          onTap: toggle,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(hidden ? 'Tampilkan' : 'Sembunyikan',
                style: const TextStyle(fontSize: 15, color: Color(0xFFDDDDDD))),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Ubah Kata Sandi',
          actions: [_topAction('Selesai', _done)]),
      body: ListView(padding: EdgeInsets.zero, children: [
        _label('Kata Sandi Saat Ini'),
        _group([
          _pw(_cur, 'Kata Sandi Saat Ini', _hCur, () => setState(() => _hCur = !_hCur))
        ]),
        _label('Kata Sandi Baru'),
        _group([
          _pw(_new, 'Kata sandi baru', _hNew, () => setState(() => _hNew = !_hNew)),
          if (_new.text.isNotEmpty && !_valid)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                  'Kata sandi tidak memenuhi persyaratan.\n\nPersyaratan kata sandi:\n• Harus berisi angka, karakter khusus, serta huruf kecil dan huruf besar\n• Harus memiliki panjang minimal 10 karakter\n• Tidak boleh berisi nama pengguna, atau nama tampilan kamu',
                  style: TextStyle(fontSize: 16, height: 1.45)),
            ),
        ]),
        _label('Konfirmasi Kata Sandi'),
        _group([
          _pw(_conf, 'Konfirmasi Kata Sandi', _hConf,
              () => setState(() => _hConf = !_hConf))
        ]),
        _forgot(context),
      ]),
    );
  }
}

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});
  @override
  State<BirthdayScreen> createState() => _BirthdayState();
}

class _BirthdayState extends State<BirthdayScreen> {
  late final _mm = TextEditingController(
      text: SettingsStore.birth.value == null
          ? ''
          : SettingsStore.birth.value!.month.toString().padLeft(2, '0'));
  late final _dd = TextEditingController(
      text: SettingsStore.birth.value == null
          ? ''
          : SettingsStore.birth.value!.day.toString().padLeft(2, '0'));
  late final _yy = TextEditingController(
      text: SettingsStore.birth.value == null
          ? ''
          : SettingsStore.birth.value!.year.toString());

  @override
  void dispose() {
    _mm.dispose();
    _dd.dispose();
    _yy.dispose();
    super.dispose();
  }

  void _changed(String _) {
    final m = int.tryParse(_mm.text), d = int.tryParse(_dd.text);
    final y = int.tryParse(_yy.text);
    if (m == null || d == null || y == null || _yy.text.length != 4) return;
    if (m < 1 || m > 12 || d < 1 || d > 31) return;
    final dt = DateTime(y, m, d);
    if (dt.month != m || dt.isAfter(DateTime.now())) return;
    SettingsStore.birth.value = dt;
  }

  Widget _box(String label, TextEditingController c, int max) => Expanded(
        child: TextField(
          controller: c,
          onChanged: _changed,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(max)
          ],
          style: const TextStyle(fontSize: 21, color: Color(0xFFBDBDBD)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _grey),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: const BorderSide(color: Color(0xFF9A9A9E))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: const BorderSide(color: Colors.white)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Atur tanggal lahir'),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const SizedBox(height: 8),
        const Text(
            'Informasi ini hanya akan dapat dilihat oleh kamu dan Tim Pendukung Wattpret.',
            style: TextStyle(fontSize: 16, height: 1.4, color: Color(0xFFBDBDBD))),
        const SizedBox(height: 26),
        const Row(children: [
          Text('Tanggal Lahir', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Icon(Icons.lock_outline, size: 22),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _box('MM', _mm, 2),
          const SizedBox(width: 12),
          _box('DD', _dd, 2),
          const SizedBox(width: 12),
          _box('YYYY', _yy, 4),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(
              child: Text('Perlu bantuan dengan tanggal lahir kamu?',
                  style: TextStyle(fontSize: 16, height: 1.3))),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _openHelpCenter(context),
              child: const Text('Kunjungi Pusat Bantuan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ======================== PREFERENSI MEMBACA (PENGATURAN BACAAN) ==============
class ReadingPrefsScreen extends StatelessWidget {
  const ReadingPrefsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AppState.reader;
    return Scaffold(
      appBar: _bar(context, 'Preferensi Membaca'),
      body: ListenableBuilder(
        listenable: p,
        builder: (_, __) => ListView(padding: EdgeInsets.zero, children: [
          const SizedBox(height: 26),
          _group([
            _swRow('Kunci Orientasi Layar', p.lockOrientation,
                (v) => p.update(() => p.lockOrientation = v)),
            _swRow('Komentar dalam Paragraf dan Reaksi', p.commentsOn,
                (v) => p.update(() => p.commentsOn = v)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(children: [
                const Expanded(
                    child: Text('Mode Baca', style: TextStyle(fontSize: 17))),
                SizedBox(
                  width: 200,
                  child: Segmented(
                    labels: const ['Halaman', 'Gulir'],
                    index: p.scrollMode ? 1 : 0,
                    onChanged: (i) => p.update(() => p.scrollMode = i == 1),
                    bg: const Color(0xFF2C2C2E),
                    selBg: const Color(0xFF6B6B70),
                    height: 38,
                    fontSize: 15,
                  ),
                ),
              ]),
            ),
            _swRow('Gulir Otomatis', p.autoScroll,
                (v) => p.update(() => p.autoScroll = v)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(children: [
                const Text('🐢', style: TextStyle(fontSize: 22)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: const Color(0xFF8A4B2E),
                      inactiveTrackColor: const Color(0xFF2E2E30),
                      thumbColor: const Color(0xFF8E8E93),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                        value: p.speed,
                        onChanged: (v) => p.update(() => p.speed = v)),
                  ),
                ),
                const Text('🐇', style: TextStyle(fontSize: 22)),
              ]),
            ),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
                'Gulir: baca dengan menggulir ke bawah. Halaman: geser seperti buku. Gulir Otomatis menggulir sendiri sesuai kecepatan yang kamu atur.',
                style: TextStyle(fontSize: 13, height: 1.4, color: _grey)),
          ),
          const SizedBox(height: 18),
          _group([
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text('Preferensi Lewati Iklan',
                          style: TextStyle(fontSize: 17)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('BARU',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    const Text(
                        'Jika diaktifkan, kamu bisa mendapatkan Lewati Iklan di antara bab cerita saat kamu membaca',
                        style: TextStyle(
                            fontSize: 14, height: 1.35, color: _grey)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _snack(context,
                          'Lewati Iklan membuatmu bebas iklan sementara di antara bab'),
                      child: const Text('Info selengkapnya',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ),
                _sw(p.skipAds, (v) => p.update(() => p.skipAds = v)),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ================================ BAHASA CERITA ==============================
class StoryLanguageScreen extends StatelessWidget {
  const StoryLanguageScreen({super.key});

  static const _langs = [
    'Polski', 'العربية', 'Deutsch', 'English', 'Español', 'Français',
    'Bahasa Indonesia', 'Italiano', 'Bahasa Melayu', 'Português', 'Filipino',
    'Türkçe', 'Русский',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Bahasa cerita'),
      body: ValueListenableBuilder<String>(
        valueListenable: SettingsStore.storyLang,
        builder: (_, cur, __) => ListView(padding: EdgeInsets.zero, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Text.rich(TextSpan(
                style: TextStyle(
                    fontSize: 16, height: 1.45, color: Color(0xFFBDBDBD)),
                children: [
                  TextSpan(
                      text:
                          'Atur bahasa cerita pilihanmu untuk mempersonalisasi cerita di Beranda, Penelusuran, dan Rekomendasi.\n\nCatatan: Ini tidak akan mengubah bahasa aplikasi. Untuk melakukannya, perbarui '),
                  TextSpan(
                      text: 'pengaturan bahasa perangkat',
                      style: TextStyle(
                          color: C.teal, fontWeight: FontWeight.w800)),
                  TextSpan(text: '.'),
                ])),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
            color: Colors.black,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  border: Border.all(color: _divC),
                  borderRadius: BorderRadius.circular(8)),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, size: 26),
                SizedBox(width: 14),
                Expanded(
                  child: Text.rich(TextSpan(
                      style: TextStyle(fontSize: 16, height: 1.35),
                      children: [
                        TextSpan(
                            text:
                                'Beberapa bahasa mungkin tidak lagi tersedia atau sudah tidak didukung. '),
                        TextSpan(
                            text: 'Info selengkapnya',
                            style: TextStyle(
                                color: C.teal, fontWeight: FontWeight.w800)),
                      ])),
                ),
              ]),
            ),
          ),
          for (final l in _langs)
            InkWell(
              onTap: () => SettingsStore.storyLang.value = l,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _divC))),
                child: Row(children: [
                  SizedBox(
                      width: 56,
                      child: l == cur
                          ? const Icon(Icons.check, color: C.teal, size: 24)
                          : null),
                  Text(l, style: const TextStyle(fontSize: 17)),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

// ================================== NOTIFIKASI ===============================
const _notifData = <String, List<List<String>>>{
  'PEMBARUAN & REKOMENDASI CERITA': [
    ['Publikasi bab', 'Push', 'Umpan'],
    ['Cerita dipublikasikan', 'Push', 'Umpan'],
    ['Rekomendasi cerita', 'Push', 'Umpan', 'Email'],
  ],
  'KOMENTAR & PESAN': [
    ['Balasan komentar', 'Push', 'Umpan'],
    ['Komentar suka', 'Push', 'Umpan'],
    ['Balasan percakapan', 'Push', 'Umpan', 'Email'],
    ['Pesan langsung', 'Push', 'Email'],
    ['Disebutkan dalam cerita', 'Umpan', 'Email'],
  ],
  'KOIN & LANGGANAN': [
    ['Kedaluwarsa koin', 'Push', 'Umpan'],
    ['Koin ditambahkan', 'Push', 'Umpan'],
    ['Langganan', 'Push', 'Umpan', 'Email'],
    ['Premium Picks', 'Push', 'Umpan'],
  ],
  'PROMOSI & PENAWARAN': [
    ['Promosi langganan', 'Push', 'Umpan', 'Email'],
    ['Promosi koin', 'Push', 'Umpan', 'Email'],
    ['Promosi cerita', 'Push', 'Umpan', 'Email'],
  ],
  'PEMBERITAHUAN PENULIS': [
    ['Komentar cerita', 'Push', 'Umpan'],
    ['Vote cerita', 'Push', 'Umpan'],
    ['Cerita ditambahkan ke daftar', 'Umpan'],
    ['Pengikut baru', 'Push', 'Umpan'],
    ['Penjadwal publikasi', 'Push'],
  ],
  'DARI WATTPRET': [
    ['Pengingat membaca', 'Push', 'Umpan', 'Email'],
    ['Kiat dan trik', 'Push', 'Umpan', 'Email'],
    ['Acara dan berita', 'Push', 'Umpan', 'Email'],
    ['Umpan Balik', 'Push', 'Umpan', 'Email'],
  ],
};

Set<String> _notifOf(String title) {
  var s = SettingsStore.notif[title];
  if (s == null) {
    for (final items in _notifData.values) {
      for (final it in items) {
        if (it[0] == title) s = it.sublist(1).toSet();
      }
    }
    SettingsStore.notif[title] = s ?? <String>{};
  }
  return SettingsStore.notif[title]!;
}

String _chanText(Set<String> s) {
  if (s.isEmpty) return 'Nonaktif';
  final l = ['Push', 'Umpan', 'Email'].where(s.contains).toList();
  return l.length == 1 ? 'Hanya ${l.first}' : l.join(', ');
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotifSettingsState();
}

class _NotifSettingsState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Notifikasi'),
      body: Scrollbar(
        child: ListView(padding: EdgeInsets.zero, children: [
          for (final e in _notifData.entries) ...[
            Container(
              width: double.infinity,
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.fromLTRB(18, 26, 18, 12),
              child: Text(e.key,
                  style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
            for (final it in e.value)
              InkWell(
                onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => NotificationDetailScreen(it[0])))
                    .then((_) => setState(() {})),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it[0], style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(_chanText(_notifOf(it[0])),
                                style: const TextStyle(
                                    fontSize: 13, color: _grey)),
                          ]),
                    ),
                    const Icon(Icons.chevron_right, size: 28, color: _grey),
                  ]),
                ),
              ),
          ],
          Container(height: 30, color: const Color(0xFF1E1E1E)),
        ]),
      ),
    );
  }
}

class NotificationDetailScreen extends StatefulWidget {
  final String title;
  const NotificationDetailScreen(this.title, {super.key});
  @override
  State<NotificationDetailScreen> createState() => _NotifDetailState();
}

class _NotifDetailState extends State<NotificationDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final s = _notifOf(widget.title);
    return Scaffold(
      appBar: _bar(context, widget.title),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 26),
        _group([
          for (final ch in const ['Push', 'Umpan', 'Email'])
            _swRow(ch, s.contains(ch),
                (v) => setState(() => v ? s.add(ch) : s.remove(ch))),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Text(
              'Pilih cara kamu ingin menerima pemberitahuan ini: notifikasi push, umpan di aplikasi, atau email.',
              style: TextStyle(fontSize: 13, height: 1.4, color: _grey)),
        ),
      ]),
    );
  }
}

// ================================== MODE GELAP ===============================
class DarkModeScreen extends StatelessWidget {
  const DarkModeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _bar(context, 'Mode gelap'),
      body: ValueListenableBuilder<String>(
        valueListenable: SettingsStore.darkMode,
        builder: (_, cur, __) => ListView(padding: EdgeInsets.zero, children: [
          const SizedBox(height: 26),
          _group([
            for (final m in const ['Nonaktif', 'Aktif', 'Otomatis'])
              InkWell(
                onTap: () => SettingsStore.darkMode.value = m,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  child: Row(children: [
                    Expanded(child: Text(m, style: const TextStyle(fontSize: 17))),
                    if (m == cur)
                      const Icon(Icons.check, color: Color(0xFF2FA89B), size: 20),
                  ]),
                ),
              ),
          ], bg: C.bg),
        ]),
      ),
    );
  }
}

// ============================= PREFERENSI KONTEN =============================
class ContentPrefsScreen extends StatelessWidget {
  const ContentPrefsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Preferensi konten'),
      body: ListView(padding: EdgeInsets.zero, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 8, 18),
          child: ValueListenableBuilder<bool>(
            valueListenable: SettingsStore.adult,
            builder: (_, v, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Konten Dewasa',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          const Text(
                              'Cerita dewasa mungkin mengandung konten eksplisit dan tema dewasa. Jika diaktifkan, konten dewasa dapat muncul di seluruh pengalaman Wattpret kamu.',
                              style: TextStyle(
                                  fontSize: 15, height: 1.4, color: _grey)),
                        ]),
                  ),
                  const SizedBox(width: 10),
                  _sw(v, (x) => SettingsStore.adult.value = x, active: _tealSw),
                ]),
          ),
        ),
        const Divider(height: 1, indent: 14, color: _divC),
        InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BlockedTagsScreen())),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(14, 20, 14, 20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tagar yang Diblokir',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text(
                      'Kami akan menghapus semua cerita yang memiliki tagar berikut dari rekomendasi di Halaman Utama kamu.',
                      style: TextStyle(fontSize: 15, height: 1.4, color: _grey)),
                ]),
              ),
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.chevron_right, color: Color(0xFF4A4A4C)),
              ),
            ]),
          ),
        ),
        const Divider(height: 1, indent: 14, color: _divC),
      ]),
    );
  }
}

class BlockedTagsScreen extends StatefulWidget {
  const BlockedTagsScreen({super.key});
  @override
  State<BlockedTagsScreen> createState() => _BlockedTagsState();
}

class _BlockedTagsState extends State<BlockedTagsScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add(String v) {
    final t = v.trim().replaceAll('#', '').toLowerCase();
    if (t.isEmpty) return;
    final l = SettingsStore.blockedTags.value;
    if (!l.contains(t)) SettingsStore.blockedTags.value = [...l, t];
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Tagar yang Diblokir'),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: SettingsStore.blockedTags,
        builder: (_, tags, __) => ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            children: [
              TextField(
                controller: _c,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: _add,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                    hintText: 'Tambah Tag',
                    hintStyle: TextStyle(color: _grey),
                    border: InputBorder.none),
              ),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in tags)
                  Chip(
                    label: Text(t),
                    backgroundColor: C.chip,
                    side: BorderSide.none,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => SettingsStore.blockedTags.value =
                        tags.where((x) => x != t).toList(),
                  ),
              ]),
            ]),
      ),
    );
  }
}

// ======================= AKUN DISENYAPKAN / DIBLOKIR =========================
class EmptyUsersScreen extends StatelessWidget {
  final String title, headline, body;
  const EmptyUsersScreen(this.title, this.headline, this.body, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, title),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
          child: Column(children: [
            Text(headline,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                  style:
                      const TextStyle(fontSize: 16, height: 1.45, color: _grey),
                  children: [
                    TextSpan(text: '$body '),
                    TextSpan(
                        text: 'Info selengkapnya',
                        style: const TextStyle(
                            color: C.orange,
                            decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _openHelpCenter(context)),
                  ]),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ]),
    );
  }
}

// ================================= PREMIUM ===================================
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumState();
}

class _PremiumState extends State<PremiumScreen> {
  int _tab = 0;
  int _plan = 1;

  // [nama, keterangan, harga, per bulan, teks "per periode" di bawah]
  static const _plansBasic = [
    ['Bulanan', 'Otomatis diperbarui dan ditagih bulanan', 'Rp45.000', '', 'bulan'],
    ['Tahunan', 'Otomatis diperbarui dan ditagih tahunan', 'Rp450.000', '(Rp37.500/bulan)', 'tahun'],
    ['Semi-Tahunan', 'Otomatis diperbarui dan ditagih semi-tahunan', 'Rp260.000', '(Rp43.333/bulan)', '6 bulan'],
  ];
  static const _plansPlus = [
    ['Bulanan', 'Otomatis diperbarui dan ditagih bulanan', 'Rp129.000', '', 'bulan'],
    ['Tahunan', 'Otomatis diperbarui dan ditagih tahunan', 'Rp1.169.000', '(Rp97.416,67/bulan)', 'tahun'],
    ['Semi-Tahunan', 'Otomatis diperbarui dan ditagih semi-tahunan', 'Rp770.000', '(Rp128.333/bulan)', '6 bulan'],
  ];
  List<List<String>> get _plans => _tab == 1 ? _plansPlus : _plansBasic;

  Widget _tabBtn(String t, int i) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _tab = i),
          child: Column(children: [
            Text(t,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: i == _tab ? Colors.white : Colors.white70)),
            const SizedBox(height: 8),
            Container(
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: i == _tab ? Colors.white : const Color(0xFF9DAAF5)),
          ]),
        ),
      );

  Widget _check(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check, size: 24, color: Colors.white70),
          const SizedBox(width: 14),
          Expanded(
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 16, height: 1.2, fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _planCard(int i) {
    final p = _plans[i];
    final sel = i == _plan;
    final fg = sel ? const Color(0xFF2A2A5A) : Colors.white;
    return GestureDetector(
      onTap: () => setState(() => _plan = i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
        decoration: BoxDecoration(
            color: sel ? const Color(0xFFB8C4F2) : Colors.black,
            border: Border.all(
                color: sel ? Colors.black : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p[0],
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 2),
              Text(p[1],
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: sel ? const Color(0xFF3A3A6A) : Colors.white)),
            ]),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(p[2],
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
              if (p[3].isNotEmpty)
                Text(p[3],
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 14, height: 1.2, color: fg)),
            ]),
          ),
          const SizedBox(width: 12),
          Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 30, color: sel ? const Color(0xFF2A2A5A) : Colors.white70),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plus = _tab == 1;
    return LightCounter(
        child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 1.0],
                colors: [Color(0xFF0A1CFF), Color(0xFF1E3AFF), Color(0xFF7A86F2)])),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 18, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              child: Row(children: [
                _tabBtn('Wattpret\nPremium', 0),
                const SizedBox(width: 10),
                _tabBtn('Wattpret\nPremium+', 1),
              ]),
            ),
            // Bagian atas bisa digulir; teks langganan & tombol tetap di bawah.
            Expanded(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const WLogo(size: 36, color: Color(0xFFC9D0FA)),
                      const SizedBox(width: 6),
                      Text(plus ? 'premium +' : 'premium',
                          style: const TextStyle(
                              fontSize: 28,
                              color: Color(0xFFC9D0FA),
                              fontWeight: FontWeight.w400)),
                    ]),
                    const SizedBox(height: 22),
                    Text(
                        plus
                            ? 'Buka akses cerita terpopuler dengan 200 Bonus Koin'
                            : 'Katakan selamat tinggal ke iklan dan sambutlah cerita offline tanpa batas',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 24,
                            height: 1.25,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 18),
                    Icon(plus ? Icons.auto_awesome : Icons.favorite,
                        size: 64,
                        color: plus
                            ? const Color(0xFFFFE2A8)
                            : const Color(0xFFDCE4F5)),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(children: [
                        if (plus) ...[
                          _check(
                              '200 Bonus Koin per bulan (Bonus Koin kedaluwarsa dalam 30 hari setelah diterima)'),
                          _check('Termasuk Wattpret Originals pilihan tiap bulan'),
                          _check('Tanpa iklan'),
                          _check('Cerita offline tanpa batas'),
                        ] else ...[
                          _check('Tanpa iklan'),
                          _check('Cerita offline tanpa batas'),
                          _check('Termasuk Wattpret Originals pilihan tiap bulan'),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 18),
                    for (var i = 0; i < _plans.length; i++) _planCard(i),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(children: [
                const Text(
                    'Dengan mengklik "Langganan sekarang", kamu setuju bahwa paket yang kamu pilih akan otomatis diperbarui dengan harga yang tertera di atas kecuali dibatalkan paling lambat satu hari sebelum tanggal pembaruan. Batalkan kapan saja di Pengaturan > Akun Apple. Jika dibatalkan, kamu tetap memiliki akses hingga tanggal pembaruan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                const Text(
                    'Uji coba gratis khusus pelanggan baru. Otomatis diperbarui ke langganan berbayar kecuali dibatalkan dalam 7 hari.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w500)),
                const SizedBox(height: 22),
                Text(
                    '${_plans[_plan][2]} / ${_plans[_plan][4]} sampai dibatalkan. Batalkan kapan saja.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _snack(
                      context, 'Berlangganan belum tersedia di versi demo'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                        color: const Color(0xFFBBC6F5),
                        borderRadius: BorderRadius.circular(40)),
                    child: const Text(
                        'Langganan sekarang dengan uji coba gratis 7 hari',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2A2A5A))),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FootLink('Pulihkan\nPembelian'),
                      _FootLink('Pelajari lebih\nlanjut'),
                      _FootLink('Kebijakan\nPrivasi'),
                      _FootLink('Persyaratan\nLayanan'),
                    ]),
              ]),
            ),
          ]),
        ),
      ),
    ));
  }
}

class _FootLink extends StatelessWidget {
  final String t;
  const _FootLink(this.t);
  @override
  Widget build(BuildContext context) => Text(t,
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70));
}

// ============================= PERSONALISASI TEMA ============================
class ThemePersonalizeScreen extends StatelessWidget {
  const ThemePersonalizeScreen({super.key});

  static const _colors = <List<Object>>[
    [Color(0xFF6B7A3A), true], [Color(0xFF5E4B52), true], [Color(0xFFF0636A), true],
    [Color(0xFF0B5273), true], [Color(0xFF2BB59A), true], [Color(0xFFF0703A), false],
    [Color(0xFF129CB0), true], [Color(0xFF1E1E1E), true], [Color(0xFFF26B21), true],
    [Color(0xFFA85A9A), true], [Color(0xFF3178C6), true], [Color(0xFF2B3E55), true],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Personalisasi tema'),
      body: ListView(padding: const EdgeInsets.fromLTRB(28, 28, 28, 20), children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 10),
          child: Text('PILIH TEMA',
              style: TextStyle(fontSize: 14, color: _grey)),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 22,
          children: [
            for (final c in _colors)
              GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const PremiumScreen())),
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                      color: c[0] as Color, shape: BoxShape.circle),
                  child: (c[1] as bool)
                      ? const Icon(Icons.lock_open_rounded,
                          size: 30, color: Colors.white54)
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen())),
            child: const Text('Aktifkan warna tema',
                style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFFAAAAAA),
                    decoration: TextDecoration.underline)),
          ),
        ),
      ]),
    );
  }
}

// ================================ AKUN TERTAUT ===============================
class LinkedAccountsScreen extends StatelessWidget {
  const LinkedAccountsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Akun tertaut'),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 26),
        _group([
          ValueListenableBuilder<bool>(
            valueListenable: SettingsStore.facebook,
            builder: (_, v, __) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.bottomCenter,
                  color: const Color(0xFF3B5998),
                  child: const Text('f',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.05)),
                ),
                const SizedBox(width: 18),
                const Expanded(
                    child: Text('Facebook', style: TextStyle(fontSize: 17))),
                _sw(v, (x) {
                  SettingsStore.facebook.value = x;
                  _snack(context,
                      x ? 'Facebook tertaut' : 'Tautan Facebook dilepas');
                }),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ================================ UNDANG TEMAN ===============================
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  Widget _row(BuildContext c, Color bg, IconData i, String t, VoidCallback f,
          {Color fg = Colors.white}) =>
      Column(children: [
        InkWell(
          onTap: f,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(i, size: 34, color: fg),
              ),
              const SizedBox(width: 24),
              Text(t,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const Padding(
            padding: EdgeInsets.only(left: 18),
            child: Divider(height: 1, color: _divC)),
      ]);

  @override
  Widget build(BuildContext context) {
    const msg = 'Ayo bergabung di Wattpret dan mulai membaca cerita seru!';
    return Scaffold(
      appBar: _bar(context, 'Undang teman'),
      body: ListView(padding: EdgeInsets.zero, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(26, 44, 26, 30),
          child: Text('Temanmu tidak ada di Wattpret?\nUndang mereka untuk bergabung.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, height: 1.3)),
        ),
        _row(context, const Color(0xFF1E9BF5), Icons.mail_outline, 'Mail',
            () => _snack(context, 'Aplikasi email dibuka dengan pesan undangan')),
        _row(context, const Color(0xFF22C03D), Icons.chat_bubble, 'SMS',
            () => _snack(context, 'Aplikasi pesan dibuka dengan pesan undangan')),
        _row(context, const Color(0xFF444446), Icons.link, 'Salin Tautan', () {
          Clipboard.setData(const ClipboardData(text: msg));
          _snack(context, 'Tautan undangan disalin');
        }),
        _row(context, const Color(0xFFAAAAAD), Icons.ios_share, 'Aplikasi lain',
            () => _snack(context, 'Menu bagikan dibuka')),
      ]),
    );
  }
}

// ================================ TENTANG WATTPRET ============================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  void _doc(BuildContext c, LegalDoc d) => Navigator.push(
      c, MaterialPageRoute(builder: (_) => LegalDocScreen(d)));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Tentang Wattpret'),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 26),
        _group([
          _navRow('Privasi', onTap: () => _doc(context, kPrivacyDoc)),
          _navRow('Persyaratan Penggunaan', onTap: () => _doc(context, kTosDoc)),
          _navRow('Kode Etik', onTap: () => _doc(context, kConductDoc)),
          _navRow('Pedoman Konten', onTap: () => _doc(context, kGuidelinesDoc)),
        ]),
      ]),
    );
  }
}

class LegalDoc {
  final String barTitle, tocTitle, heading, revised;
  final List<String> toc; // awali dengan 2 spasi untuk sub-butir
  final List<String> paras; // awali dengan "i:" untuk miring
  const LegalDoc(this.barTitle, this.tocTitle, this.heading, this.revised,
      this.toc, this.paras);
}

const kPrivacyDoc = LegalDoc(
  'Privasi',
  'Privacy Policy',
  'Privacy Policy',
  'November 2, 2023',
  [
    'What is Personal Information?',
    'What do we collect and Why do we use it?',
    'Why do you ask for my date of birth?',
    'Why do we collect and use your email?',
    'What can other Wattpret users see?',
    'Legal grounds',
    'How do we share your Personal Information?',
    'Where do we store your Personal Information?',
    'Your rights',
    'Automated Decision Making',
    'How does Wattpret protect and retain my Personal Information?',
    'How long does Wattpret keep my Personal Information?',
    'Changes',
    'How to contact us',
  ],
  [
    'i:If you are a California resident, please see our California Resident Privacy Notice for supplemental information and disclosures regarding rights of California residents',
    'At Wattpret Corp. ("Wattpret" "we" or "us"), we are committed to protecting your privacy and keeping your information safe. Wattpret processes information about you in a few different ways. This Privacy Policy explains how we collect, use, disclose and keep information that can identify you ("Personal Information") when you create a Wattpret account and use wattpret.com (the "Site"), or our mobile applications, to post content to the Wattpret community, including stories you create, comments and messages (the "Services").',
    'Note that our Terms of Service apply to this Privacy Policy. By creating an account with Wattpret, using the Services, or submitting any Personal Information via the Services, you are acknowledging that we will collect, use and disclose your Personal Information as described in this Privacy Policy.',
  ],
);

const kTosDoc = LegalDoc(
  'Persyaratan Penggunaan',
  'Terms of Service',
  'Terms of Service',
  'May 13, 2019',
  [
    'You Need to be 13',
    'You Need an Account',
    'Your Content is Yours',
    'Our Rights in the Services',
    'How We Deal with Copyright Issues',
    'Things You Should and Shouldn’t Do',
    'Deleting Your Account',
    'Disclaimers, Limitations of Liability and Indemnification',
    'Serving Ads',
    'General Terms',
  ],
  [
    'Welcome to the Wattpret platform, which is owned and operated by Wattpret Corp. ("Wattpret" "we" or "us"). These terms of service (which includes our Code of Conduct and our Privacy Policy) ("Terms of Service") are a contract between you and Wattpret. By using wattpret.com (the "Site"), creating your Wattpret account and using the Site or our mobile applications to post various content to the Wattpret community, including stories you create, comments and messages, or to access and view Wattpret content or other user content (together with the Site, the "Services"), you’re agreeing to these Terms of Service. If you don’t agree to any of these terms, you can’t use the Wattpret Services.',
  ],
);

const kConductDoc = LegalDoc(
  'Kode Etik',
  'Code of Conduct',
  'Code of Conduct',
  'Oct 14, 2021',
  [
    'We build trust and integrity with each other',
    'We engage each other with empathy, care, and respect',
    'We foster community by amplifying inspiring stories',
    'We value and speak up for marginalized communities',
    'We use our platform to protect the vulnerability of our users and their stories',
  ],
  [
    'Wattpret is a creative and global community for our users to enjoy. It’s important to respect the values of the community, but remember that you have a right and a responsibility to help uphold those values too. If you see a post with the aim of upsetting a member of our community, please report it by following the instructions here.',
    'Expressing opinions about public figures is not in violation of our policies. For more information on setting positive community values, please see here.',
    'We have an everyday commitment to this code of conduct.',
  ],
);

const kGuidelinesDoc = LegalDoc(
  'Pedoman Konten',
  'Wattpret Content Guidelines',
  'Wattpret Content Guidelines',
  'August 10, 2026',
  [
    '1. Our Approach',
    '2. Before You Post',
    '3. Content Rating',
    "4. What's Allowed (and What's Not)",
    '  Sexual Content',
    '  Violence',
    '  Self-Harm & Suicide',
    '  Hate, Harassment & Discrimination',
    '  Real-World Harm & Extremism',
    '  Self-Expression & Sensitive Topics',
    '5. Media (Images, Videos, and Other Content)',
    '6. Privacy & Respect',
    '7. Spam, Fraudulent & Commercial Content',
    '8. Unlawful Use, Reporting & Enforcement',
  ],
  [
    'At Wattpret, we believe in the power of storytelling. We want to create a space where people can freely share ideas, explore complex topics, and connect with others, while keeping our community safe and respectful for everyone.',
    'These guidelines explain what you can post, how to rate your stories, and what content is not allowed on Wattpret.',
    'You should also read our Code of Conduct, Terms of Service, Community Standards, Privacy Policy, and our Copyright Policies so you have all the information you need to enjoy Wattpret and help others enjoy it too!',
  ],
);

/// Halaman dokumen hukum ala tampilan web Wattpret (latar putih).
class LegalDocScreen extends StatefulWidget {
  final LegalDoc doc;
  const LegalDocScreen(this.doc, {super.key});
  @override
  State<LegalDocScreen> createState() => _LegalDocState();
}

class _LegalDocState extends State<LegalDocScreen> {
  final _sc = ScrollController();

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc;
    const ink = Color(0xFFBDBDBD);
    const link = Color(0xFF5DB2E6);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context)),
        title: Text(d.barTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
              color: C.bg,
              border: Border(bottom: BorderSide(color: Color(0xFF2E2E2E)))),
          child: Row(children: [
            const Spacer(flex: 2),
            const WLogo(size: 46),
            const Spacer(),
            Container(
              width: 56,
              height: 46,
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4A4A4A)),
                  borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.menu, color: Color(0xFF8A8A8A), size: 30),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _sc,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
            child: DefaultTextStyle(
              style: const TextStyle(color: ink, fontSize: 17, height: 1.6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 5, height: 22, color: const Color(0xFF1AB5B5)),
                  const SizedBox(width: 24),
                  Text(d.tocTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 18)),
                ]),
                const SizedBox(height: 10),
                for (final t in d.toc)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        29 + (t.startsWith('  ') ? 30.0 : 0), 8, 20, 8),
                    child: Text(t.trim(), style: const TextStyle(fontSize: 16)),
                  ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Divider(height: 1, color: Color(0xFF3A3A3A)),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(d.heading,
                      style: const TextStyle(
                          fontSize: 36,
                          height: 1.05,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: 'Last Revised: ${d.revised}\n'),
                    const TextSpan(
                        text: '(Click here to see previous version)',
                        style: TextStyle(color: link)),
                  ])),
                ),
                const SizedBox(height: 28),
                for (final p in d.paras)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 22),
                    child: Text(p.startsWith('i:') ? p.substring(2) : p,
                        style: TextStyle(
                            fontStyle: p.startsWith('i:')
                                ? FontStyle.italic
                                : FontStyle.normal)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => _sc.animateTo(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut),
                    child: const Text('Back to top',
                        style: TextStyle(
                            color: Color(0xFF1AB5B5),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ============================= BANTUAN & DUKUNGAN ============================
/// Layar "Bantuan & dukungan": Pusat Bantuan, Kirim Tiket Bantuan, Goyangkan.
/// Alur: Bantuan & dukungan -> (Kirim Tiket Bantuan) -> Masalah yang Diketahui
/// -> ("Masalah saya tidak tercantum!") -> Pilih Topik Bantuan.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Widget _item(String title, String desc, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, color: Color(0xFFBDBDBD))),
                const SizedBox(height: 6),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 15, height: 1.3, color: _grey)),
              ]),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 26, color: _grey),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Bantuan & dukungan'),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Text('Bantuan apa yang kamu butuhkan?',
              style: TextStyle(fontSize: 18, color: Color(0xFFBDBDBD))),
        ),
        const Divider(height: 1, color: _divC),
        _item(
            'Pusat Bantuan',
            'Kunjungi Pusat Bantuan kami dan baca artikel tentang cara menggunakan Wattpret, atau periksa halaman Masalah yang Diketahui untuk melihat bug yang sedang kami perbaiki.',
            () => _openHelpCenter(context)),
        const Divider(height: 1, color: _divC),
        _item(
            'Kirim Tiket Bantuan',
            'Mengalami kendala yang belum kami sebutkan di Pusat Bantuan? Hubungi tim kami.',
            () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KnownIssuesScreen()))),
        const Divider(height: 1, color: _divC),
        ValueListenableBuilder<bool>(
          valueListenable: SettingsStore.helpShake,
          builder: (_, v, __) => Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Goyangkan untuk Bantuan',
                      style: TextStyle(fontSize: 18, color: Color(0xFFBDBDBD))),
                  SizedBox(height: 6),
                  Text('Akses Pusat Bantuan dari mana saja dalam aplikasi.',
                      style: TextStyle(fontSize: 15, height: 1.3, color: _grey)),
                ]),
              ),
              const SizedBox(width: 12),
              _sw(v, (n) => SettingsStore.helpShake.value = n),
            ]),
          ),
        ),
        const Divider(height: 1, color: _divC),
      ]),
    );
  }
}

/// Layar "Masalah yang Diketahui": tiga artikel, lalu "Masalah saya tidak
/// tercantum!" yang membuka Pilih Topik Bantuan.
class KnownIssuesScreen extends StatelessWidget {
  const KnownIssuesScreen({super.key});

  static const _issues = [
    "How to check if there's an Outage",
    'Connection issues in various countries/regions',
    'Creating covers with Canva - Temporarily unavailable',
    'Masalah saya tidak tercantum!',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Masalah yang Diketahui'),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 40, 12),
          child: Text('Berikut adalah Masalah yang Diketahui dan sedang kami tangani:',
              style: TextStyle(fontSize: 18, height: 1.3, color: Color(0xFFBDBDBD))),
        ),
        const Divider(height: 1, color: _divC),
        for (var i = 0; i < _issues.length; i++) ...[
          InkWell(
            onTap: () {
              if (i == _issues.length - 1) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HelpTopicsScreen()));
              } else {
                _openHelpCenter(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
              child: SizedBox(
                height: 54,
                child: Row(children: [
                  Expanded(
                      child: Text(_issues[i],
                          style: const TextStyle(
                              fontSize: 17, color: Color(0xFFBDBDBD)))),
                  const Icon(Icons.chevron_right, size: 26, color: _grey),
                ]),
              ),
            ),
          ),
          Divider(
              height: 1,
              color: _divC,
              indent: i == _issues.length - 1 ? 0 : 14),
        ],
      ]),
    );
  }
}

/// Layar "Pilih Topik Bantuan": daftar topik, tiap topik membuka Pusat Bantuan.
class HelpTopicsScreen extends StatelessWidget {
  const HelpTopicsScreen({super.key});

  static const _topics = [
    'Pengaturan Akun',
    'Profil Kamu',
    'Menulis',
    'Perpustakaan',
    'Pembacaan',
    'Penelusuran dan Halaman Utama',
    'Fitur Berbayar',
    'Wattpret Premium',
    'Notifikasi',
    'Olah Pesan',
    'Komentar dan Vote',
  ];

  Widget _topic(BuildContext c, String t) => InkWell(
        onTap: () => _openHelpCenter(c),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),
          child: SizedBox(
            height: 52,
            child: Row(children: [
              Expanded(
                  child: Text(t,
                      style: const TextStyle(
                          fontSize: 17, color: Color(0xFFBDBDBD)))),
              const Icon(Icons.chevron_right, size: 26, color: _grey),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar(context, 'Pilih Topik Bantuan'),
      body: ListView(padding: EdgeInsets.zero, children: [
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Text(
              'Silakan pilih opsi yang PALING menjelaskan letak permasalahan kamu.',
              style: TextStyle(fontSize: 16, height: 1.3, color: Color(0xFFBDBDBD))),
        ),
        const Divider(height: 1, color: _divC),
        for (var i = 0; i < _topics.length; i++) ...[
          _topic(context, _topics[i]),
          Divider(
              height: 1,
              color: _divC,
              indent: i == _topics.length - 1 ? 0 : 18),
        ],
      ]),
    );
  }
}

// ================================ UNDANG-UNDANG ==============================
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  static const _disclaimer =
      'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.';

  @override
  Widget build(BuildContext context) {
    const serif = TextStyle(
        fontFamily: 'Times New Roman',
        fontFamilyFallback: ['Georgia', 'serif'],
        color: Color(0xFFDDDDDD),
        fontSize: 13.5,
        height: 1.25);
    Widget p(String t, {bool bold = false, bool center = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: SizedBox(
            width: double.infinity,
            child: Text(t,
                textAlign: center ? TextAlign.center : TextAlign.start,
                style: serif.copyWith(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          ),
        );
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Undang-undang',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 20), children: [
        p('Copyright Information', bold: true, center: true),
        p('Wattpret', bold: true),
        p('Copyright (c) 2026 Wattpret'),
        p(_disclaimer),
        p('Wattpret uses the following open source software:',
            bold: true, center: true),
        p('AFNetworking', bold: true),
        p('Copyright (c) 2013-2014 AFNetworking (http://afnetworking.com/)'),
        p('Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:'),
        p('The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.'),
        p(_disclaimer),
        p('CocoaLumberjack', bold: true),
        p('This code is distributed under the BSD license.'),
        p('Copyright (c) 2010-2014, Deusty, LLC'),
        p('Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:'),
        p('Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.'),
        p('Neither the name of Deusty nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission of Deusty, LLC.'),
        p(_disclaimer),
      ]),
    );
  }
}

// ================================= FAQ (PERPUSTAKAAN) ========================
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _faq = <List<String>>[
    [
      'Kenapa harus tersedia cara baru untuk membaca offline di Wattpret?',
      'Fitur membaca secara offline memungkinkan kamu membawa cerita Wattpret favoritmu saat bepergian—tanpa harus terhubung ke internet. Pengalaman manajemen Perpustakaan yang baru memudahkan kamu dalam menambah dan menghapus cerita dari Daftar Offline lewat sebuah ketukan tombol. Dengan hanya terhubung ke internet sebentar, tambahkan cerita ke Daftar Offline kamu dengan sekali ketuk, dan silakan menyelam ke dalam obsesimu selanjutnya di mana pun kamu berada—tanpa memerlukan internet.\n\nMeninjau masalah dari versi manajemen Perpustakaan sebelumnya, pengguna Wattpret tidak memiliki kontrol terhadap cerita yang diunduh secara otomatis, kelebihan penyimpanan di perangkat, masalah sinkronisasi Perpustakaan, dan crash pada aplikasi—yang mana bukanlah pengalaman offline yang ingin kami berikan.\n\nSekarang kamu memiliki kontrol penuh atas cerita yang ingin kamu simpan untuk dibaca secara offline dengan menyusun Daftar Offline berdasarkan kebutuhan dan preferensimu. Dengan fitur ini, kamu memberi tahu Wattpret kapan dan bagaimana menggunakan koneksi internet dan penyimpanan di perangkatmu.',
    ],
    [
      'Bagaimana cara menambahkan cerita agar dapat dibaca offline?',
      'Untuk menambahkan cerita ke daftar Offline, kamu dapat mengunjungi Perpustakaan dan ketuk ikon {cloud} kemudian "Tambahkan ke daftar Offline". Kamu harus terhubung ke internet untuk menambahkan cerita ke daftar Offline.',
    ],
    [
      'Bagaimana cara menghapus cerita dari daftar Offline saya?',
      'Untuk menghapus cerita, buka Perpustakaan kamu dan ketuk ikon {dots} di sebelah cerita yang ingin kamu hapus, kemudian "Hapus dari daftar Offline"',
    ],
    [
      'Bagaimana cara mengetahui apakah suatu cerita bisa dibaca offline?',
      'Jika kamu ingin mengonfirmasi cerita mana saja yang dapat dibaca offline, kunjungi bagian "Tersedia Offline" di Perpustakaan kamu atau lihat ikon {cloudok} di sebelah setiap cerita. Kami juga akan memberi tahu kamu saat cerita yang ingin kamu baca harus diakses dengan jaringan dan perangkat yang kamu gunakan tidak terhubung ke internet.',
    ],
    [
      'Apakah Wattpret Originals masuk dalam hitungan batas cerita offline saya?',
      'Setiap Wattpret Originals yang kamu tambahkan ke Perpustakaan akan tersedia untuk dibaca offline dan tidak akan mengurangi batas cerita offline kamu.',
    ],
    [
      'Bagaimana cara mengubah batasan offline saya?',
      'Kamu dapat menghapus batasan offline dan mengakses cerita untuk dibaca offline tanpa batas dengan berlangganan Wattpret Premium.',
    ],
    [
      'Jika saya menghapus sebuah cerita dari daftar cerita offline, apakah cerita itu akan hilang dari Perpustakaan saya?',
      'Menghapus cerita dari daftar Offline tidak akan menghapus cerita itu dari Perpustakaan. Cerita yang dihapus dari daftar Offline akan pindah ke bagian "Cerita Lainnya" di Perpustakaan kamu.',
    ],
  ];

  InlineSpan _body(String s) {
    const body = TextStyle(fontSize: 16, height: 1.4, color: Color(0xFFB5B5B5));
    final spans = <InlineSpan>[];
    final re = RegExp(r'\{(cloud|dots|cloudok)\}');
    var last = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > last) spans.add(TextSpan(text: s.substring(last, m.start)));
      final k = m.group(1);
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: k == 'dots'
            ? const Text('•••',
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900))
            : Icon(k == 'cloudok' ? Icons.cloud_done_outlined : Icons.cloud_outlined,
                size: 19, color: Colors.white),
      ));
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last)));
    return TextSpan(style: body, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _bar(context, 'FAQ'),
      body: Scrollbar(
        child: ListView(padding: EdgeInsets.zero, children: [
          for (var i = 0; i < _faq.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 14, color: _divC),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_faq[i][0],
                    style: const TextStyle(
                        fontSize: 16, height: 1.3, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text.rich(_body(_faq[i][1])),
              ]),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ======================= SUMBER DAYA KEPENULISAN (CREATORS) ==================
class _BrowserBar extends StatelessWidget {
  final Color bg, fg;
  final VoidCallback onClose;
  const _BrowserBar({required this.bg, required this.fg, required this.onClose});
  @override
  Widget build(BuildContext context) => Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Row(children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: fg.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.close, color: fg, size: 26),
            ),
          ),
          Expanded(
            child: Text('creators.wattpret.com',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: fg, fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: fg.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.web_asset, color: fg, size: 22),
          ),
        ]),
      );
}

class _CreatorsHeader extends StatelessWidget {
  final bool dark;
  const _CreatorsHeader({required this.dark});
  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : const Color(0xFF333333);
    return Container(
      color: dark ? Colors.transparent : Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(children: [
        WLogo(size: 40, color: dark ? Colors.white : C.orange),
        const SizedBox(width: 6),
        Text('creators',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w500, color: dark ? Colors.white : C.orange)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
              color: dark ? Colors.white : const Color(0xFFFF6A1A),
              borderRadius: BorderRadius.circular(24)),
          child: Text('SIGN UP',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.black : Colors.white)),
        ),
        const SizedBox(width: 16),
        Icon(Icons.search, color: fg, size: 26),
        const SizedBox(width: 14),
        Icon(Icons.menu, color: fg, size: 28),
      ]),
    );
  }
}

class WritingResourcesScreen extends StatelessWidget {
  const WritingResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2E2E2E);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        SafeArea(
          bottom: false,
          child: _BrowserBar(
              bg: const Color(0xFF2C2C2E),
              fg: Colors.white,
              onClose: () => Navigator.pop(context)),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            const _CreatorsHeader(dark: false),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Stack(children: [
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                      width: 240, height: 150, color: const Color(0xFFBFE3D6)),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(26, 6, 0, 0),
                  child: Text('WRITING\nRESOURCES',
                      style: TextStyle(
                          fontSize: 50,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                          color: ink)),
                ),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(26, 34, 26, 0),
              child: Text(
                  'Need help getting started?\nDealing with writer\'s block?\nLooking to grow your audience?',
                  style: TextStyle(fontSize: 22, height: 1.55, color: ink)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(26, 30, 26, 0),
              child: Text(
                  'Welcome to your one-stop shop for resources that will help inspire your storytelling creativity, grow your audience, and sharpen your writing skills.',
                  style: TextStyle(fontSize: 22, height: 1.55, color: ink)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _snack(context, 'Halaman dibuka di browser'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                    decoration: BoxDecoration(
                        border: Border.all(color: ink, width: 3),
                        borderRadius: BorderRadius.circular(40)),
                    child: const Text('LEARN MORE',
                        style: TextStyle(
                            fontSize: 20,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800,
                            color: ink)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            Container(
              color: const Color(0xFFF3F6F4),
              padding: const EdgeInsets.fromLTRB(26, 46, 26, 70),
              child: const Text('WHAT DO YOU WANT\nTO LEARN?',
                  style: TextStyle(
                      fontSize: 34,
                      height: 1.15,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: ink)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ========================== PROGRAM & PELUANG (CREATORS) =====================
class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  Widget _card(BuildContext c, Color thumb, IconData icon, String t) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: GestureDetector(
          onTap: () => _snack(c, 'Halaman dibuka di browser'),
          child: Container(
            height: 148,
            color: Colors.white,
            child: Row(children: [
              Container(
                  width: 150,
                  color: thumb,
                  alignment: Alignment.center,
                  child: Icon(icon, size: 56, color: Colors.white70)),
              Expanded(
                child: Center(
                  child: Text(t,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          height: 1.4,
                          letterSpacing: 4,
                          color: Color(0xFF333333))),
                ),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: Column(children: [
        SafeArea(
          bottom: false,
          child: _BrowserBar(
              bg: Colors.white,
              fg: Colors.black,
              onClose: () => Navigator.pop(context)),
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            Container(
              color: const Color(0xFF14185A),
              padding: const EdgeInsets.only(bottom: 44),
              child: Column(children: [
                const _CreatorsHeader(dark: true),
                const SizedBox(height: 40),
                const Text('PROGRAMS &\nOPPORTUNITIES',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 42,
                        height: 1.15,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                      'Writers like you are the heartbeat of the Wattpret community. We work tirelessly to create opportunities to help writers connect their stories with new audiences.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 21, height: 1.4)),
                ),
              ]),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(children: [
                _card(context, const Color(0xFF2D3DB0), Icons.local_florist,
                    'BRAND\nOPPORTUNITIES'),
                _card(context, const Color(0xFFD9503A), Icons.emoji_events,
                    'WRITING CONTESTS'),
                _card(context, const Color(0xFF33B7A8), Icons.groups,
                    'WATTPRET\nAMBASSADORS'),
              ]),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ]),
    );
  }
}
