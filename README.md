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

## 🚀 Fitur Aplikasi Lengkap

Aplikasi ini mengintegrasikan seluruh komponen inti Mobile GIS dari sisi antarmuka, pemetaan digital, sensor GNSS, akuisisi foto, hingga penyimpanan database lokal dan ekspor data multi-format:

### 1. 🧭 Antarmuka & Navigasi Modern (Material 3)
* Mengadopsi **Material 3 UI** bertema warna profesional *Dark Slate Blue* & aksen *Royal Blue/Teal*.
* **Bottom Navigation Bar 3 Tab**:
  * 🗺️ **Peta RBI**: Visualisasi peta digital, kontrol layer, dan popup data spasial.
  * 📝 **Survei**: Form digital akuisisi titik, garis, dan area fasilitas lapangan.
  * 📜 **Riwayat**: Tabel rekapitulasi data survei dan ekspor multi-format.

### 2. 🗺️ Integrasi Peta Digital Multi-Layer & Peta Dasar BIG
* Menggunakan pustaka `flutter_map` dan `latlong2`.
* **Multi-Basemap Switcher (Dengan Pengunci Posisi Kamera)**:
  * **Peta Dasar RBI (BIG)**: Peta dasar Rupabumi Indonesia resmi dari Badan Informasi Geospasial (ArcGIS REST Tile).
  * **Google Satellite**: Citra satelit resolusi tinggi.
  * **OpenStreetMap (OSM)**: Peta vektor jalan publik.
* **Visualisasi Geometri Lengkap**:
  * Render **Titik (Point)** dengan marker interaktif.
  * Render **Garis (Line)** untuk jalan, jalur survei, atau sungai.
  * Render **Area (Polygon)** berarsir untuk batas lahan atau blok fasilitas.
* Kontrol navigasi: *Zoom In*, *Zoom Out*, *Re-center GPS*, dan status *Mode Online/Offline*.

### 3. 📍 Sensor GNSS & Input Koordinat Fleksibel
* Pustaka `geolocator` untuk komunikasi dengan sensor GNSS/GPS perangkat.
* Modul service terisolasi (`LocationService`) untuk validasi layanan lokasi dan izin akses (`ACCESS_FINE_LOCATION`).
* **Live Position Tracking**: Marker live posisi surveyor di lapangan.
* **Input Mandiri / Kunci GPS**: Surveyor dapat mengunci koordinat otomatis via satelit atau memasukkan angka Latitude & Longitude secara mandiri.

### 4. 🌦️ Widget Cuaca Real-Time Lokasi Survei
* Integrasi REST API Open-Meteo untuk membaca suhu dan kondisi cuaca terkini di Kota Makassar (Kampus Unhas Tamalanrea).
* Tersemat langsung pada header Laman Survei untuk memantau kelayakan cuaca operasional lapangan.

### 5. 📊 Ekspor Data Lapangan Multi-Format (PDF, Excel, CSV, Word)
* **Format PDF**: Laporan resmi ber-Kop Dokumen Program Studi D4 PJ-SIG Universitas Hasanuddin siap cetak/arsip.
* **Format Excel (.xlsx)**: Spreadsheet terstruktur untuk pengolahan analisis tabular lanjutan di Microsoft Excel.
* **Format CSV**: Standar industri geospasial yang kompatibel langsung diimpor ke software **QGIS** dan **ArcGIS**.
* **Format Word (.doc / .docx)**: Format dokumen Microsoft Word yang dapat diedit langsung.

### 6. 💾 Database Hybrid & Cross-Platform Safe Image
* Penyimpanan *offline-first* dengan dual storage: SQLite (`sqflite`) pada perangkat Android native dan in-memory store saat dijalankan pada web/desktop.
* Penanganan gambar anti-crash (`_Namespace`) dengan kompilasi kondisional (`platform_image_helper.dart` & `file_saver.dart`) yang mendukung Base64 dan file lokal.

---

## 🛠️ Stack Teknologi

| Komponen | Teknologi / Package |
|---|---|
| **Framework** | Flutter (Dart SDK 3.13+) |
| **Peta Digital** | `flutter_map: ^8.3.2` & `latlong2: ^0.10.1` |
| **GPS / GNSS** | `geolocator: ^14.0.0` |
| **Kamera & Geotag** | `image_picker: ^1.1.2` |
| **Database Lokal** | `sqflite: ^2.3.3+1` & `path_provider: ^2.1.4` |
| **Ekspor Data** | `pdf: ^3.12.0`, `excel: ^4.0.6`, `csv: ^8.0.0`, `printing: ^5.14.3` |
| **Cuaca / HTTP** | `http: ^1.2.2` (Open-Meteo REST API) |
| **Target Platform** | Android (Min SDK 26, Target SDK 34/36) & Web |

---

## 📥 Download Aplikasi (APK Siap Install)

File APK rilis terbaru siap pakai dapat diunduh langsung melalui menu **GitHub Releases**:
👉 **[Download APK via GitHub Releases](https://github.com/zeolit404/MobileGIS_V126241003/releases/latest)**

Pilih file asset **`app-arm64-v8a-release.apk`** untuk di-install pada smartphone Android.

---

## 📂 Struktur Direktori Proyek

```text
praktek_mobile_gis/
├── android/                   # Konfigurasi native Android & AndroidManifest.xml (Permissions)
├── lib/
│   ├── db/
│   │   └── database_helper.dart      # Hybrid SQLite & Memory Store Database Manager
│   ├── models/
│   │   └── survey_point.dart         # Data Model Titik, Garis, & Poligon Survei
│   ├── screens/
│   │   ├── home_page.dart            # Navigasi Bottom Bar, Header Cuaca, & Mode Peta
│   │   ├── map_page.dart             # Peta Dasar RBI, Google Satelit, OSM & Geometri Layer
│   │   ├── survey_form_page.dart     # Form Geometri, Input Mandiri, GPS & Akuisisi Foto
│   │   └── history_page.dart         # Tabel Rekap Survei & Tombol Menu Ekspor
│   ├── services/
│   │   ├── export_service.dart       # Generator Ekspor PDF, Excel, CSV, & Word
│   │   ├── location_service.dart     # Service Pengambil Koordinat & Stream GPS
│   │   └── weather_service.dart      # Integrasi REST API Cuaca Makassar
│   ├── utils/
│   │   ├── file_saver.dart           # Cross-platform File Saver (Web & Mobile)
│   │   └── platform_image_helper.dart# Cross-platform Safe Image Handler
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
