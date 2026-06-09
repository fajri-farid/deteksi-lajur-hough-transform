# Deteksi Jalur Jalan pada Video Menggunakan MATLAB

Repository ini berisi proyek praktikum pengolahan citra digital untuk mendeteksi jalur jalan atau *lane detection* pada video menggunakan MATLAB. Program dikembangkan dalam dua versi agar proses peningkatan metode dapat dibandingkan dengan jelas: `versi1` sebagai implementasi awal dan `versi2` sebagai implementasi lanjutan dengan mask warna marka, validasi geometri, fallback kurva, serta video debug.

## Ringkasan Proyek

| Bagian | Keterangan |
| --- | --- |
| Bahasa | MATLAB |
| Topik | Deteksi tepi, Region of Interest (ROI), Hough Transform, segmentasi warna, stabilisasi hasil deteksi, dan pemrosesan video |
| Input | 4 video jalan pada folder `input/` |
| Output versi 1 | Video hasil deteksi jalur dan gambar panel proses 1 frame |
| Output versi 2 | Video hasil deteksi jalur, gambar panel proses 1 frame, dan video debug panel |

## Struktur Folder

| Folder/File | Keterangan |
| --- | --- |
| `input/` | Berisi video input yang digunakan oleh program. |
| `versi1/` | Implementasi awal deteksi jalur menggunakan grayscale, Canny, ROI, Hough Transform, fitting garis, dan stabilizer. |
| `versi2/` | Implementasi lanjutan dengan mask warna marka putih/kuning, fallback deteksi kurva, validasi garis, ROI lebih fleksibel, dan output debug video. |
| `readme.md` | Dokumentasi utama project. |

## Link Penting

| Jenis | Link |
| --- | --- |
| Folder input | [Google Drive - Input](https://drive.google.com/drive/folders/12mNP92cbfqqLuf6PDcHAWZvuHOyb8bpL?usp=sharing) |
| Folder output versi 1 | [Google Drive - Output Versi 1](https://drive.google.com/drive/folders/1sjeogVMn7aGsiEwn2Ka0itiA0YuepOFg?usp=sharing) |
| Folder output versi 2 | [Google Drive - Output Versi 2](https://drive.google.com/drive/folders/1hSvFT6yzlyAd6vMxQZDTidk_mqHe_FB8?usp=sharing) |

## Video Input

| No. | File lokal | Link video |
| --- | --- | --- |
| 1 | `input/video.mp4` | [Google Drive - Video 1](https://drive.google.com/file/d/1xw9AwSyDH5rVTkf9ud2QlB5jfMzf6KcH/view?usp=drive_link) |
| 2 | `input/video2.mp4` | [Google Drive - Video 2](https://drive.google.com/file/d/1QXMP5AvdyIyVLp_Q0ZjP-_hGVYAO6EDk/view?usp=drive_link) |
| 3 | `input/video3.mp4` | [Google Drive - Video 3](https://drive.google.com/file/d/1kAZpUKlAoZl9pEHZv4_06oDHvdgIUFki/view?usp=drive_link) |
| 4 | `input/video4.mp4` | [Google Drive - Video 4](https://drive.google.com/file/d/1a7E69yH4dq5LZ3OkZ6BLVkIrYWmM3J-_/view?usp=drive_link) |

## Persiapan Video Input

Sebelum menjalankan program, unduh video input dari link Google Drive di atas atau dari folder input lengkap, lalu simpan ke folder `input/` dengan nama file yang sesuai.

Struktur file yang diharapkan:

```text
input/
├── video.mp4
├── video2.mp4
├── video3.mp4
└── video4.mp4
```

Jika hanya ingin menjalankan satu video, cukup unduh video yang diperlukan dan pastikan variabel `inputVideo` pada `code.m` mengarah ke nama file tersebut.

## Perbandingan Versi

| Aspek | Versi 1 | Versi 2 |
| --- | --- | --- |
| Fokus utama | Baseline deteksi jalur berbasis Canny dan Hough Transform. | Peningkatan ketahanan deteksi pada variasi warna marka, tikungan, dan kondisi garis yang tidak stabil. |
| Pemilihan area jalan | ROI poligon statis. | ROI dengan mode `normal` dan `wide`. |
| Pemilihan kandidat marka | Edge hasil Canny di dalam ROI. | Gabungan Canny dengan mask warna marka putih dan kuning. |
| Deteksi garis | Hough Transform dan fitting garis linear. | Hough Transform, validasi geometri, dan fallback kurva saat garis linear gagal. |
| Debug | Gambar panel proses untuk 1 frame. | Gambar panel proses 1 frame dan video debug panel 2x3 untuk seluruh frame. |
| Stabilitas output | Menggunakan smoothing antar-frame. | Smoothing ditambah validasi lompatan, validasi lebar jalur, dan penanganan sisi yang sering putus. |

## Cara Menjalankan

1. Pastikan video input tersedia di folder `input/`.
2. Buka MATLAB.
3. Masuk ke folder versi yang ingin dijalankan, misalnya `versi1/` atau `versi2/`.
4. Sesuaikan variabel file input dan output di bagian awal `code.m` jika ingin memproses video yang berbeda.
5. Jalankan:

```matlab
code
```

Contoh variabel yang dapat disesuaikan:

```matlab
inputVideo  = '../input/video2.mp4';
outputVideo = 'video_lane_output_v2_lane_color_mask2.mp4';
```

## Dokumentasi Lanjutan

- [Dokumentasi folder input](input/README.md)
- [Dokumentasi versi 1](versi1/README.md)
- [Dokumentasi versi 2](versi2/README.md)

## Catatan Repository

File video inputan ataupun output `.mp4`, tidak disimpan ke repository karena ukuran file besar dan sudah masuk `.gitignore`. Gunakan link Google Drive pada dokumentasi ini untuk mengakses file video input dan output.