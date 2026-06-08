# Deteksi Jalur Jalan pada Video Menggunakan MATLAB

Proyek ini berisi implementasi deteksi jalur jalan (*lane detection*) pada video menggunakan MATLAB. Program ini dikembangkan dalam dua versi untuk menunjukkan evolusi dan perbaikan dari implementasi awal.

## Struktur Proyek

Proyek ini terdiri dari dua versi implementasi:

| Folder | Versi | Keterangan |
| --- | --- | --- |
| `versi1/` | Versi 1 | Implementasi awal/lama deteksi jalur jalan. |
| `versi2/` | Versi 2 | Versi upgrade dari versi 1 yang sedang dalam pengembangan. |

## Folder Utama

| Folder | Keterangan |
| --- | --- |
| `input/` | Berisi file video input yang akan diproses. |
| `versi1/` | Implementasi versi pertama (versi lama). |
| `versi2/` | Implementasi versi kedua (versi upgrade, sedang dalam pengembangan). |
| `readme.md` | Dokumentasi utama proyek (file ini). |

## Cara Menggunakan

Untuk menggunakan salah satu versi:

1. Siapkan file video input dengan nama `video.mp4` di folder `input/`.
2. Pilih versi yang ingin digunakan:
   - **Versi 1**: Masuk ke folder `versi1/` dan jalankan `code.m`
   - **Versi 2**: Masuk ke folder `versi2/` dan jalankan `code.m`
3. Buka MATLAB dan arahkan *Current Folder* ke folder versi yang dipilih.
4. Jalankan file:

```matlab
code
```

## Informasi Lebih Lanjut

Untuk dokumentasi lengkap masing-masing versi, silakan lihat:

- [Versi 1 - Dokumentasi Lengkap](versi1/README.md)
- [Versi 2 - Dokumentasi Lengkap](versi2/README.md)
- [Input Video - Dokumentasi](input/README.md)

## Catatan

- File video input dan output tidak disertakan dalam repository karena ukuran file besar dan masuk `.gitignore`.
- Setiap versi memiliki implementasi dan parameter yang mungkin berbeda sesuai dengan perkembangan pengembangan.
- Versi 2 saat ini sedang dalam pengembangan dan merupakan upgrade dari versi 1.
