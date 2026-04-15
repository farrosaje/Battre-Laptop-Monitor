#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Folder penyimpanan log
LOG_DIR="battery_logs"
mkdir -p $LOG_DIR

# File untuk hasil terbaru
LATEST_FILE="$LOG_DIR/latest_status.txt"
HISTORY_FILE="$LOG_DIR/history.csv"

# Tanggal dan waktu
DATE=$(date '+%Y-%m-%d %H:%M:%S')
DATE_FILE=$(date '+%Y-%m-%d')

echo "========================================="
echo "     🔋 BATTERY HEALTH CHECKER 🔋       "
echo "========================================="
echo "Waktu: $DATE"
echo ""

# Cek apakah di laptop/PC (battery exists)
if [ -d "/sys/class/power_supply/BAT0" ] || [ -d "/sys/class/power_supply/BAT1" ]; then
    echo -e "${GREEN}✓ Baterai terdeteksi${NC}"
    
    # Ambil data baterai
    if [ -d "/sys/class/power_supply/BAT0" ]; then
        BAT_PATH="/sys/class/power_supply/BAT0"
    else
        BAT_PATH="/sys/class/power_supply/BAT1"
    fi
    
    # Baca file-file sistem
    CAPACITY=$(cat $BAT_PATH/capacity 2>/dev/null || echo "N/A")
    STATUS=$(cat $BAT_PATH/status 2>/dev/null || echo "N/A")
    VOLTAGE=$(cat $BAT_PATH/voltage_now 2>/dev/null || echo "N/A")
    CURRENT=$(cat $BAT_PATH/current_now 2>/dev/null || echo "N/A")
    TEMP=$(cat $BAT_PATH/temp 2>/dev/null || echo "N/A")
    CYCLE_COUNT=$(cat $BAT_PATH/cycle_count 2>/dev/null || echo "N/A")
    ENERGY_FULL=$(cat $BAT_PATH/energy_full 2>/dev/null || echo "N/A")
    ENERGY_FULL_DESIGN=$(cat $BAT_PATH/energy_full_design 2>/dev/null || echo "N/A")
    
    # Konversi nilai
    if [ "$VOLTAGE" != "N/A" ]; then
        VOLTAGE=$(echo "scale=2; $VOLTAGE/1000000" | bc 2>/dev/null || echo "N/A")
    fi
    
    if [ "$CURRENT" != "N/A" ]; then
        CURRENT=$(echo "scale=2; $CURRENT/1000000" | bc 2>/dev/null || echo "N/A")
    fi
    
    if [ "$TEMP" != "N/A" ]; then
        TEMP=$(echo "scale=1; $TEMP/1000" | bc 2>/dev/null || echo "N/A")
    fi
    
    # Hitung kesehatan baterai
    if [ "$ENERGY_FULL" != "N/A" ] && [ "$ENERGY_FULL_DESIGN" != "N/A" ]; then
        HEALTH=$(echo "scale=1; ($ENERGY_FULL/$ENERGY_FULL_DESIGN)*100" | bc 2>/dev/null || echo "N/A")
        
        # Penilaian kesehatan
        if [ "$HEALTH" != "N/A" ]; then
            if (( $(echo "$HEALTH >= 80" | bc -l) )); then
                HEALTH_STATUS="${GREEN}BAIK${NC}"
            elif (( $(echo "$HEALTH >= 60" | bc -l) )); then
                HEALTH_STATUS="${YELLOW}CUKUP${NC}"
            else
                HEALTH_STATUS="${RED}PERLU GANTI${NC}"
            fi
        else
            HEALTH_STATUS="N/A"
        fi
    else
        HEALTH="N/A"
        HEALTH_STATUS="N/A"
    fi
    
    # Tampilkan hasil
    echo ""
    echo "📊 STATUS BATTERAI:"
    echo "├─ Kapasitas: ${CAPACITY}%"
    echo "├─ Status: $STATUS"
    echo "├─ Tegangan: ${VOLTAGE}V"
    echo "├─ Arus: ${CURRENT}A"
    [ "$TEMP" != "N/A" ] && echo "├─ Suhu: ${TEMP}°C"
    [ "$CYCLE_COUNT" != "N/A" ] && echo "├─ Siklus charge: $CYCLE_COUNT"
    echo "└─ Kesehatan: ${HEALTH}% → $HEALTH_STATUS"
    
    # Rekomendasi
    echo ""
    echo "💡 REKOMENDASI:"
    if [ "$STATUS" == "Charging" ]; then
        echo "   🔌 Sedang mengisi daya"
    elif [ "$STATUS" == "Discharging" ]; then
        if [ "$CAPACITY" -lt 20 ]; then
            echo -e "   ${RED}⚠️  Baterai rendah! Segera charge${NC}"
        elif [ "$CAPACITY" -lt 50 ]; then
            echo -e "   ${YELLOW}⚡ Baterai menengah, sebaiknya segera charge${NC}"
        else
            echo "   ✅ Baterai cukup, bisa digunakan"
        fi
    fi
    
    if [ "$HEALTH" != "N/A" ] && (( $(echo "$HEALTH < 60" | bc -l) )); then
        echo -e "   ${RED}🔧 Kesehatan baterai buruk, pertimbangkan ganti baterai${NC}"
    fi
    
    # Simpan ke file
    echo "=== BATTERY REPORT - $DATE ===" > $LATEST_FILE
    echo "Kapasitas: ${CAPACITY}%" >> $LATEST_FILE
    echo "Status: $STATUS" >> $LATEST_FILE
    echo "Tegangan: ${VOLTAGE}V" >> $LATEST_FILE
    echo "Kesehatan: ${HEALTH}%" >> $LATEST_FILE
    echo "Rekomendasi: $( [ "$HEALTH" != "N/A" ] && [ $(echo "$HEALTH < 60" | bc) -eq 1 ] && echo "Ganti baterai" || echo "Normal" )" >> $LATEST_FILE
    
    # Simpan ke history (CSV)
    if [ ! -f "$HISTORY_FILE" ]; then
        echo "Tanggal,Kapasitas(%),Status,Tegangan(V),Kesehatan(%)" > $HISTORY_FILE
    fi
    echo "$DATE,$CAPACITY,$STATUS,$VOLTAGE,$HEALTH" >> $HISTORY_FILE
    
    # Tampilkan grafik sederhana
    echo ""
    echo "📈 GRAFIK KAPASITAS (history 10 terakhir):"
    tail -10 $HISTORY_FILE | cut -d',' -f2 | tail -10 | while read cap; do
        if [ "$cap" != "Kapasitas(%)" ] && [ "$cap" != "" ]; then
            bar=$(printf '█ %.0s' $(seq 1 $((cap / 5))))
            printf "   %3s%% %s\n" "$cap" "$bar"
        fi
    done
    
else
    echo -e "${RED}✗ Tidak terdeteksi baterai${NC}"
    echo "   (Ini mungkin PC desktop atau virtual environment)"
    echo "   Simulasi data untuk menjaga aktivitas GitHub..."
    
    # Simulasi data untuk tetap aktif
    SIMULASI_CAP=$((RANDOM % 100 + 1))
    echo "=== BATTERY REPORT (SIMULATED) - $DATE ===" > $LATEST_FILE
    echo "Kapasitas: ${SIMULASI_CAP}% (simulasi)" >> $LATEST_FILE
    echo "Status: $( [ $((RANDOM % 2)) -eq 0 ] && echo "Charging" || echo "Discharging" )" >> $LATEST_FILE
    echo "Catatan: Sistem tidak memiliki baterai fisik" >> $LATEST_FILE
fi

echo ""
echo "========================================="
echo "✅ Laporan disimpan di: $LATEST_FILE"
echo "📜 History: $HISTORY_FILE"
echo "========================================="
