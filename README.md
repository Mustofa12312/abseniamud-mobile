# IAIMU Mobile Attendance App (Android)
**Institut Agama Islam Miftahul Ulum Pamekasan**

Aplikasi presensi kehadiran resmi berbasis Android (Flutter + Dart) yang terhubung langsung dengan backend **Laravel REST API** di `https://api.iaimiftahululum.com/api`.

---

## 🌟 Fitur Utama

### 1. Desain UI Modern, Mewah & Profesional
- **Identitas Kampus Islam**: Palet warna Emerald Green (`#16A34A`, `#15803D`, `#052E16`) dan aksen Warm Amber (`#F59E0B`).
- **Material 3 & Glassmorphic Cards**: Tipografi Google Fonts Inter, bayangan lembut, dan sudut melengkung modern.
- **Header Dinamis**: Menampilkan salam islami, nama dosen/tendik, role badge, serta jam digital real-time dengan format WIB dan penanggalan bahasa Indonesia.
- **Animasi Radar GPS**: Efek radar pulsing konsentris interaktif untuk visualisasi pemindaian satelit dan geofence kampus.

### 2. Terhubung Penuh dengan Laravel Backend API
- **Base URL**: `https://api.iaimiftahululum.com/api` (dapat dikonfigurasi fleksibel via dialog pengaturan server).
- **Authentication**: `POST /auth/login`, `POST /auth/logout`, `GET /me`.
- **Presensi**:
  - `GET /attendance/today` (Status real-time hari ini: Masuk, Pulang, Libur).
  - `POST /attendance/check-in` (Validasi latitude, longitude, akurasi, dan lokasi kampus).
  - `POST /attendance/check-out` (Presensi pulang).
  - `GET /attendance/history` (Riwayat lengkap presensi dengan filter bulan & tahun).
  - `GET /attendance/summary` (Rekap bulanan: Hadir, Terlambat, Izin/Sakit, Alpha).
- **Jadwal & Pengumuman**:
  - `GET /schedules` (Jadwal mengajar dosen dikelompokkan per hari: Senin - Minggu).
  - `GET /announcements` (Pengumuman resmi dari pimpinan kampus).
- **Pengajuan Koreksi Presensi**:
  - `POST /attendance/corrections` & `GET /attendance/corrections` (Form pengajuan lupa check-in/out, tugas luar, atau dinas luar).

---

### 3. Proteksi Anti Fake Location (Mock Location / Fake GPS Prevention)
- Menggunakan deteksi native Android via `isMocked` flag dari provider sistem operasi.
- Deteksi anomali akurasi GPS dan aplikasi pemalsu koordinat.
- **Sistem Pemblokiran Otomatis**:
  - Jika mock location / Fake GPS terdeteksi, tombol Check-In dan Check-Out langsung **DIBLOKIR**.
  - Menampilkan banner peringatan keamanan merah dan dialog pemblokiran: *"LOKASI PALSU (MOCK LOCATION) TERDETEKSI: Presensi dibatalkan demi keamanan dan integritas data kampus IAIMU."*
  - Saat GPS bersih dan asli dari hardware perangkat, sistem menampilkan badge hijau: *"Keamanan GPS Terverifikasi: Koordinat Asli Perangkat"*.

---

### 4. Deteksi Identitas Perangkat (Device Fingerprinting & Binding)
- Mendeteksi secara akurat:
  - **Merk & Produsen**: Samsung, Xiaomi, Google, Oppo, Vivo, dll.
  - **Model Perangkat**: SM-S911B, Redmi Note 12, Pixel 7, dll.
  - **Sistem Operasi**: Android 14, Android 13 (beserta SDK Level API).
  - **Status Perangkat**: Perangkat Fisik Asli (*Physical Hardware*) vs Emulator.
  - **Device Fingerprint UUID**: ID unik perangkat yang disimpan secara persisten.
- Mengirimkan `device_name` saat login dan mencantumkan metadata perangkat dalam header HTTP request:
  - `User-Agent: IAIMU-Android/1.0 (...)`
  - `X-Device-Id: IAIMU-XXXXXXXX`
  - `X-Device-Model: ...`
- Menampilkan kartu identitas perangkat resmi di halaman **Profil & Keamanan** dan konfirmasi presensi.

---

## 📱 Struktur Navigasi Aplikasi

```text
IAIMU Mobile
├── 0. Splash Screen (Animasi logo IAIMU, deteksi hardware, inisialisasi sesi)
├── 1. Login Screen (Portal masuk akun, banner deteksi HP, konfigurasi endpoint)
└── 2. Main Navigation (Bottom Navigation Bar)
    ├── Tab 1: Beranda / Dashboard (Status presensi hari ini, jam digital, rekap 4-grid, jadwal kuliah hari ini, pengumuman)
    ├── Tab 2: Presensi (Radar GPS pulsing, pemilih gedung kampus, koordinat live, akurasi, geofence, tombol check-in/out)
    ├── Tab 3: Riwayat (Filter bulan & tahun, timeline kehadiran, bottom sheet detail presensi, shortcut koreksi)
    ├── Tab 4: Jadwal (Tab jadwal kuliah hari Senin s/d Minggu beserta ruang kelas dan jam kuliah)
    └── Tab 5: Profil & Keamanan (Info akun dosen, NIDN/NIP, Card Identitas Perangkat Terdeteksi, Status Keamanan, Logout)
```

---

## 🛠️ Menjalankan & Membangun Aplikasi

### Jalankan di Emulator / Perangkat Android:
```bash
flutter run
```

### Build APK Debug:
```bash
flutter build apk --debug
# Hasil build: build/app/outputs/flutter-apk/app-debug.apk
```

### Build APK Release (Produksi):
```bash
flutter build apk --release
# Hasil build: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 File Artefak APK yang Sudah Dihasilkan

- **Release APK (Optimized, 55 MB)**:
  `iaimu-mobile/build/app/outputs/flutter-apk/app-release.apk`
- **Debug APK (169 MB)**:
  `iaimu-mobile/build/app/outputs/flutter-apk/app-debug.apk`
