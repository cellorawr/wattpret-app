import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import 'camera_capture_screen.dart';

/// Pemilih gambar umum untuk semua bagian yang butuh gambar:
/// sampul cerita (info cerita, banner bab, edit cerita) dan gambar di dalam bab.
/// Tombol ikon video juga memakai pemilih ini (hasilnya tetap gambar).
///
/// Mengembalikan daftar gambar (kosong bila dibatalkan / gagal).
/// [multi] = boleh pilih beberapa gambar sekaligus dari galeri.
/// [onRemove] != null menampilkan pilihan "Hapus gambar".
Future<List<Uint8List>> pickImages(
  BuildContext c, {
  bool multi = false,
  bool cover = false,
  VoidCallback? onRemove,
}) async {
  const divC = Color(0xFF3A3A3C);

  Widget btn(BuildContext ctx, String t, VoidCallback f, {Color? color}) =>
      InkWell(
        onTap: f,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          child: Text(t,
              style: TextStyle(fontSize: 20, color: color ?? C.iosBlue)),
        ),
      );

  var removed = false;
  final src = await showModalBottomSheet<ImageSource>(
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
              btn(ctx, 'Mengambil Foto',
                  () => Navigator.pop(ctx, ImageSource.camera)),
              const Divider(height: 1, color: divC),
              btn(ctx, 'Pilih dari Galeri',
                  () => Navigator.pop(ctx, ImageSource.gallery)),
              if (onRemove != null) ...[
                const Divider(height: 1, color: divC),
                btn(ctx, 'Hapus gambar', () {
                  removed = true;
                  Navigator.pop(ctx);
                }, color: C.red),
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

  if (removed) {
    onRemove?.call();
    return [];
  }
  if (src == null || !c.mounted) return [];

  try {
    final desktopOrWeb = kIsWeb ||
        const {TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macOS}
            .contains(defaultTargetPlatform);
    if (src == ImageSource.camera && desktopOrWeb) {
      // Di web/desktop image_picker hanya membuka pemilih berkas,
      // jadi pakai layar kamera langsung.
      final b = await Navigator.of(c, rootNavigator: true).push<Uint8List>(
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const CameraCaptureScreen()));
      return b == null ? [] : [b];
    }
    final max = cover ? 1600.0 : 1400.0;
    if (multi && src == ImageSource.gallery) {
      final xs = await ImagePicker()
          .pickMultiImage(maxWidth: max, maxHeight: max, imageQuality: 88);
      return [for (final x in xs) await x.readAsBytes()];
    }
    final x = await ImagePicker().pickImage(
        source: src, maxWidth: max, maxHeight: max, imageQuality: 88);
    if (x == null) return [];
    return [await x.readAsBytes()];
  } catch (_) {
    if (c.mounted) {
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(
          content: Text(src == ImageSource.camera
              ? 'Tidak bisa membuka kamera. Periksa izin kamera.'
              : 'Tidak bisa membuka galeri. Periksa izin foto.')));
    }
    return [];
  }
}
