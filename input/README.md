# Folder Input Video

Folder `input/` berisi video sumber yang digunakan untuk pengujian program deteksi jalur jalan pada `versi1` dan `versi2`. File video tidak disimpan ke repository Git karena ukurannya besar, sehingga akses utama disediakan melalui Google Drive.

## Link Folder

| Jenis | Link |
| --- | --- |
| Folder input lengkap | [Google Drive - Folder Input](https://drive.google.com/drive/folders/12mNP92cbfqqLuf6PDcHAWZvuHOyb8bpL?usp=sharing) |

## Daftar Video

| No. | Nama file lokal | Link Google Drive | Keterangan penggunaan |
| --- | --- | --- | --- |
| 1 | `video.mp4` | [Video 1](https://drive.google.com/file/d/1xw9AwSyDH5rVTkf9ud2QlB5jfMzf6KcH/view?usp=drive_link) | Video jalan lurus sebagai skenario dasar untuk menguji apakah deteksi jalur dapat berjalan stabil pada kondisi sederhana. |
| 2 | `video2.mp4` | [Video 2](https://drive.google.com/file/d/1QXMP5AvdyIyVLp_Q0ZjP-_hGVYAO6EDk/view?usp=drive_link) | Video jalan kombinasi lurus dan belok ringan, dengan marka kanan berwarna kuning. Pada bagian akhir terdapat marka yang hilang sehingga versi 1 sempat kehilangan deteksi garis kiri. |
| 3 | `video3.mp4` | [Video 3](https://drive.google.com/file/d/1kAZpUKlAoZl9pEHZv4_06oDHvdgIUFki/view?usp=drive_link) | Video jalan full belok untuk menguji kestabilan deteksi pada tikungan. Pada versi 1, deteksi marka terutama sisi kanan terlihat kurang stabil dan beberapa kali hilang. |
| 4 | `video4.mp4` | [Video 4](https://drive.google.com/file/d/1a7E69yH4dq5LZ3OkZ6BLVkIrYWmM3J-_/view?usp=drive_link) | Video percobaan belok ekstrem. Pada kondisi ini, garis kiri sulit terdeteksi dari jarak yang cukup jauh sebelum kendaraan mencapai tikungan; versi 2 digunakan untuk menguji apakah deteksi dapat lebih terbantu pada sebagian frame. |

## Cara Menyiapkan Video

1. Unduh video dari link Google Drive.
2. Letakkan file di folder `input/`.
3. Pastikan nama file sesuai dengan nama yang digunakan pada `code.m`, misalnya:

```matlab
inputVideo = '../input/video2.mp4';
```

4. Jika ingin memproses video lain, ubah nilai `inputVideo` pada `code.m` di folder `versi1/` atau `versi2/`.

## Catatan

- File `.mp4` diabaikan oleh Git melalui `.gitignore`, sehingga perubahan atau penambahan video lokal tidak akan ikut masuk repository.
- Pastikan struktur relatif folder tetap sama: `versi1/` dan `versi2/` membaca video dari `../input/`.
- Jika MATLAB menampilkan error bahwa file tidak ditemukan, periksa kembali nama file, lokasi file, dan ekstensi `.mp4`.