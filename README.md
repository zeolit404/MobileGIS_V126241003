# 📱 Praktek Mobile GIS — Universitas Hasanuddin

Repositori ini berisi kode sumber aplikasi **Praktek Mobile GIS** berbasis **Flutter (Dart)** yang dikembangkan sesuai dengan Rencana Pembelajaran Semester (RPS) Program Studi D4 Penginderaan Jauh dan Sistem Informasi Geografis, Fakultas Vokasi, Universitas Hasanuddin.

---

## 👤 Identitas Mahasiswa
* **Nama** : M. Arief Abdillah
* **NIM** : V126241003
* **Program Studi** : D4 Penginderaan Jauh dan Sistem Informasi Geografis (PJ-SIG)
* **Fakultas** : Fakultas Vokasi, Universitas Hasanuddin
* **Mata Kuliah** : Praktek Mobile GIS (2026)
* **Dosen Pengampu** : Dr. Agus Aris, S.Kel., M.Sc.

---

## 🚀 Fitur Aplikasi (Pertemuan 5 – 12)

Aplikasi ini mengintegrasikan seluruh komponen inti Mobile GIS dari sisi antarmuka, pemetaan digital, sensor GNSS, akuisisi foto, hingga penyimpanan database lokal:

### 1. 🧭 Antarmuka & Navigasi (Pertemuan 5 - 6)
* Mengadopsi **Material 3 UI** dengan tema warna hijau khas geospasial.
* Menggunakan **Bottom Navigation Bar 3 Tab**:
  * 🗺️ **Peta**: Visualisasi peta digital dan pemantauan posisi pengguna.
  * 📝 **Survei**: Form digital akuisisi titik fasilitas lapangan.
  * 📜 **Riwayat**: Riwayat data survei tersimpan.

### 2. 🗺️ Integrasi Peta Digital Multi-Layer (Pertemuan 7)
* Menggunakan pustaka `flutter_map` dan `latlong2`.
* **Multi-Basemap Switcher**:
  * **OpenStreetMap (OSM)**: Peta vektor jalan publik.
  * **Google Satellite**: Citra satelit resolusi tinggi dari Google Maps Tile Server.
* **Marker Layer**:
  * Marker referensi statis di kawasan Kampus Universitas Hasanuddin Tamalanrea (`-5.1357, 119.4886`).
  * Kontrol floating button untuk *Zoom In*, *Zoom Out*, dan *Re-center*.
  * Tampilan *Head-Up Display* (HUD) koordinat Latitude & Longitude real-time.

### 3. 📍 Integrasi GPS & Lokasi Real-Time (Pertemuan 8)
* Menggunakan pustaka `geolocator` untuk komunikasi dengan sensor GNSS/GPS perangkat.
* Modul service terisolasi (`LocationService`) untuk validasi layanan lokasi dan izin akses (`ACCESS_FINE_LOCATION`).
* **Live Position Tracking**: Marker biru lokasi pengguna yang otomatis bergerak mengikuti posisi surveyor secara real-time.

### 4. 📋 Form Survei Lapangan & Foto Geotagging (Pertemuan 9 - 11)
* Input terstruktur: Nama Objek/Fasilitas, Kategori (Pendidikan, Ibadah, Kesehatan, Olahraga, Fasilitas Umum), dan Catatan Keterangan.
* Tombol **"Ambil Lokasi Sekarang"** untuk *lock* koordinat GPS dan nilai akurasi (meter).
* Integrasi kamera dan galeri menggunakan `image_picker` dan `path_provider` untuk mendokumentasikan foto objek langsung di lapangan.

### 5. 💾 Database Lokal SQLite (Pertemuan 12)
* Penyimpanan *offline-first* menggunakan `sqflite`.
* Tabel data `survey_points` untuk menyimpan seluruh record survei: ID, nama, kategori, deskripsi, koordinat (lat/long), alamat path foto, dan timestamp akuisisi.

---

## 🛠️ Stack Teknologi

| Komponen | Teknologi / Package |
|---|---|
| **Framework** | Flutter (Dart SDK 3.13+) |
| **Peta Digital** | `flutter_map: ^7.0.2` & `latlong2: ^0.9.1` |
| **GPS / GNSS** | `geolocator: ^14.0.0` |
| **Kamera & Geotag** | `image_picker: ^1.1.2` |
| **Database Lokal** | `sqflite: ^2.3.3+1` & `path_provider: ^2.1.4` |
| **HTTP / Server** | `http: ^1.2.2` |
| **Target Platform** | Android (Min SDK 26, Target SDK 34/36) |

---

## 📥 Download Aplikasi (APK Siap Install)

File APK siap pakai dapat diunduh langsung melalui menu **GitHub Releases**:
👉 **[Download APK via GitHub Releases (v1.0.0)](https://github.com/zeolit404/MobileGIS_V126241003/releases/latest)**

Pilih file asset **`app-arm64-v8a-release.apk`** untuk di-install pada smartphone Android.

---

## 📂 Struktur Direktori Proyek

```text
praktek_mobile_gis/
├── android/                   # Konfigurasi native Android & AndroidManifest.xml (Permissions)
├── lib/
│   ├── db/
│   │   └── database_helper.dart      # Singleton SQLite Database Manager
│   ├── models/
│   │   └── survey_point.dart         # Data Model Titik Survei
│   ├── screens/
│   │   ├── home_page.dart            # Navigasi Bottom Bar (Peta, Survei, Riwayat)
│   │   ├── map_page.dart             # Peta OSM, Google Satelit, & Live GPS Marker
│   │   ├── survey_form_page.dart     # Form Survei, GPS Capture & Kamera
│   │   └── history_page.dart         # Tampilan Riwayat Survei
│   ├── services/
│   │   └── location_service.dart     # Service Pengambil Koordinat & Stream GPS
│   └── main.dart                     # Entry point aplikasi & tema Material 3
├── pubspec.yaml               # Deklarasi dependencies Flutter
└── README.md                  # Dokumentasi resmi proyek
```

---

## ⚡ Cara Menjalankan Proyek

1. **Clone repository ini:**
   ```bash
   git clone https://github.com/zeolit404/MobileGIS_V126241003.git
   cd MobileGIS_V126241003
   ```

2. **Unduh dependencies:**
   ```bash
   flutter pub get
   ```

3. **Jalankan pada perangkat HP Android fisik (Mode Debug):**
   ```bash
   flutter run
   ```

4. **Build APK Release Siap Pakai:**
   ```bash
   flutter build apk --split-per-abi
   ```
   *File APK akan berada pada direktori: `build/app/outputs/flutter-apk/`*

---

*Dikembangkan untuk Praktikum Mobile GIS 2026 — Program Studi D4 Penginderaan Jauh & SIG, Universitas Hasanuddin.*
