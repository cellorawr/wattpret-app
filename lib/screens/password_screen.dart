import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'info_screen.dart';
import 'verify_email_screen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();
  bool _show1 = false, _show2 = false, _promo = false, _terms = false;

  late final TapGestureRecognizer _tosTap = TapGestureRecognizer()
    ..onTap = () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const InfoScreen('Persyaratan Layanan', kTermsText)));
  late final TapGestureRecognizer _privTap = TapGestureRecognizer()
    ..onTap = () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const InfoScreen('Kebijakan Privasi', kPrivacyText)));

  @override
  void initState() {
    super.initState();
    _f1.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _f1.dispose();
    _f2.dispose();
    _p1.dispose();
    _p2.dispose();
    _tosTap.dispose();
    _privTap.dispose();
    super.dispose();
  }

  bool get _rule1 {
    final p = _p1.text;
    return RegExp(r'\d').hasMatch(p) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(p) &&
        RegExp(r'[a-z]').hasMatch(p) &&
        RegExp(r'[A-Z]').hasMatch(p);
  }

  bool get _rule2 => _p1.text.length >= 10;
  bool get _rule3 {
    final p = _p1.text.toLowerCase();
    final u = AppState.username.toLowerCase();
    return u.isEmpty || !p.contains(u);
  }

  bool get _valid => _rule1 && _rule2 && _rule3;
  bool get _match => _p1.text == _p2.text;

  Widget _toggle(bool shown, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 92,
          alignment: Alignment.center,
          child: Text(shown ? 'Sembunyikan' : 'Tampilkan',
              style: const TextStyle(
                  color: C.link, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      );

  Widget _req(String t, bool ok) => Padding(
        padding: const EdgeInsets.only(left: 6, top: 3),
        child: Text('•  $t',
            style: TextStyle(
                color: ok ? const Color(0xFF3DB88B) : C.red, fontSize: 15)),
      );

  bool _loading = false;

  Future<void> _submit() async {
    if (_loading) return;
    if (!_terms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Setujui Persyaratan Layanan dan Kebijakan Privasi dulu')));
      return;
    }
    if (_p1.text.isEmpty || !_valid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kata sandi belum memenuhi persyaratan')));
      return;
    }
    if (!_match) {
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kata sandi tidak cocok')));
      return;
    }
    setState(() => _loading = true);
    try {
      await Api.register(AppState.email, AppState.username, _p1.text);
      await AppState.syncFromServer();
      if (!mounted) return;
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
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

  @override
  Widget build(BuildContext context) {
    final p1 = _p1.text.isNotEmpty;
    final p2 = _p2.text.isNotEmpty;
    // Hanya bergantung pada isi (bukan fokus) supaya kolom di bawahnya tidak
    // bergeser saat kolom lain diketuk.
    final showReq = p1 && !_valid;
    final err1 = p1 && !_valid;
    final err2 = p2 && (!_match || !_valid);
    const label = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
    String? msg;
    if (p2 && !_match) {
      msg = 'Kata sandi tidak cocok.';
    } else if (p2 && _match && !_valid) {
      msg = 'Kata sandi cocok, tetapi tidak memenuhi persyaratan.';
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Column(children: [
            Expanded(
              child: ListView(children: [
                const SizedBox(height: 18),
                const Text('Buat akun',
                    style:
                        TextStyle(fontSize: 31, fontWeight: FontWeight.w800)),
                const SizedBox(height: 28),
                const Text('Kata Sandi', style: label),
                const SizedBox(height: 12),
                TextField(
                  controller: _p1,
                  focusNode: _f1,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _f2.requestFocus(),
                  obscureText: !_show1,
                  style: const TextStyle(fontSize: 20),
                  onChanged: (_) => setState(() {}),
                  decoration: pillDecoration(
                      hint: 'Kata Sandi',
                      error: err1,
                      vPad: 14,
                      borderColor: _f1.hasFocus ? C.orange : null,
                      suffix: _toggle(_show1,
                          () => setState(() => _show1 = !_show1))),
                ),
                if (showReq) ...[
                  const SizedBox(height: 12),
                  const Text('Persyaratan kata sandi:',
                      style: TextStyle(color: C.red, fontSize: 15)),
                  _req(
                      'Harus berisi angka, karakter khusus, serta huruf kecil dan huruf besar',
                      _rule1),
                  _req('Harus memiliki panjang minimal 10 karakter', _rule2),
                  _req(
                      'Tidak boleh berisi nama pengguna, atau nama tampilan kamu',
                      _rule3),
                ],
                const SizedBox(height: 26),
                const Text('Masukkan ulang kata sandi', style: label),
                const SizedBox(height: 12),
                TextField(
                  controller: _p2,
                  focusNode: _f2,
                  textInputAction: TextInputAction.done,
                  obscureText: !_show2,
                  style: const TextStyle(fontSize: 20),
                  onChanged: (_) => setState(() {}),
                  decoration: pillDecoration(
                      hint: 'Masukkan ulang kata sandi',
                      error: err2,
                      vPad: 14,
                      suffix: _toggle(_show2,
                          () => setState(() => _show2 = !_show2))),
                ),
                if (msg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 2),
                    child: Text(msg,
                        style: const TextStyle(color: C.red, fontSize: 15)),
                  ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFF2E2E2E)),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppCheck(
                      value: _promo,
                      onChanged: (v) => setState(() => _promo = v)),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Ya, saya ingin menerima email promosi dari Wattpret. (opsional)',
                              style: TextStyle(fontSize: 18)),
                          SizedBox(height: 6),
                          Text(
                              'Dapatkan info tentang pembaruan cerita, pengumuman, penawaran, dan lainnya via email. Nonaktifkan kapan saja.',
                              style: TextStyle(color: C.grey, fontSize: 15)),
                        ]),
                  ),
                ]),
                const SizedBox(height: 24),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppCheck(
                      value: _terms,
                      onChanged: (v) => setState(() => _terms = v)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                          children: [
                            const TextSpan(text: 'Ya, saya telah membaca dan menyetujui '),
                            TextSpan(
                                text: 'Persyaratan Layanan',
                                recognizer: _tosTap,
                                style: const TextStyle(color: C.link)),
                            const TextSpan(text: ' dan '),
                            TextSpan(
                                text: 'Kebijakan Privasi',
                                recognizer: _privTap,
                                style: const TextStyle(color: C.link)),
                            const TextSpan(text: ' Wattpret.'),
                          ]),
                    ),
                  ),
                ]),
              ]),
            ),
            WhiteButton('Daftar', onTap: _submit),
          ]),
        ),
      ),
    );
  }
}
