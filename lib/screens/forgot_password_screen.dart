import 'package:flutter/material.dart';

/// Layar "Lupa kata sandi" (email / nama pengguna + tombol Kirim) dengan
/// kotak konfirmasi "Kembali untuk Masuk".
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _c = TextEditingController();
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_c.text.trim().isEmpty) return;
    _f.unfocus();
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.47),
      builder: (ctx) => Center(
        child: Material(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 254,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 21, 16, 19),
                child: Text(
                    'Jika ada akun yang terhubung dengan email atau nama pengguna ini, kamu akan menerima email untuk mengatur ulang kata sandimu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14.5, height: 1.2, color: Colors.white)),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFF3D3D3F)),
              InkWell(
                onTap: () => Navigator.pop(ctx),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(13)),
                child: const SizedBox(
                  height: 41,
                  width: double.infinity,
                  child: Center(
                    child: Text('Kembali untuk Masuk',
                        style:
                            TextStyle(fontSize: 17, color: Color(0xFF4C93F5))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomGap = (44 - mq.padding.bottom).clamp(16.0, 60.0).toDouble();
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: EdgeInsets.fromLTRB(22.7, mq.padding.top, 22.7, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 38,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: const Padding(
                    padding: EdgeInsets.only(left: 0, right: 16),
                    child: Icon(Icons.arrow_back, size: 26)),
              ),
            ),
          ),
          const SizedBox(height: 16.5),
          const Text('Lupa kata sandi',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 25.5),
          const Text(
              'Masukkan email atau nama penggunamu, dan kami akan mengirimkan instruksi cara mengatur ulang kata sandimu.',
              style: TextStyle(
                  fontSize: 16, height: 1.4, color: Color(0xFFA3A3A5))),
          const SizedBox(height: 22.5),
          const Text('Email atau nama pengguna',
              style: TextStyle(fontSize: 16.5, height: 1.2)),
          const SizedBox(height: 8),
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                    color: _f.hasFocus
                        ? const Color(0xFF7A8A5C)
                        : const Color(0xFF3A3A3C),
                    width: 1.2)),
            child: TextField(
              controller: _c,
              focusNode: _f,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 16.5),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Email atau nama pengguna',
                hintStyle: TextStyle(fontSize: 16.5, color: Color(0xFF8E8E90)),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _send,
            child: Container(
              height: 45,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(23)),
              child: const Text('Kirim',
                  style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
            ),
          ),
          SizedBox(height: bottomGap),
        ]),
      ),
    );
  }
}
