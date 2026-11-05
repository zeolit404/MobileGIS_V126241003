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

### 1. 🧭 Antarmuka Modern & Pengubah Tema (Dark/Light Mode)
* Mengadopsi **Material 3 UI** bertema warna profesional *Dark Slate Blue* & aksen *Royal Blue/Teal*.
* **Tombol Pengubah Tema Interaktif**: Beralih instan antara **Mode Terang (Light Mode)** dan **Mode Gelap (Dark Mode)** langsung dari AppBar.
* **Bottom Navigation Bar 3 Tab**:
  * 🗺️ **Peta RBI**: Visualisasi peta digital multi-layer, kompas orientasi utara, dan popup data spasial.
  * 📝 **Survei**: Form digital akuisisi titik, garis, dan area lengkap dengan dukungan sistem koordinat WGS 84 dan UTM.
  * 📜 **Riwayat**: Tabel rekapitulasi data survei dan ekspor multi-format ber-geotagging.

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
* Kontrol navigasi: *Zoom In*, *Zoom Out*, *Re-center GPS*, dan **Tombol Reset Arah Utara (Kompas)**.

### 3. 🌐 Dual Sistem Koordinat: WGS 84 & UTM (Universal Transverse Mercator)
* **Sistem Koordinat WGS 84 (Geografis)**: Penginputan format Latitude & Longitude dengan konversi otomatis ke proyeksi metrik UTM.
* **Sistem Koordinat UTM (Proyeksi Metrik)**: Penginputan berbasis Easting (X dalam meter) dan Northing (Y dalam meter) dengan pemilihan Zona UTM (default: **Zona 50S** untuk Makassar / Sulsel).
* **Konverter Geodesi Dua Arah Presisi** (`coordinate_converter.dart`) menggunakan konstanta ellipsoid WGS 84 standar.
* **Sensor GNSS & Input Mandiri**: Mengunci koordinat otomatis via satelit GPS atau mengetik koordinat manual.

### 4. 🌦️ Widget Cuaca Real-Time Lokasi Survei
* Integrasi REST API Open-Meteo untuk membaca suhu dan kondisi cuaca terkini di Kota Makassar (Kampus Unhas Tamalanrea).
* Tersemat langsung pada header Laman Survei dengan pembaruan otomatis berkala dan saat membuka tab survei.

### 5. 📊 Ekspor Data Lapangan Ber-Geotagging (PDF, Excel, GeoJSON, CSV, Word)
* **Format PDF**: Laporan resmi ber-Kop Universitas Hasanuddin + **Lampiran Galeri Foto Lapangan Ber-Geotagging**.
* **Format Excel (.xlsx)**: Spreadsheet terstruktur lengkap dengan kolom Foto/Geotagging dan koordinat metrik.
* **Format GeoJSON (.geojson)**: Format vektor standar SIG yang siap dioleh di **QGIS**, **ArcGIS**, dan WebGIS.
* **Format CSV**: Standar tabular SIG dengan kolom status foto dan koordinat geotag.
* **Format Word (.doc / .docx)**: Format dokumen Microsoft Word dengan preview foto dokumentasi langsung di dalam tabel.

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
│   │   ├── home_page.dart            # Navigasi Bottom Bar, Header Cuaca, & Theme Switcher
│   │   ├── map_page.dart             # Peta Dasar RBI, Google Satelit, OSM, Kompas & Geometri
│   │   ├── survey_form_page.dart     # Form Geometri, WGS 84 & UTM, GPS & Akuisisi Foto
│   │   └── history_page.dart         # Rekapitulasi Survei & Menu Ekspor Geotagging
│   ├── services/
│   │   ├── export_service.dart       # Generator Ekspor PDF, Excel, GeoJSON, CSV, & Word
│   │   ├── location_service.dart     # Service Pengambil Koordinat & Stream GPS
│   │   ├── theme_manager.dart        # Pengelola Tema Terang & Gelap (Dark/Light Mode)
│   │   └── weather_service.dart      # Integrasi REST API Cuaca Makassar
│   ├── utils/
│   │   ├── coordinate_converter.dart # Konverter Geodesi Presisi WGS 84 <-> UTM
│   │   ├── file_saver.dart           # Cross-platform File Saver (Web & Mobile)
│   │   └── platform_image_helper.dart# Cross-platform Safe Image Handler
│   └── main.dart                     # Entry point aplikasi & konfigurasi tema M3
├── pubspec.yaml               # Deklarasi dependencies Flutter (v1.2.0)
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
