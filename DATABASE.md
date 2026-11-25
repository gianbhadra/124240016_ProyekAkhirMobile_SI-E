# Database CoinWise (SQLite)

File database: `coinwise.db` (dibuat otomatis saat aplikasi pertama dijalankan).
Kode: `lib/services/db_helper.dart` (skema) dan `lib/services/app_state.dart` (pemakaian).

## Tabel
| Tabel | Kolom | Fungsi |
|---|---|---|
| users | id, username (unik), name, email (unik), salt, password_hash, balance, created_at | Akun dan saldo virtual |
| holdings | user_id, symbol, qty | Aset kripto yang dimiliki |
| watchlist | user_id, symbol | Koin favorit |
| blockchain | id, user_id, idx, data, timestamp, prev_hash, nonce, hash | Rantai blok transaksi simulasi (data transaksi ada di kolom `data`) |
| skor_game | id, user_id, skor, waktu | Riwayat skor mini game |
| saran_kesan | id, user_id, rating, kategori, kesan, saran, waktu | Saran dan kesan mata kuliah |
| expenses | id, user_id, amount, category, note, waktu | Catatan pengeluaran pengguna |
| cache | key, value, updated | Cache harga kripto dan kurs untuk mode offline |

Relasi: semua tabel selain `users` dan `cache` punya `user_id` yang merujuk ke `users.id`.
Session, pengaturan biometrik, dan path foto profil disimpan di SharedPreferences. File foto profil disimpan di direktori dokumen privat aplikasi, bukan di tabel SQLite atau Supabase.

## Melihat isi database (untuk demo dan laporan)
1. Jalankan aplikasi dari Android Studio ke HP/emulator.
2. Buka menu View > Tool Windows > App Inspection > tab Database Inspector.
3. Pilih `coinwise.db`, lalu klik nama tabel untuk melihat datanya.
Screenshot tabel `users` (kolom password_hash berisi kode acak, bukan password asli) cocok dipakai sebagai bukti enkripsi di laporan.
