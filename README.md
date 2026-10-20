
# Wattpret

Aplikasi seluler **Wattpret**, tiruan (clone) dari **Wattpad**, dibuat dengan **Flutter** dan terhubung ke **REST API Laravel** serta database **MySQL**.

Proyek ini dibuat untuk Ujian Tengah Semester (UTS) mata kuliah **Pemrograman Aplikasi Bergerak**, Program Studi Sistem Informasi, Tahun Akademik 2026/2027.

## Identitas Proyek

| | |
|---|---|
| Aplikasi asli | Wattpad |
| Nama plesetan | **Wattpret** |
| Frontend | Flutter (Dart) |
| Backend | Laravel 13 (PHP 8.3) + Laravel Sanctum |
| Database | MySQL |
| Video presentasi & demo | (link YouTube menyusul setelah diunggah) |

## Anggota Kelompok

| No | Nama | NIM | Pembagian Tugas |
|---|---|---|---|
| 1 | Nazwa Aurellia Ababiluna Putri | 24051214226 | Aplikasi Flutter, REST API Laravel, database (bersama Naftaly), README dan repositori, serta koordinasi tim. |
| 2 | Naftaly Akhya Rani Cellolin | 24051214217 | 	Aplikasi Flutter, REST API Laravel, database (bersama Nazwa), README dan repositori.|
| 3 | Galih Triadi Mukti | 24051214225 | Aplikasi Flutter, menyunting dan mengunggah video|
| 4 | Wisnu Aziz Imansyah | 24051214238 | Aplikasi Flutter, menyunting dan mengunggah video |

## Fitur

### 1. Pendaftaran dan Masuk
- **Layar Welcome** dengan pilihan daftar (email, Google, Facebook) dan tombol "Saya sudah memiliki akun".
- **Alur daftar akun baru**: Ceritakan tentang dirimu (email, nama pengguna, tanggal lahir, kata ganti, dengan validasi dan batas usia minimal 13 tahun) → Buat akun (kata sandi) → Verifikasi email → Pilih genre favorit (minimal 1) → Izin notifikasi → Beranda.
- **Aturan kata sandi** ditampilkan langsung: minimal 10 karakter, ada huruf besar dan kecil, angka, dan karakter khusus, tidak memuat nama pengguna, serta harus cocok dengan kolom ulangi kata sandi. Pendaftar wajib menyetujui Persyaratan Layanan dan Kebijakan Privasi.
- **Masuk (Login)** dengan email atau nama pengguna dan kata sandi, dengan tombol tampilkan/sembunyikan kata sandi dan pesan kesalahan dari API.
- **Lupa kata sandi** dengan email atau nama pengguna.
- **Sesi tersimpan**: token disimpan di perangkat sehingga pengguna tidak perlu masuk ulang.
- **Keluar** dengan dialog konfirmasi dan layar loading, lalu kembali ke Welcome.

### 2. Beranda, Telusuri, dan Detail Cerita
- **Beranda**: kategori cerita, "Direkomendasikan untukmu", "Cerita pilihan untuk kamu", "Bacaanmu selanjutnya", dan banner program.
- **Telusuri**: pencarian cerita atau profil, filter, panel semua genre, dan urutkan berdasarkan Terpopuler, Bab terbanyak, atau Judul A-Z.
- **Peringkat Cerita** per tag atau kategori.
- **Detail cerita** dengan tab Ringkasan dan Bab, vote, tambah atau hapus dari Perpustakaan, bagikan cerita, tombol Mulai atau Lanjutkan membaca, dan rekomendasi "Kamu mungkin juga menyukai ini".

### 3. Pembaca (Membaca Cerita)
- Pindah bab sebelumnya dan berikutnya, serta lanjut membaca dari bab terakhir (progres baca tersimpan).
- **Mode Baca**: *Halaman* (geser seperti buku) atau *Gulir* (menggulir ke bawah).
- **Gulir Otomatis** dengan pengaturan kecepatan (kura-kura sampai kelinci).
- **Tampilan bacaan**: ukuran huruf, pilihan font (Georgia, Times New Roman, Arial), dan warna halaman (putih, hitam, krem, atau ikut pengaturan aplikasi).
- **Preferensi Membaca**: kunci orientasi layar, komentar dalam paragraf dan reaksi, serta preferensi Lewati Iklan.
- **Komentar dan reaksi** per bab maupun per paragraf, lengkap dengan balasan dan jumlah komentar tiap paragraf.
- Catatan Penulis, vote bab, dan ajakan menambahkan cerita ke Perpustakaan serta mengikuti penulis.
- **Bagikan** (WhatsApp, Kirim ke Profil, Salin Tautan, Facebook) dan **Laporkan**.
- Penanda "Tersedia offline" untuk bab yang diunduh.

### 4. Perpustakaan
- Simpan dan hapus cerita dari Perpustakaan.
- Urutkan berdasarkan: baru saja dibaca, baru saja diperbarui, baru ditambahkan, judul cerita, atau penulis.
- Tandai cerita untuk diunduh (offline), dengan bagian "Tersedia Offline" terpisah dari "Cerita yang Disimpan".
- Arsipkan cerita dan kelola arsip.
- Status progres baca tiap cerita.
- **Daftar bacaan (reading list)**: buat, ubah, hapus, tambah cerita, atur privasi **Publik** atau **Pribadi**, bagikan tautan daftar, dan sukai daftar milik orang lain (halaman "Daftar bacaan yang disukai").

### 5. Menulis dan Karya Saya
- Tab **Tulis**: Lanjutkan menulis, Buat cerita baru, Seri, Sumber daya kepenulisan, Program dan peluang.
- **Buat cerita**: sampul, judul, deskripsi, tag, fandom, genre, bahasa cerita, jenis cerita, tanda konten dewasa, dan status tamat.
- **Editor bab**: judul bab, isi bab, polling, simpan sebagai konsep (draf), pratinjau, dan riwayat revisi.
- **Sisipkan media di bab**: gambar (kamera atau galeri, bisa beberapa sekaligus) dan video YouTube (cari atau tempel tautan).
- **Karya**: daftar cerita Terpublikasi dan Draf, kelola bab (tambah, hapus, **ubah urutan bab**), edit cerita, batalkan publikasi, lihat sebagai pembaca, dan hapus cerita.
- **Publikasi**: halaman konfirmasi, halaman "Selamat", dan bagikan ke aplikasi lain atau salin tautan.

### 6. Profil dan Sosial
- **Profil sendiri**: tab Karya, Daftar Bacaan, Pengikut, dan Percakapan; status atau deskripsi; jumlah pengikut dan mengikuti.
- **Profil pengguna lain**: ikuti atau berhenti mengikuti, laporkan profil, blokir, dan lihat karya serta daftar bacaan mereka.
- **Dinding pesan** di profil: tulis pesan, balas, dan hapus pesan.
- **Daftar pengikut dan mengikuti**, halaman "Temukan komunitasmu" untuk mencari akun yang diikuti, dan undang teman.
- **Pembaruan**: tab *Feed Sosial* (aktivitas dari penulis yang diikuti), *Notifikasi*, dan *Pesan*.
- Halaman akun resmi komunitas (AmbassadorsID).

### 7. Koin dan Langganan
- Saldo koin, beli paket koin, klaim koin harian, dan tonton iklan untuk bonus koin.
- Preferensi dan penawaran Lewati Iklan.
- Halaman **Langganan Premium dan Premium+** dengan paket bulanan, semi-tahunan, dan tahunan.

### 8. Pengaturan
Menu Pengaturan memuat semua halaman berikut.

**Profil**
- **Ganti foto profil lewat kamera atau file**: pilihan *Mengambil Foto* (kamera), *Pilih dari Galeri* (file gambar), dan *Hapus gambar*. Di web atau desktop, kamera memakai layar kamera bawaan aplikasi dengan tombol ganti kamera.
- **Atur gambar latar belakang** profil dengan pilihan yang sama (kamera, galeri, hapus).
- Foto dan gambar latar diunggah ke server dan tersimpan di akun.
- Nama Tampilan (bisa ditampilkan atau disembunyikan), Lokasi, Bio, Kata Ganti (Laki-laki, Perempuan, Netral), dan Situs Web Pribadi.

**Akun**
- Ubah Nama Pengguna, Email, Kata Sandi, dan Tanggal Lahir.
- **Pengaturan Bacaan**: Mode Baca (*Halaman* atau *Gulir*), Gulir Otomatis dan kecepatannya, Kunci Orientasi Layar, Komentar dalam Paragraf dan Reaksi, dan Preferensi Lewati Iklan.
- **Bahasa cerita** (13 bahasa, di antaranya Bahasa Indonesia, English, Español, Français, Deutsch).
- Tutup Akun.

**Notifikasi**
- Atur kategori pemberitahuan per saluran: Push, Umpan, dan Email.

**Mode gelap**
- Tiga pilihan: **Nonaktif** (terang), **Aktif** (gelap), dan **Otomatis** (mengikuti pengaturan HP). Tampilan seluruh aplikasi langsung berubah.

**Privasi dan Keamanan**
- Preferensi konten: konten dewasa dan **tagar yang diblokir**.
- Akun yang disenyapkan dan akun yang diblokir.

**Langganan**
- Langganan premium.
- **Personalisasi tema**: pilih warna tema aplikasi.

**Lainnya**
- Akun tertaut (Facebook), Undang teman (email, pesan, salin tautan, aplikasi lain).
- Tentang Wattpret: Privasi, Persyaratan Penggunaan, Kode Etik, dan Pedoman Konten.
- Bantuan dan dukungan: Pusat Bantuan, Kirim Tiket Bantuan, Goyangkan untuk Bantuan, Masalah yang Diketahui, Topik Bantuan, dan FAQ.
- Versi aplikasi dan lisensi sumber terbuka.
- Keluar.

## Struktur Repositori

```
wattpret/
├── README.md
├── docs/
│   └── logo.png    # Logo untuk README
├── mobile/     # Aplikasi Flutter (frontend)
└── backend/    # REST API Laravel + migration & seeder database
```

Skema database dibuat lewat migration di `backend/database/migrations/`, dan data contoh (87 cerita dan akun demo) lewat seeder di `backend/database/seeders/`.

## Arsitektur Singkat

```
Flutter App  ──HTTP/JSON (Bearer token)──▶  Laravel REST API  ──▶  MySQL
 (mobile/)                                    (backend/)
```

- Aplikasi memanggil API melalui kelas `Api` di `mobile/lib/api_service.dart`.
- Autentikasi memakai token Laravel Sanctum. Token disimpan di perangkat dengan `shared_preferences`.
- Upload gambar disimpan di disk `public` Laravel (`storage/app/public`).

## Prasyarat

- PHP 8.3 atau lebih baru, Composer
- MySQL (misalnya lewat Laragon atau XAMPP)
- Flutter SDK (Dart 3.5 atau lebih baru)
- Emulator Android, Chrome, atau HP Android

## Menjalankan Backend

Jalankan semua perintah di folder `backend/`.

1. Pasang dependensi:
   ```
   composer install
   ```
2. Salin file environment, lalu buat key:
   ```
   copy .env.example .env
   php artisan key:generate
   ```
3. Buat database kosong bernama `wattpret_db` di MySQL, lalu ubah bagian database di `.env`:
   ```
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=wattpret_db
   DB_USERNAME=root
   DB_PASSWORD=
   APP_TIMEZONE=Asia/Jakarta
   ```
4. Jalankan migration dan isi data contoh:
   ```
   php artisan migrate --seed
   ```
5. Hubungkan folder upload agar gambar bisa diakses:
   ```
   php artisan storage:link
   ```
6. Jalankan server:
   ```
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   API aktif di `http://127.0.0.1:8000/api`.

Untuk mengulang dari awal (menghapus semua data lalu mengisi ulang): `php artisan migrate:fresh --seed`.

## Menjalankan Aplikasi Flutter

Jalankan di folder `mobile/`, dengan backend sudah berjalan.

```
flutter pub get
flutter run
```

Alamat API diatur di `mobile/lib/api_service.dart`:

| Dijalankan di | Alamat yang dipakai |
|---|---|
| Chrome (web) | `http://127.0.0.1:8000/api` (otomatis) |
| Emulator Android | `http://10.0.2.2:8000/api` (bawaan) |
| HP asli | Ubah `_deviceHost` ke IP laptop, misalnya `192.168.1.10`. HP dan laptop harus satu jaringan Wi-Fi. |

## Akun Demo

| Username | Password |
|---|---|
| `demo` | `password123` |

Akun `demo` sudah punya perpustakaan, dua daftar bacaan, pesan, notifikasi, dan 50 koin. Penulis lain dari seeder bisa dipakai masuk dengan username mereka (misalnya `kirana_w`) dan password yang sama.

## Endpoint API

Semua endpoint berada di bawah `/api`. Tanda 🔒 berarti butuh header `Authorization: Bearer <token>`.

| Kelompok | Contoh endpoint |
|---|---|
| Akun | `POST /register`, `POST /login`, `GET /me` 🔒, `PUT /me/password` 🔒 |
| Cerita | `GET /stories`, `GET /stories/{id}`, `POST /stories` 🔒, `GET /ranking`, `GET /search` |
| Bab | `GET /chapters/{id}`, `POST /stories/{id}/chapters` 🔒, `PUT /stories/{id}/chapters/order` 🔒 |
| Komentar | `GET /chapters/{id}/comments`, `GET /chapters/{id}/comment-counts`, `POST /chapters/{id}/comments` 🔒 |
| Perpustakaan | `GET /library` 🔒, `POST /library/{story}` 🔒, `GET /reading-lists` 🔒 |
| Sosial | `POST /users/{username}/follow` 🔒, `GET /feed` 🔒, `GET /notifications` 🔒 |
| Koin | `GET /coins` 🔒, `POST /coins/claim-daily` 🔒 |

Daftar lengkap ada di `backend/routes/api.php`.

## Batasan Versi Demo

Beberapa bagian hanya berupa tampilan (meniru aplikasi asli) dan belum terhubung ke layanan nyata:

- Tombol daftar dan masuk dengan Google atau Facebook, serta berbagi ke Facebook.
- Tutup Akun, pembelian langganan Premium, penawaran koin pihak ketiga, Wattpret Originals, dan impor naskah.
- Pengaturan tampilan dan bacaan (mode gelap, mode baca, personalisasi tema, dan sejenisnya) berlaku selama aplikasi berjalan, tetapi belum disimpan ke server, sehingga kembali ke bawaan setelah aplikasi ditutup.
- Verifikasi email dan lupa kata sandi memakai kode yang dikembalikan API saat mode debug (`APP_DEBUG=true`), bukan email sungguhan.

## Catatan

- Proyek ini dibuat untuk keperluan tugas kuliah dan bukan produk resmi Wattpad.
