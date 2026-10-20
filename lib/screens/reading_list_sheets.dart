import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';

const Color _sheetBg = Color(0xFF121212);

Widget _grabbableSheet({required Widget child}) => Container(
      decoration: const BoxDecoration(
          color: _sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      child: child,
    );

Widget _pillButton(String label, VoidCallback? onTap, {bool filled = false}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: filled
                ? (onTap == null ? const Color(0xFF3A3A3A) : Colors.white)
                : Colors.transparent,
            border: filled ? null : Border.all(color: Colors.white, width: 1.4),
            borderRadius: BorderRadius.circular(30)),
        child: Text(label,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: filled
                    ? (onTap == null ? const Color(0xFF8A8A8A) : Colors.black)
                    : Colors.white)),
      ),
    );

/// Lembar "Tambahkan cerita ke": Perpustakaan + semua daftar bacaan.
Future<void> showAddToSheet(BuildContext context, Story story) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) => _grabbableSheet(
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.62),
          child: ListenableBuilder(
            listenable:
                Listenable.merge([AppState.library, AppState.readingLists]),
            builder: (_, __) {
              Widget row(String name, bool pub, bool on, VoidCallback tap) =>
                  InkWell(
                    onTap: tap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xFF2E2E2E)))),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Icon(
                                      pub
                                          ? Icons.public
                                          : Icons.lock_outline,
                                      size: 20,
                                      color: C.grey),
                                  const SizedBox(width: 8),
                                  Text(pub ? 'Publik' : 'Pribadi',
                                      style: const TextStyle(
                                          color: C.grey, fontSize: 16)),
                                ]),
                              ]),
                        ),
                        if (on) const Icon(Icons.check, size: 28),
                      ]),
                    ),
                  );
              return Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Tambahkan cerita ke',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800))),
                    GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, size: 30)),
                  ]),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView(shrinkWrap: true, children: [
                      row('Perpustakaan', false, AppState.inLibrary(story), () {
                        AppState.inLibrary(story)
                            ? AppState.removeFromLibrary(story)
                            : AppState.addToLibrary(story);
                      }),
                      for (final l in AppState.readingLists.value)
                        row(AppState.listName(l), l.isPublic, l.has(story),
                            () => AppState.toggleInList(l, story)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  _pillButton('Buat daftar bacaan baru', () async {
                    await showCreateListSheet(context, add: story);
                  }),
                  const SizedBox(height: 12),
                  _pillButton('Tutup', () => Navigator.pop(ctx), filled: true),
                ]),
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// Lembar "Buat daftar baru" (judul + privasi Publik/Pribadi).
/// Jika [add] diisi, cerita itu langsung dimasukkan ke daftar baru.
Future<void> showCreateListSheet(BuildContext context, {Story? add}) {
  final c = TextEditingController();
  var pub = true;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final name = c.text.trim();
      Widget radio(bool value, IconData icon, String t, String d) =>
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setS(() => pub = value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(d,
                        style: const TextStyle(
                            fontSize: 15, height: 1.3, color: C.grey)),
                  ]),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: pub == value ? C.orange : const Color(0xFF6A6A6A),
                          width: 2.4)),
                  child: pub == value
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                              color: C.orange, shape: BoxShape.circle))
                      : null,
                ),
              ]),
            ),
          );
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _grabbableSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const Expanded(
                      child: Text('Buat daftar baru',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800))),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, size: 30)),
                ]),
                const SizedBox(height: 24),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Judul',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                const SizedBox(height: 10),
                TextField(
                  controller: c,
                  maxLength: 80,
                  onChanged: (_) => setS(() {}),
                  cursorColor: C.orange,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            const BorderSide(color: Color(0xFF8A8A8A), width: 1.3)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.white, width: 1.3)),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${c.text.length}/80 karakter',
                        style: const TextStyle(fontSize: 15))),
                const SizedBox(height: 22),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Privasi daftar',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                const SizedBox(height: 4),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Pilih siapa yang dapat melihat daftar ini',
                        style: TextStyle(fontSize: 15, color: C.grey))),
                const SizedBox(height: 8),
                radio(true, Icons.public, 'Publik',
                    'Dapat dilihat semua orang di Wattpret. Daftar publik dapat dibagikan dan disukai.'),
                radio(false, Icons.lock_outline, 'Pribadi',
                    'Hanya dapat dilihat oleh kamu.'),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _pillButton('Batal', () => Navigator.pop(ctx))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pillButton(
                        'Buat',
                        name.isEmpty
                            ? null
                            : () {
                                final l = ReadingList(name, isPublic: pub);
                                if (add != null) l.own.add(add);
                                AppState.readingLists.value = [
                                  ...AppState.readingLists.value,
                                  l
                                ];
                                Navigator.pop(ctx);
                              },
                        filled: true),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      );
    }),
  );
}
