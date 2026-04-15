# 🔋 Battery Health Monitor

Repo ini otomatis mengecek kesehatan baterai setiap hari menggunakan GitHub Actions.

## 📊 Status Baterai Terbaru

\`\`\`
$(cat battery_logs/latest_status.txt 2>/dev/null || echo "Belum ada data")
\`\`\`

## 📈 Riwayat Kesehatan

Lihat file [battery_logs/history.csv](battery_logs/history.csv) untuk data lengkap.

---

*Diupdate otomatis oleh GitHub Actions*
