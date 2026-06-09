# Versi 1 - Deteksi Jalur Jalan Menggunakan MATLAB

Folder `versi1/` berisi implementasi awal deteksi jalur jalan pada video. Versi ini menjadi baseline untuk membaca video, melakukan preprocessing citra, mendeteksi tepi, membatasi area jalan dengan ROI, mencari garis marka menggunakan Hough Transform, lalu menggambar hasil deteksi pada video output.

## Fitur Utama

- Membaca video input menggunakan `VideoReader`.
- Melakukan konversi RGB ke grayscale.
- Mengurangi noise menggunakan Gaussian blur.
- Mendeteksi tepi menggunakan Canny edge detection.
- Membatasi area deteksi dengan Region of Interest (ROI).
- Mendeteksi kandidat garis menggunakan Hough Transform.
- Memisahkan kandidat garis kiri dan kanan berdasarkan kemiringan.
- Melakukan fitting garis agar garis jalur lebih utuh.
- Menstabilkan hasil antar-frame menggunakan smoothing.
- Menyimpan video hasil deteksi.
- Menyimpan gambar panel proses untuk 1 frame contoh.

## Struktur File

| File | Keterangan |
| --- | --- |
| `code.m` | Program utama versi 1. |
| `README.md` | Dokumentasi versi 1. |
| `video_lane_output.mp4` sampai `video_lane_output4.mp4` | Video output hasil deteksi untuk masing-masing input. |
| `proses_1_frame_lane_detection.png` sampai `proses_1_frame_lane_detection4.png` | Gambar panel proses untuk masing-masing input. |

## Link Output

Semua output versi 1 dapat diakses melalui folder berikut:

[Google Drive - Folder Output Versi 1](https://drive.google.com/drive/folders/1sjeogVMn7aGsiEwn2Ka0itiA0YuepOFg?usp=sharing)

## Pasangan Input dan Output

| Input | Video output | Panel proses |
| --- | --- | --- |
| `../input/video.mp4` | `video_lane_output.mp4` | `proses_1_frame_lane_detection.png` |
| `../input/video2.mp4` | `video_lane_output2.mp4` | `proses_1_frame_lane_detection2.png` |
| `../input/video3.mp4` | `video_lane_output3.mp4` | `proses_1_frame_lane_detection3.png` |
| `../input/video4.mp4` | `video_lane_output4.mp4` | `proses_1_frame_lane_detection4.png` |

## Cara Menjalankan

1. Pastikan video input sudah tersedia di folder `input/`.
2. Buka MATLAB.
3. Arahkan *Current Folder* ke folder `versi1/`.
4. Sesuaikan bagian awal `code.m` sesuai video yang ingin diproses:

```matlab
inputVideo  = '../input/video4.mp4';
outputVideo = 'video_lane_output4.mp4';
outputImage = 'proses_1_frame_lane_detection4.png';
```

5. Jalankan:

```matlab
code
```

Setelah selesai, program akan menyimpan video output dan gambar panel proses di folder `versi1/`.

## Alur Pemrosesan

1. Membaca frame dari video input.
2. Mengubah frame ke grayscale.
3. Menerapkan Gaussian blur.
4. Mendeteksi tepi dengan Canny.
5. Membentuk ROI pada area jalan.
6. Mengambil edge hanya pada area ROI.
7. Menerapkan Hough Transform.
8. Memfilter garis berdasarkan sudut.
9. Memisahkan garis kiri dan kanan.
10. Melakukan fitting garis.
11. Menstabilkan hasil deteksi antar-frame.
12. Menggambar garis kiri, garis kanan, dan area jalur.
13. Menyimpan frame ke video output.

## Parameter Penting

| Parameter | Fungsi |
| --- | --- |
| `param.minAngle` dan `param.maxAngle` | Rentang sudut garis yang dianggap valid sebagai kandidat jalur. |
| `param.numPeaks` | Jumlah kandidat puncak Hough yang diproses. |
| `param.houghThresh` | Ambang kekuatan kandidat garis pada Hough Transform. |
| `param.fillGap` | Jarak maksimum untuk menyambungkan segmen garis. |
| `param.minLength` | Panjang minimum garis yang diterima. |
| `param.roiTopRatio` | Posisi batas atas ROI terhadap tinggi frame. |
| `param.bottomLeftRatio`, `param.bottomRightRatio`, `param.topLeftRatio`, `param.topRightRatio` | Bentuk ROI pada area jalan. |

## Output Visual

Pada video hasil deteksi:

- Garis biru menunjukkan jalur kiri.
- Garis merah menunjukkan jalur kanan.
- Area hijau transparan menunjukkan area jalur yang terdeteksi.

## Catatan

- Versi 1 efektif sebagai baseline, tetapi masih sensitif terhadap perubahan pencahayaan, warna marka, tikungan, dan garis marka yang terputus.
- Jika deteksi kurang stabil, parameter ROI dan Hough Transform dapat disesuaikan di `code.m`.
- Untuk peningkatan metode dan output debug yang lebih lengkap, lihat dokumentasi `versi2/`.