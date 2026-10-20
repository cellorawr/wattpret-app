import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'password_screen.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _email = TextEditingController();
  final _user = TextEditingController();
  final _mm = TextEditingController();
  final _dd = TextEditingController();
  final _yy = TextEditingController();
  String _pron = 'Perempuan';
  bool _submitted = false;

  static const _taken = {'wawawawawawa', 'admin', 'wattpad', 'wattpret'};
  static const _pronouns = [
    'Perempuan',
    'Laki-laki',
    'Non-biner',
    'Lainnya',
    'Tidak ingin menyebutkan'
  ];

  bool get _mmOk {
    final v = int.tryParse(_mm.text);
    return v != null && v >= 1 && v <= 12;
  }

  bool get _ddOk {
    final v = int.tryParse(_dd.text);
    return v != null && v >= 1 && v <= 31;
  }

  bool get _yyOk {
    final v = int.tryParse(_yy.text);
    return v != null &&
        _yy.text.length == 4 &&
        v >= 1900 &&
        v <= DateTime.now().year;
  }

  static const _olive = Color(0xFFB3CB8F);
  bool get _userOk => _user.text.trim().isNotEmpty && _userErr == null;

  String? get _emailErr {
    final e = _email.text.trim();
    if (e.isEmpty) return _submitted ? 'Email wajib diisi' : null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      return 'Masukkan email yang valid';
    }
    return null;
  }

  String? get _userErr {
    final u = _user.text.trim();
    if (u.isEmpty) return _submitted ? 'Nama pengguna wajib diisi' : null;
    if (_taken.contains(u.toLowerCase())) {
      return 'Nama pengguna ini telah digunakan';
    }
    if (u.length < 2) return 'Nama pengguna terlalu pendek';
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(u)) {
      return 'Hanya huruf, angka, dan garis bawah';
    }
    return null;
  }

  void _next() {
    setState(() => _submitted = true);
    if (_emailErr != null ||
        _userErr != null ||
        _user.text.trim().isEmpty ||
        _email.text.trim().isEmpty) return;
    if (!(_mmOk && _ddOk && _yyOk)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal lahir belum valid')));
      return;
    }
    final age = DateTime.now().year - int.parse(_yy.text);
    if (age < 13) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kamu harus berusia minimal 13 tahun')));
      return;
    }
    AppState.email = _email.text.trim();
    AppState.username = _user.text.trim();
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PasswordScreen()));
  }

  Widget _err(String? t) => t == null
      ? const SizedBox(height: 0)
      : Padding(
          padding: const EdgeInsets.only(top: 6, left: 2),
          child: Text(t, style: const TextStyle(color: C.red, fontSize: 15)));

  Widget _dateField(String label, TextEditingController c, bool ok, int max) {
    const green = Color(0xFF3DB88B);
    return Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 20),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(max)
        ],
        onChanged: (_) => setState(() {}),
        decoration: pillDecoration(
          label: label,
          borderColor: ok ? green : null,
          suffix: ok
              ? const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check, color: green, size: 18))
              : null,
        ).copyWith(
          // kolom sempit: kurangi padding & lebar ikon agar angka tidak terpotong
          contentPadding: const EdgeInsets.fromLTRB(18, 17, 4, 17),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = const TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
    return Scaffold(
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
                const Text('Ceritakan tentang dirimu',
                    style:
                        TextStyle(fontSize: 31, fontWeight: FontWeight.w800)),
                const SizedBox(height: 28),
                Text('Email', style: label),
                const SizedBox(height: 10),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 19),
                  onChanged: (_) => setState(() {}),
                  decoration: pillDecoration(error: _emailErr != null, vPad: 14),
                ),
                _err(_emailErr),
                const SizedBox(height: 22),
                Text('Nama Pengguna', style: label),
                const SizedBox(height: 10),
                TextField(
                  controller: _user,
                  style: const TextStyle(fontSize: 19),
                  onChanged: (_) => setState(() {}),
                  decoration: pillDecoration(
                    error: _userErr != null,
                    vPad: 14,
                    borderColor: _userOk ? _olive : null,
                    suffix: _userOk
                        ? const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.check, color: _olive, size: 22))
                        : null,
                  ),
                ),
                _err(_userErr),
                if (_userErr == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 2),
                    child: Text('Nama pengguna kamu bersifat publik.',
                        style: TextStyle(color: C.grey, fontSize: 14)),
                  ),
                const SizedBox(height: 22),
                Text('Kapan kamu lahir?', style: label),
                const SizedBox(height: 12),
                Row(children: [
                  _dateField('MM', _mm, _mmOk, 2),
                  const SizedBox(width: 14),
                  _dateField('DD', _dd, _ddOk, 2),
                  const SizedBox(width: 14),
                  _dateField('YYYY', _yy, _yyOk, 4),
                ]),
                const SizedBox(height: 10),
                const Text(
                    'Tanggal lahirmu hanya dapat dilihat oleh kamu dan tim pendukung Wattpret.',
                    style: TextStyle(color: C.grey, fontSize: 15)),
                const SizedBox(height: 26),
                Text('Kata ganti (opsional)', style: label),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: const Color(0xFF8A8A8A), width: 1.3)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _pron,
                      isExpanded: true,
                      dropdownColor: C.surface,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: const TextStyle(fontSize: 19, color: Colors.white),
                      items: [
                        for (final p in _pronouns)
                          DropdownMenuItem(value: p, child: Text(p))
                      ],
                      onChanged: (v) => setState(() => _pron = v ?? _pron),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                    'Kata gantimu hanya dapat dilihat oleh kamu dan Tim Pendukung Wattpret. Kamu dapat memperbaruinya kapan saja di pengaturan.',
                    style: TextStyle(color: C.grey, fontSize: 15)),
              ]),
            ),
            WhiteButton('Lanjutkan', onTap: _next),
          ]),
        ),
      ),
    );
  }
}
