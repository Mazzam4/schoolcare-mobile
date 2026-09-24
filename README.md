# SchoolCare - Mobile App (Flutter)

SchoolCare adalah aplikasi pelaporan fasilitas dan kebersihan sekolah berbasis mobile. Aplikasi ini membantu sekolah menjaga lingkungan tetap bersih dan terawat melalui sistem pelaporan yang cepat, akurat dengan GPS, dan interaktif.

## Arsitektur Full-Stack

Proyek ini dibangun menggunakan arsitektur full-stack dan dipisah menjadi dua repositori:

1. **Frontend / Mobile App**: Flutter dan Dart, yaitu repositori ini.
2. **Backend & API**: Node.js, Express, dan PostgreSQL.

Backend dan database telah di-deploy ke Vercel dan Neon.tech. Karena itu, pengguna cukup menjalankan aplikasi mobile ini; aplikasi akan terhubung ke server cloud yang telah dikonfigurasi.

Repositori backend: [SchoolCare Backend](https://github.com/Mazzam4/schoolcare-backend)

## Persyaratan

- Flutter SDK 3.11.5 atau yang kompatibel
- Dart SDK yang disertakan dalam Flutter SDK
- Android Studio dengan emulator Android, atau perangkat Android fisik
- VS Code dengan ekstensi Flutter dan Dart (opsional)

## Cara Menjalankan Aplikasi

### 1. Unduh kode

Unduh kode melalui **Code > Download ZIP**, lalu ekstrak, atau clone repositori ini menggunakan Git.

```bash
git clone <URL_REPOSITORI_FRONTEND>
cd school_care
```

### 2. Buka proyek

Buka folder proyek menggunakan VS Code atau Android Studio.

### 3. Unduh dependencies

Jalankan perintah berikut dari terminal di root proyek:

```bash
flutter pub get
```

### 4. Jalankan aplikasi

Pastikan emulator Android aktif atau perangkat fisik tersambung dengan USB Debugging. Kemudian jalankan:

```bash
flutter run
```

Aplikasi juga dapat dijalankan pada browser Chrome dengan perintah berikut:

```bash
flutter run -d chrome
```

## Konfigurasi API Server

Konfigurasi tujuan API berada di [lib/core/api_config.dart](lib/core/api_config.dart). Aplikasi saat ini menggunakan server produksi berikut:

```dart
static const String baseUrl = "https://schoolcare-backend.vercel.app";
```

Konfigurasi tambahan mungkin diperlukan untuk fitur lokasi dan Google Maps, terutama saat menjalankan aplikasi pada perangkat atau platform baru.

## Alur Pengujian

Untuk mencoba fitur aplikasi secara maksimal, lakukan alur berikut:

1. Daftar sebagai pengguna baru atau masuk menggunakan akun yang tersedia.
2. Buat organisasi/sekolah atau bergabung dengan sekolah menggunakan kode undangan.
3. Buat laporan fasilitas atau kebersihan dengan foto, deskripsi, dan lokasi GPS.
4. Periksa laporan pada halaman daftar laporan dan riwayat.
5. Perbarui status laporan jika memiliki hak akses yang sesuai.
6. Periksa dashboard, grafik, daftar anggota, dan profil pengguna.

Untuk menjalankan pemeriksaan otomatis:

```bash
flutter test
```

## Tech Stack

- **UI & Frontend**: Flutter, Dart, Material Design
- **State Management**: Riverpod, StatefulWidget, dan StatelessWidget
- **Network & API**: Dio, REST API
- **Penyimpanan lokal**: Shared Preferences dan SQLite
- **Pelaporan lokasi**: Geolocator dan Google Maps
- **Media**: Image Picker dan encoding Base64
- **Visualisasi data**: FL Chart
- **Backend**: Node.js, Express, dan PostgreSQL
- **Deployment**: Vercel dan Neon.tech
