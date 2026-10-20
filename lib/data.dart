import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'api_service.dart';

class Story {
  final String title, author, views;
  final int parts;
  final List<String> tags;
  final Color color, textColor;
  final String synopsis;

  /// Sampul yang diunggah pengguna (null = pakai sampul bawaan / aset).
  final Uint8List? cover;

  /// Data dari server (null bila cerita bawaan lokal).
  final int? id;
  final String? coverUrl;
  final String category;
  const Story(this.title, this.author, this.views, this.parts, this.tags,
      this.color, this.textColor,
      {this.synopsis = '',
      this.cover,
      this.id,
      this.coverUrl,
      this.category = ''});

  /// Jumlah vote asli dari server, menurut id cerita.
  static final Map<int, int> voteCounts = {};

  /// Dibuat dari JSON `/api/stories`.
  factory Story.fromJson(Map<String, dynamic> j) {
    Color parse(String? hex) {
      final h = (hex ?? '').replaceAll('#', '');
      final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
      return Color(v ?? 0xFF2A2A2A);
    }

    final bg = parse(j['cover_color']?.toString());
    final tags = (j['tags'] ?? '')
        .toString()
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final cat = (j['category'] ?? '').toString();
    final a = j['author'];
    final sid = int.tryParse('${j['id']}');
    final vc = int.tryParse('${j['votes_count']}');
    if (sid != null && vc != null) voteCounts[sid] = vc;
    return Story(
      (j['title'] ?? '').toString(),
      a is Map ? (a['username'] ?? '').toString() : '',
      _fmtViews(j['views']),
      int.tryParse('${j['chapters_count'] ?? 0}') ?? 0,
      tags.isEmpty ? [cat.isEmpty ? 'cerita' : cat.toLowerCase()] : tags,
      bg,
      bg.computeLuminance() > 0.5 ? const Color(0xFF2B2B2B) : Colors.white,
      synopsis: (j['synopsis'] ?? '').toString(),
      id: int.tryParse('${j['id']}'),
      coverUrl: j['cover_url']?.toString(),
      category: cat,
    );
  }
}

/// Angka ringkas: 950 -> "950", 1200 -> "1,2Rb", 2500000 -> "2,5Jt".
String fmtCount(int n) => _fmtViews(n);

String _fmtViews(dynamic v) {
  final n = int.tryParse('$v') ?? 0;
  String one(double x) {
    final s = x.toStringAsFixed(1);
    return (s.endsWith('.0') ? s.substring(0, s.length - 2) : s)
        .replaceAll('.', ',');
  }

  if (n >= 1000000) return '${one(n / 1000000)}Jt';
  if (n >= 1000) return '${one(n / 1000)}Rb';
  return '$n';
}

class ServerChapter {
  final int id;
  final String title;
  final DateTime date;
  const ServerChapter(this.id, this.title, this.date);
}

/// Detail cerita + isi bab dari server (disimpan di memori selama aplikasi jalan).
class ServerCache {
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);
  static final Map<int, Map<String, dynamic>> details = {};
  static final Map<int, List<ServerChapter>> chapters = {};
  static final Map<int, String> bodies = {};
  static final Set<int> _busy = {};
  static final Set<int> failed = {};

  static Future<Map<String, dynamic>?> loadDetail(int storyId,
      {bool force = false}) async {
    if (!force && details.containsKey(storyId)) return details[storyId];
    try {
      final d = await Api.story(storyId);
      details[storyId] = d;
      chapters[storyId] = [
        for (final c in (d['chapters'] as List? ?? const []))
          ServerChapter(
              int.parse('${c['id']}'),
              (c['title'] ?? '').toString(),
              DateTime.tryParse('${c['created_at']}')?.toLocal() ??
                  DateTime.now())
      ];
      tick.value++;
      return d;
    } catch (_) {
      return null;
    }
  }

  /// Mulai mengambil isi bab (sekali saja); hasilnya ada di [bodies].
  static Future<void> loadBody(int chapterId) async {
    if (bodies.containsKey(chapterId) ||
        failed.contains(chapterId) ||
        !_busy.add(chapterId)) {
      return;
    }
    try {
      final c = await Api.chapter(chapterId);
      bodies[chapterId] = (c['body'] ?? '').toString();
    } catch (_) {
      failed.add(chapterId);
    } finally {
      _busy.remove(chapterId);
      tick.value++;
    }
  }
}

/// Cerita yang diambil dari server. Selama belum termuat (atau server mati),
/// aplikasi memakai data bawaan lokal.
class ServerStories {
  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  static List<Story> all = [];
  static bool get loaded => all.isNotEmpty;

  static Future<void> load() async {
    try {
      final out = <Story>[];
      for (var p = 1; p <= 20; p++) {
        final page = await Api.stories(sort: 'popular', page: p);
        if (page.isEmpty) break;
        out.addAll(page.map(Story.fromJson));
      }
      if (out.isNotEmpty) {
        all = out;
        version.value++;
      }
    } catch (_) {
      // server tidak terjangkau: tetap pakai data lokal
    }
  }

  static List<Story> byCategory(String c) =>
      all.where((s) => s.category == c).toList();
  static List<Story> top(int n) => all.take(n).toList();
}

const kCategories = [
  'Romansa',
  'Fiksi Remaja',
  'Fiksi Penggemar',
  'Fantasi',
  'Acak',
  'Cerita Pendek',
  'Fiksi Umum',
  'ChickLit',
  'Humor',
  'Aksi',
  'Misteri',
  'Thriller',
  'Spiritual',
  'Fiksi Sejarah',
  'Nonfiksi',
  'Fiksi Ilmiah',
  'Petualangan',
  'Horor',
  'Vampir',
  'Manusia Serigala',
  'Paranormal',
  'Puisi',
  'Klasik'
];

const featured = <Story>[
  Story('My Devil\nHUSBAND', 'demimoy', '24,5Jt', 60, ['lovestory'],
      Color(0xFF1B2433), Colors.white),
  Story('Silencio', 'Winnyraca', '1,47Jt', 40, ['love'], Color(0xFFB9B7C9),
      Colors.white),
  Story('Bening dan Banyu', 'MommieXYZ', '5,56Jt', 50, ['romantis'],
      Color(0xFFF4F1EA), Color(0xFF3B5B9C)),
  Story('Jan... Serigala Bulan', 'SKIA LIN', '3,17Jt', 45, ['romansa'],
      Color(0xFF1C1C1C), Color(0xFFD9C27B)),
];

const finalists = <Story>[
  Story('Unconditional Love', 'apinath', '2Jt', 40, ['romansa'], Colors.white,
      Colors.black),
  Story('BEGIN Again', 'Rhainike', '1Jt', 30, ['romansa'], Color(0xFF8E7BB5),
      Colors.white),
  Story('Unwanted Marriage', 'Huzaifah Shafia', '900Rb', 35, ['romansa'],
      Color(0xFFE6D9EC), Color(0xFF4A3B5C)),
  Story('Unexpected Groom', 'Huzaifah Shafia', '700Rb', 33, ['romansa'],
      Color(0xFFBFD6EA), Color(0xFF3B5B7C)),
];

/// Semua cerita di sini ramah semua umur (tidak ada konten 21+/dewasa).
const ranking = <Story>[
  Story('Senja di Ujung Dermaga', 'nadiraputri', '3Jt', 62,
      ['remaja', 'persahabatan', 'sekolah'], Color(0xFF8A9A86), Colors.white),
  Story('Kopi Pertama di Bulan Mei', 'kirana_w', '3Jt', 48,
      ['romansa', 'kampus', 'ringan'], Color(0xFFF8F1E4), Color(0xFFB8862B)),
  Story('Kelas 12 IPA 3', 'raflisetia', '2Jt', 47,
      ['sekolah', 'remaja', 'komedi'], Color(0xFF2A2A2A), Colors.white),
  Story('Balik Kanan Jatuh Cinta', 'zyourwrite', '2Jt', 55,
      ['ceo', 'chicklit', 'cinta'], Color(0xFFFFD84D), Color(0xFF8A4B14)),
  Story('Surat untuk Esok Hari', 'aya.writes', '3Jt', 57,
      ['keluarga', 'inspiratif', 'usai'], Color(0xFF6F7B66), Colors.white),
];

// Judul, penulis, views, jumlah bab, tag (dipisah koma)
const _bank = <String, List<List<String>>>{
  'Fiksi Remaja': [
    ['Jurnal Anak Kos Pertama', 'dinda.menulis', '1,8Jt', '44', 'remaja,kos,persahabatan'],
    ['Geng Atap Sekolah', 'bumiaksara', '1,2Jt', '38', 'sekolah,geng,remaja'],
    ['Bintang di Kelas Sebelah', 'salsabila_r', '2,1Jt', '51', 'sekolah,cinta,remaja'],
    ['Seragam Putih Abu-abu', 'ketikanrani', '900Rb', '29', 'sma,sahabat,remaja'],
  ],
  'Fiksi Penggemar': [
    ['Dunia Setelah Konser', 'mimpiseribu', '1,5Jt', '36', 'fandom,musik,fiksipenggemar'],
    ['Catatan Fandom Kita', 'ara.ketik', '820Rb', '25', 'fandom,komunitas,teman'],
    ['Sahabat Sang Idola', 'lintangmalam', '1,1Jt', '41', 'idola,persahabatan,au'],
    ['Tiket Terakhir', 'fiksiwulan', '640Rb', '22', 'konser,fandom,au'],
  ],
  'Fantasi': [
    ['Kerajaan di Balik Kabut', 'penjagabuku', '2,4Jt', '58', 'kerajaan,sihir,petualangan'],
    ['Penjaga Lentera Terakhir', 'senjakala_', '1,6Jt', '47', 'lentera,sihir,takdir'],
    ['Naga Kecil dari Gunung Arum', 'tintabiru', '1,3Jt', '33', 'naga,petualangan,keluarga'],
    ['Sihir di Kota Bawah Laut', 'ombakpagi', '980Rb', '40', 'laut,sihir,misteri'],
  ],
  'Aksi': [
    ['Operasi Fajar', 'garudaputra', '1,9Jt', '45', 'agen,misi,aksi'],
    ['Kurir Tengah Malam', 'rafi_nugraha', '1,4Jt', '39', 'kota,kejar,aksi'],
    ['Garis Merah Pelabuhan', 'dermagabaja', '870Rb', '31', 'pelabuhan,aksi,persahabatan'],
    ['Pelari dari Zona Tujuh', 'zonanol', '1,1Jt', '43', 'distopia,aksi,bertahan'],
  ],
  'Misteri': [
    ['Rumah Nomor Tujuh', 'jejakkata', '2,2Jt', '49', 'rumah,teka-teki,misteri'],
    ['Kunci yang Hilang di Perpustakaan', 'rakbuku', '1,3Jt', '34', 'perpustakaan,detektif,sekolah'],
    ['Jejak di Kebun Teh', 'hijaupagi', '960Rb', '37', 'kebun,detektif,keluarga'],
    ['Surat Tanpa Nama', 'anonimabu', '1,7Jt', '42', 'surat,rahasia,misteri'],
  ],
  'Thriller': [
    ['Lima Menit Sebelum Gelap', 'detikmalam', '2,0Jt', '46', 'tegang,waktu,thriller'],
    ['Saksi Terakhir', 'bayangtipis', '1,2Jt', '35', 'saksi,kota,thriller'],
    ['Pesan dari Nomor Asing', 'sinyalhilang', '1,6Jt', '40', 'pesan,misteri,thriller'],
    ['Lift Lantai Tiga Belas', 'gedungtua', '890Rb', '28', 'gedung,tegang,thriller'],
  ],
  'Horor': [
    ['Penunggu Sekolah Tua', 'malamjumat', '2,6Jt', '52', 'sekolah,hantu,horor'],
    ['Boneka di Loteng', 'senyapdesa', '1,4Jt', '33', 'boneka,rumah,horor'],
    ['Jalan Pulang yang Salah', 'kabutmalam', '1,0Jt', '30', 'perjalanan,mistis,horor'],
    ['Kos Lantai Dua', 'lampuredup', '1,8Jt', '41', 'kos,mistis,horor'],
  ],
  'Humor': [
    ['Emak vs Grup WhatsApp', 'ketawaterus', '2,3Jt', '48', 'komedi,keluarga,humor'],
    ['Anak Rantau Kena Mental', 'rantauceria', '1,7Jt', '37', 'rantau,komedi,humor'],
    ['Tetangga Absurd', 'gangsempit', '1,1Jt', '32', 'tetangga,komedi,humor'],
    ['Kisah Kucing Bos Kantor', 'meongkerja', '1,5Jt', '39', 'kantor,kucing,humor'],
  ],
  'Acak': [
    ['Hari Ketika Hujan Berhenti', 'rintikpagi', '1,3Jt', '27', 'acak,hujan,kehidupan'],
    ['Catatan di Balik Jendela', 'jendelakata', '760Rb', '21', 'acak,catatan,harian'],
    ['Rumah di Ujung Gang', 'gangbuntu', '1,0Jt', '30', 'acak,rumah,keluarga'],
  ],
  'Cerita Pendek': [
    ['Surat dari Stasiun Kecil', 'stasiunsenja', '540Rb', '3', 'cerpen,surat,rindu'],
    ['Payung Biru', 'hujanbulan', '430Rb', '2', 'cerpen,hujan,persahabatan'],
    ['Kopi Terakhir Ayah', 'seduhkata', '820Rb', '4', 'cerpen,keluarga,haru'],
  ],
  'Fiksi Umum': [
    ['Pulang ke Kampung Halaman', 'tanahkelahiran', '1,6Jt', '36', 'keluarga,kampung,kehidupan'],
    ['Warung Bu Tinah', 'dapurkata', '1,1Jt', '33', 'warung,tetangga,kehidupan'],
    ['Anak Sulung', 'kakaktertua', '1,9Jt', '42', 'keluarga,tanggungjawab,haru'],
  ],
  'ChickLit': [
    ['Bos Baru di Lantai Lima', 'kantorkata', '2,0Jt', '44', 'kantor,komedi,chicklit'],
    ['Resep Cinta Chef Amel', 'dapurhati', '1,4Jt', '38', 'masak,cinta,chicklit'],
    ['Mulai dari Nol Lagi', 'ketikmanis', '1,2Jt', '35', 'karier,cinta,chicklit'],
  ],
  'Spiritual': [
    ['Langkah Menuju Subuh', 'hijrahpelan', '1,5Jt', '34', 'hijrah,doa,spiritual'],
    ['Titipan Ibu', 'doaibu', '1,1Jt', '29', 'keluarga,doa,spiritual'],
    ['Senja di Serambi Masjid', 'serambikata', '930Rb', '31', 'masjid,teman,spiritual'],
  ],
  'Fiksi Sejarah': [
    ['Surat dari Tanah Jawa', 'babadkata', '1,2Jt', '39', 'sejarah,kerajaan,perjuangan'],
    ['Pelabuhan Sunda Kelapa', 'layarlama', '860Rb', '32', 'pelabuhan,dagang,sejarah'],
    ['Kereta Terakhir 1945', 'rodabesi', '1,0Jt', '37', 'kemerdekaan,kereta,sejarah'],
  ],
  'Nonfiksi': [
    ['Belajar Menulis dari Nol', 'pelatihpena', '1,4Jt', '25', 'menulis,tips,nonfiksi'],
    ['Catatan Anak Rantau', 'rantaujujur', '980Rb', '28', 'rantau,pengalaman,nonfiksi'],
    ['Kebiasaan Kecil, Hidup Besar', 'harikecil', '1,7Jt', '30', 'kebiasaan,motivasi,nonfiksi'],
  ],
  'Fiksi Ilmiah': [
    ['Koloni di Bulan Biru', 'astronotkata', '1,8Jt', '46', 'luar angkasa,koloni,fiksiilmiah'],
    ['Kode Terakhir', 'robotpuisi', '1,2Jt', '36', 'robot,masa depan,fiksiilmiah'],
    ['Kota di Atas Awan', 'langitlipat', '990Rb', '33', 'kota,teknologi,fiksiilmiah'],
  ],
  'Petualangan': [
    ['Peta di Balik Lemari', 'penjelajahcilik', '1,7Jt', '41', 'peta,harta,petualangan'],
    ['Menyusuri Sungai Barito', 'arusderas', '1,0Jt', '35', 'sungai,hutan,petualangan'],
    ['Ekspedisi Gunung Sunyi', 'pendakikata', '1,3Jt', '38', 'gunung,teman,petualangan'],
  ],
  'Vampir': [
    ['Tamu Malam di Rumah Tua', 'bulanmerah', '1,5Jt', '40', 'vampir,rumah,fantasi'],
    ['Perpustakaan Abadi', 'abadikata', '880Rb', '32', 'vampir,buku,misteri'],
    ['Senja Tak Pernah Usai', 'senjagelap', '1,1Jt', '36', 'vampir,kota,fantasi'],
  ],
  'Manusia Serigala': [
    ['Bulan Purnama di Desa Kabut', 'auman', '1,9Jt', '43', 'serigala,desa,fantasi'],
    ['Kawanan Terakhir', 'rimbaraya', '1,2Jt', '37', 'serigala,kawanan,petualangan'],
    ['Penjaga Hutan Utara', 'taringperak', '940Rb', '30', 'serigala,hutan,persahabatan'],
  ],
  'Paranormal': [
    ['Kamera Tua Nenek', 'lensagaib', '1,6Jt', '38', 'misteri,kamera,paranormal'],
    ['Radio yang Menyala Sendiri', 'gelombangsunyi', '1,0Jt', '31', 'radio,rumah,paranormal'],
    ['Murid Baru Kelas Sebelah', 'bisikmalam', '1,4Jt', '35', 'sekolah,misteri,paranormal'],
  ],
  'Puisi': [
    ['Kumpulan Rindu Sederhana', 'sajakpagi', '720Rb', '40', 'puisi,rindu,sajak'],
    ['Hujan dalam Bait', 'baitsenja', '650Rb', '35', 'puisi,hujan,sajak'],
    ['Surat untuk Diri Sendiri', 'kataperlahan', '910Rb', '28', 'puisi,semangat,sajak'],
  ],
  'Klasik': [
    ['Siti di Tepi Telaga', 'hikayatlama', '1,1Jt', '30', 'klasik,desa,hikayat'],
    ['Salah Pilih Jalan', 'balaipustaka', '860Rb', '27', 'klasik,keluarga,hikayat'],
    ['Layar Terkembang di Pantai', 'kisahdulu', '980Rb', '33', 'klasik,laut,hikayat'],
  ],
};

const _covers = <Color>[
  Color(0xFF1B2433),
  Color(0xFF8E7BB5),
  Color(0xFFE6D9EC),
  Color(0xFFBFD6EA),
  Color(0xFF6F7B66),
  Color(0xFFFFD84D),
  Color(0xFF2A2A2A),
  Color(0xFFF4F1EA),
];
const _coverText = <Color>[
  Colors.white,
  Colors.white,
  Color(0xFF4A3B5C),
  Color(0xFF3B5B7C),
  Colors.white,
  Color(0xFF8A4B14),
  Colors.white,
  Color(0xFF3B5B9C),
];

Story _fromRow(List<String> r, int i) => Story(r[0], r[1], r[2],
    int.parse(r[3]), r[4].split(','), _covers[i % _covers.length],
    _coverText[i % _coverText.length]);

/// Daftar cerita untuk satu kategori di halaman Telusuri.
List<Story> storiesFor(String cat) {
  if (ServerStories.loaded) return ServerStories.byCategory(cat);
  if (cat == 'Romansa') return [...ranking, ...finalists];
  final rows = _bank[cat] ?? const <List<String>>[];
  return [
    for (var i = 0; i < rows.length; i++) _fromRow(rows[i], i + cat.length)
  ];
}

List<Story> _collectAll() {
  final seen = <String>{};
  final out = <Story>[];
  for (final s in [
    ...featured,
    ...finalists,
    ...ranking,
    for (final c in kCategories) ...storiesFor(c),
  ]) {
    if (seen.add(s.title)) out.add(s);
  }
  return out;
}

/// Semua cerita (tanpa duplikat) untuk pencarian.
final List<Story> _localAll = _collectAll();
List<Story> get allStories =>
    ServerStories.loaded ? ServerStories.all : _localAll;
