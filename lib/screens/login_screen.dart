import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import '../theme.dart';
import '../widgets.dart';
import 'main_shell.dart';
import '../api_service.dart';
import '../app_state.dart';

/// Layar "Masuk" (untuk yang sudah punya akun).
/// Ukuran mengikuti screenshot aplikasi asli (layar 390 x 844):
/// tombol & kolom setinggi 48, margin samping 24, jarak antar tombol 24.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _idF = FocusNode();
  final _pwF = FocusNode();
  bool _show = false;

  // Warna kolom saat sedang diisi / sudah berisi (mengikuti aplikasi asli).
  static const _active = Color(0xFF98A585);
  static const _activeLink = Color(0xFF84C0B8);
  static const _line = Color(0xFF3A3A3C);
  static const _lbl = TextStyle(fontSize: 18, fontWeight: FontWeight.w400);

  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    for (final l in [_id, _pw]) {
      l.addListener(_rebuild);
    }
    for (final f in [_idF, _pwF]) {
      f.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    _idF.dispose();
    _pwF.dispose();
    super.dispose();
  }

  bool get _idOn => _idF.hasFocus || _id.text.isNotEmpty;
  bool get _pwOn => _pwF.hasFocus || _pw.text.isNotEmpty;

  bool _loading = false;

  Future<void> _login() async {
    if (_loading) return;
    if (_id.text.trim().isEmpty || _pw.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Isi email atau nama pengguna dan kata sandi')));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await Api.login(_id.text.trim(), _pw.text);
      AppState.username = (user['username'] ?? AppState.username).toString();
      AppState.email = (user['email'] ?? AppState.email).toString();
      await AppState.syncFromServer();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Tidak bisa terhubung ke server. Pastikan php artisan serve sudah jalan.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tombol sosial: hanya tampilan, belum difungsikan.
  Widget _social(Widget icon, String label,
          {Color bg = Colors.transparent, bool bold = true}) =>
      Container(
        height: 48,
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 1.2)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 18 : 22,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        ]),
      );

  InputDecoration _dec(String hint, {Widget? suffix, bool on = false}) {
    OutlineInputBorder b() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: on ? _active : _line, width: 1.2));
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
      enabledBorder: b(),
      border: b(),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: _active, width: 1.2)),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 52),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('wattpret',
                      style: TextStyle(
                          color: C.orange,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5)),
                  SizedBox(width: 6),
                  WLogo(size: 36),
                ]),
                const SizedBox(height: 24),
                // Google & Facebook: belum difungsikan (tampilan saja).
                _social(
                    Image.asset('assets/logo_google.png',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) => const Text('G',
                            style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontWeight: FontWeight.w900,
                                fontSize: 24))),
                    'Masuk dengan akun Google'),
                const SizedBox(height: 24),
                _social(
                    Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                            color: const Color(0xFF3B5998),
                            borderRadius: BorderRadius.circular(3)),
                        child: const Text('f',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                height: 1))),
                    'Masuk dengan Facebook'),
                const SizedBox(height: 20),
                const Row(children: [
                  Expanded(child: Divider(color: Color(0xFF2A2A2A), height: 1)),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('atau',
                          style: TextStyle(color: C.grey, fontSize: 15))),
                  Expanded(child: Divider(color: Color(0xFF2A2A2A), height: 1)),
                ]),
                const SizedBox(height: 26),
                const Text('Email atau nama pengguna', style: _lbl),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _id,
                    focusNode: _idF,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 18),
                    decoration: _dec('Email atau nama pengguna', on: _idOn),
                  ),
                ),
                const SizedBox(height: 26),
                const Text('Kata Sandi', style: _lbl),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _pw,
                    focusNode: _pwF,
                    obscureText: !_show,
                    style: const TextStyle(fontSize: 18),
                    onChanged: (_) => setState(() {}),
                    decoration: _dec('Kata Sandi',
                        on: _pwOn,
                        suffix: GestureDetector(
                          onTap: () => setState(() => _show = !_show),
                          child: Container(
                            width: 44,
                            margin: const EdgeInsets.only(right: 4),
                            alignment: Alignment.center,
                            child: Text(_show ? 'Sembunyikan' : 'Tampilkan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _pwOn
                                        ? _activeLink
                                        : const Color(0xFF8E8E93),
                                    fontSize: 13,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800)),
                          ),
                        )),
                  ),
                ),
                const SizedBox(height: 26),
                WhiteButton('Masuk', onTap: _login),
                const SizedBox(height: 36),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Lupa kata sandi?',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          // "Belum punya akun? Daftar" -> kembali ke halaman sebelumnya.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(0, 14, 0, 40),
              child: Text('Belum punya akun? Daftar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}
