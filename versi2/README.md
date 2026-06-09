# Versi 2 - Deteksi Jalur Jalan dengan Mask Warna dan Debug Panel

Folder `versi2/` berisi implementasi lanjutan dari program deteksi jalur jalan. Versi ini dibuat untuk memperbaiki beberapa keterbatasan pada versi 1, terutama ketika garis marka sulit dipertahankan karena variasi warna, pencahayaan, tikungan, garis terputus, atau hasil Hough Transform yang tidak stabil.

## Ringkasan Peningkatan

Versi 2 tetap menggunakan pipeline utama Canny, ROI, dan Hough Transform, tetapi ditambah beberapa mekanisme baru:

- Mask warna marka putih dan kuning berbasis HSV.
- Seleksi edge yang menggabungkan hasil Canny dengan mask warna marka.
- Fallback ke edge ROI biasa jika mask warna terlalu sedikit.
- ROI mode `wide` untuk area jalan yang lebih lebar.
- Validasi geometri garis kiri dan kanan.
- Fallback kurva orde 2 ketika deteksi garis linear gagal.
- Stabilizer dengan batas lompatan posisi antar-frame.
- Video debug panel 2x3 untuk memeriksa proses pada setiap frame.

## Masalah yang Diselesaikan

| Masalah pada versi sebelumnya | Penyelesaian di versi 2 |
| --- | --- |
| Deteksi garis mudah mengambil edge non-marka seperti bayangan, tekstur jalan, atau objek lain. | Ditambahkan mask warna marka putih dan kuning agar edge yang diproses lebih fokus pada kandidat marka jalan. |
| Garis kanan atau kiri dapat hilang saat marka putus-putus atau kontras rendah. | Ditambahkan stabilizer dengan toleransi `maxMiss` dan fallback kurva ketika garis linear tidak terdeteksi. |
| Hasil garis kadang melompat jauh antar-frame. | Ditambahkan validasi lompatan posisi dengan `maxJumpRatioL` dan `maxJumpRatioR`. |
| Garis kiri dan kanan dapat tertukar atau terlalu dekat/tidak masuk akal. | Ditambahkan validasi geometri menggunakan batas posisi sisi kiri/kanan serta rasio lebar jalur minimum dan maksimum. |
| ROI versi awal kurang fleksibel untuk jalan belok atau area marka yang melebar. | Ditambahkan `param.roiMode = 'wide'` dan parameter ROI lebar. |
| Sulit mengevaluasi penyebab kegagalan deteksi hanya dari video output akhir. | Ditambahkan video debug panel yang menampilkan tahapan proses untuk setiap frame. |

## Struktur File

| File | Keterangan |
| --- | --- |
| `code.m` | Program utama versi 2. |
| `README.md` | Dokumentasi versi 2. |
| `video_lane_output_v2_lane_color_mask*.mp4` | Video output final hasil deteksi jalur. |
| `video_debug_panel_v2_lane_color_mask*.mp4` | Video debug panel untuk melihat proses deteksi tiap frame. |
| `proses_1_frame_lane_detection_v2_lane_color_mask*.png` | Gambar panel proses untuk 1 frame contoh. |

## Link Output

Semua output versi 2 dapat diakses melalui folder berikut:

[Google Drive - Folder Output Versi 2](https://drive.google.com/drive/folders/1hSvFT6yzlyAd6vMxQZDTidk_mqHe_FB8?usp=sharing)

## Pasangan Input dan Output

| Input | Video output final | Video debug panel | Panel proses 1 frame |
| --- | --- | --- | --- |
| `../input/video.mp4` | `video_lane_output_v2_lane_color_mask.mp4` | `video_debug_panel_v2_lane_color_mask.mp4` | `proses_1_frame_lane_detection_v2_lane_color_mask.png` |
| `../input/video2.mp4` | `video_lane_output_v2_lane_color_mask2.mp4` | `video_debug_panel_v2_lane_color_mask2.mp4` | `proses_1_frame_lane_detection_v2_lane_color_mask2.png` |
| `../input/video3.mp4` | `video_lane_output_v2_lane_color_mask3.mp4` | `video_debug_panel_v2_lane_color_mask3.mp4` | `proses_1_frame_lane_detection_v2_lane_color_mask3.png` |
| `../input/video4.mp4` | `video_lane_output_v2_lane_color_mask4.mp4` | `video_debug_panel_v2_lane_color_mask4.mp4` | `proses_1_frame_lane_detection_v2_lane_color_mask4.png` |

## Cara Menjalankan

1. Pastikan video input tersedia di folder `input/`.
2. Buka MATLAB.
3. Arahkan *Current Folder* ke folder `versi2/`.
4. Sesuaikan variabel file pada bagian awal `code.m`:

```matlab
inputVideo  = '../input/video2.mp4';
outputVideo = 'video_lane_output_v2_lane_color_mask2.mp4';
outputImage = 'proses_1_frame_lane_detection_v2_lane_color_mask2.png';
debugVideo  = 'video_debug_panel_v2_lane_color_mask2.mp4';
```

5. Jalankan:

```matlab
code
```

Setelah selesai, program akan menyimpan video output final, video debug panel, dan gambar panel proses di folder `versi2/`.

## Opsi Tampilan dan Debug

| Variabel | Fungsi |
| --- | --- |
| `showVideoPreview` | Menampilkan video hasil deteksi final saat program berjalan. |
| `showProcessFigure` | Menampilkan panel proses untuk 1 frame contoh. |
| `makeDebugVideo` | Membuat video debug panel 2x3 untuk seluruh frame. |
| `showDebugVideoPreview` | Menampilkan debug panel berjalan di MATLAB saat proses berlangsung. |

Jika ingin mempercepat proses tanpa jendela preview, ubah opsi tampilan menjadi `false`.

## Alur Pemrosesan Versi 2

1. Membaca frame dari video input.
2. Mengubah frame ke grayscale dan HSV.
3. Membuat mask warna marka putih dan kuning.
4. Menerapkan Gaussian blur dan Canny edge detection.
5. Menggabungkan edge Canny dengan mask warna marka.
6. Membentuk ROI pada area jalan.
7. Memilih edge hasil mask warna atau fallback ke edge ROI biasa.
8. Menerapkan Hough Transform.
9. Memfilter dan memisahkan garis kiri serta kanan.
10. Melakukan validasi geometri garis.
11. Menstabilkan garis antar-frame.
12. Menggunakan fallback kurva jika garis linear gagal.
13. Menggambar hasil deteksi pada frame.
14. Menyimpan video output final.
15. Menyimpan video debug panel dan gambar proses 1 frame.

## Isi Debug Panel

Debug panel digunakan untuk menganalisis proses deteksi secara visual. Panel menampilkan tahapan seperti:

- Frame asli.
- Grayscale.
- Canny edge.
- ROI.
- Mask warna marka putih dan kuning.
- Canny yang sudah dikombinasikan dengan mask warna.
- Kandidat garis kiri dan kanan.
- Output final.

Dengan debug panel, kegagalan deteksi dapat ditelusuri apakah berasal dari mask warna, ROI, Hough Transform, validasi garis, atau fallback kurva.

## Parameter Penting

### Deteksi Garis

| Parameter | Fungsi |
| --- | --- |
| `param.minAngle` dan `param.maxAngle` | Rentang sudut kandidat garis jalur. |
| `param.numPeaks` | Jumlah puncak Hough yang dipertimbangkan. |
| `param.houghThresh` | Ambang batas kekuatan puncak Hough. |
| `param.fillGap` | Jarak maksimum untuk menyambungkan segmen garis. |
| `param.minLength` | Panjang minimum segmen garis yang valid. |

### Mask Warna Marka

| Parameter | Fungsi |
| --- | --- |
| `param.whiteMinValue` | Batas kecerahan minimum untuk marka putih. |
| `param.whiteMaxSaturation` | Batas saturasi maksimum agar piksel dianggap putih/abu terang. |
| `param.yellowHueMin` dan `param.yellowHueMax` | Rentang hue untuk marka kuning. |
| `param.yellowMinSaturation` | Saturasi minimum untuk marka kuning. |
| `param.yellowMinValue` | Kecerahan minimum untuk marka kuning. |
| `param.laneColorDilateRadius` | Radius dilasi agar mask marka tidak mudah putus. |
| `param.enableMaskFallback` | Mengaktifkan fallback ke edge ROI biasa jika mask warna tidak cukup. |
| `param.minColorEdgeRatio` | Rasio minimum edge warna terhadap edge ROI agar mask dianggap layak dipakai. |

### Fallback Kurva

| Parameter | Fungsi |
| --- | --- |
| `param.enableCurveFallback` | Mengaktifkan fallback kurva. |
| `param.curveOrder` | Orde polinomial kurva. |
| `param.curveMinPoints` | Jumlah titik minimum untuk fitting kurva. |
| `param.curveMaxRMSE` | Batas error maksimum hasil fitting kurva. |
| `param.curveMinPairDistanceRatio` | Jarak minimum antar pasangan kurva kiri dan kanan. |

### Validasi dan Stabilizer

| Parameter | Fungsi |
| --- | --- |
| `param.enableLineValidation` | Mengaktifkan validasi posisi garis. |
| `param.leftMaxBottomRatio` | Batas maksimum posisi bawah garis kiri. |
| `param.rightMinBottomRatio` | Batas minimum posisi bawah garis kanan. |
| `param.minLaneWidthRatio` dan `param.maxLaneWidthRatio` | Batas lebar jalur yang dianggap masuk akal. |
| `maxMissL` dan `maxMissR` | Jumlah frame toleransi ketika garis tidak terdeteksi. |
| `alphaL` dan `alphaR` | Faktor smoothing garis kiri dan kanan. |
| `maxJumpRatioL` dan `maxJumpRatioR` | Batas maksimum lompatan garis antar-frame. |

## Catatan

- Versi 2 lebih lengkap untuk analisis karena menghasilkan video final dan video debug.
- Output debug berukuran lebih besar karena menyimpan beberapa tampilan proses untuk setiap frame.
- Jika hasil deteksi terlalu ketat, cek parameter mask warna dan nilai `param.minColorEdgeRatio`.
- Jika deteksi pada tikungan masih kurang baik, cek parameter ROI `wide` dan parameter fallback kurva.