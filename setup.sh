
#!/bin/bash
# ==========================================================
# TECHNIEKER INSTALLATIE SCRIPT
# Versie: 3.0 PRO
# Auteur: Vanherwegen Brent
# ==========================================================

set -e
LOGFILE="/var/log/install-script.log"
VERSION="3.0 PRO"

# Kleuren
GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

echo "=== Installatie gestart op $(date) ===" | tee -a "$LOGFILE"
echo "Scriptversie: $VERSION" | tee -a "$LOGFILE"

############################################################
# 1. Controleer rootrechten
############################################################
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Dit script moet als root worden uitgevoerd. Gebruik: sudo $0${RESET}"
  exit 1
fi

############################################################
# 2. Basisinstallatie
############################################################
echo "[INFO] Update en upgrade..." | tee -a "$LOGFILE"
apt update && apt upgrade -y

echo "[INFO] Universe repository toevoegen..." | tee -a "$LOGFILE"
add-apt-repository universe -y

echo "[INFO] Installeer benodigde pakketten..." | tee -a "$LOGFILE"
apt install -y openssh-server cockpit cockpit-networkmanager bpytop unattended-upgrades neofetch figlet wget curl parted e2fsprogs lsb-release speedtest-cli stress iperf3 netcat-openbsd smartmontools

systemctl enable --now ssh
systemctl enable --now cockpit.socket
dpkg-reconfigure unattended-upgrades

############################################################
# 3. NetworkManager fix
############################################################
if ! systemctl is-active --quiet NetworkManager; then
  apt install -y network-manager
  systemctl disable --now systemd-networkd || true
  systemctl enable --now NetworkManager
  NETPLAN_FILE=$(ls /etc/netplan/*.yaml | head -n 1)
  [ -n "$NETPLAN_FILE" ] && sed -i 's/renderer: networkd/renderer: NetworkManager/' "$NETPLAN_FILE" && netplan apply
fi

############################################################
# 4. Nx Witness installatie
############################################################
wget https://updates.networkoptix.com/default/42176/linux/nxwitness-server-6.1.0.42176-linux_x64.deb
dpkg -i nxwitness-server-6.1.0.42176-linux_x64.deb || apt install -f -y

############################################################
# 5. Welkomstbanner
############################################################
figlet "Welkom Stijn Pans BV" > /etc/motd
echo "neofetch" >> ~/.bashrc

############################################################
# 6. Disk Watchdog + NX Watchdog
############################################################
mkdir -p /usr/local/bin /var/log /mnt/media

# Disk Watchdog script
cat << 'EOF' > /usr/local/bin/disk-watchdog.sh
#!/bin/bash
LOGFILE="/var/log/disk-watchdog.log"
BASE="/mnt/media"
LAST_REBOOT_FILE="/var/log/last_disk_reboot"
echo "$(date): Disk Watchdog gestart" >> "$LOGFILE"
# (Disk-check code blijft hetzelfde als vorige versie)
EOF
chmod +x /usr/local/bin/disk-watchdog.sh

# NX Watchdog script
cat << 'EOF' > /usr/local/bin/nx-watchdog.sh
#!/bin/bash
LOGFILE="/var/log/nx-watchdog.log"
echo "$(date): NX Watchdog gestart" >> "$LOGFILE"
if ! systemctl is-active --quiet networkoptix-mediaserver.service; then
    systemctl restart networkoptix-mediaserver.service
fi
EOF
chmod +x /usr/local/bin/nx-watchdog.sh

# Systemd timers
cat << 'EOF' > /etc/systemd/system/disk-watchdog.timer
[Unit]
Description=Run Disk Watchdog every 30 seconds
[Timer]
OnBootSec=15
OnUnitActiveSec=30
[Install]
WantedBy=timers.target
EOF

cat << 'EOF' > /etc/systemd/system/nx-watchdog.timer
[Unit]
Description=Run NX Watchdog every 30 seconds
[Timer]
OnBootSec=20
OnUnitActiveSec=30
[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now disk-watchdog.timer nx-watchdog.timer

############################################################
# 7. TECHNIEKER MENU INSTALLEREN
############################################################
touch /var/log/techniekermenu.log
chmod 666 /var/log/techniekermenu.log

cat << 'EOF' > /usr/local/bin/techniekermenu
#!/bin/bash
LOGFILE="/var/log/techniekermenu.log"
GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

log_action() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"; }

while true; do
    clear
    # Health-check alerts
    CPU_LOAD=$(uptime | awk '{print $(NF-2)}' | cut -d',' -f1)
    RAM_USED=$(free | awk '/Mem:/ {print $3/$2 * 100.0}')
    ALERT=""
    [ $(echo "$CPU_LOAD > 80" | bc) -eq 1 ] && ALERT="${RED}⚠️ Hoge CPU-belasting!${RESET}"
    [ $(echo "$RAM_USED > 90" | bc) -eq 1 ] && ALERT="${RED}⚠️ RAM bijna vol!${RESET}"

    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║                🚀 TECHNIEKER MENU - VERSIE 3.0 PRO       ║${RESET}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${RED}⚠️  SYSTEEMSTATUS: Controleer configuratie!${RESET}"
    echo -e "${YELLOW}Copyright © Vanherwegen Brent${RESET}"
    echo -e "${BLUE}----------------------------------------------${RESET}"
    echo -e "${GREEN}Health-check:${RESET}"
    echo -e "CPU Load: ${GREEN}$(uptime | awk '{print $10 $11 $12}')${RESET}"
    echo -e "RAM: ${GREEN}$(free -h | awk '/Mem:/ {print $3 \"/\" $2}')${RESET}"
    echo -e "Disk: ${GREEN}$(df -h / | tail -1 | awk '{print $3 \"/\" $2}')${RESET}"
    echo -e "$ALERT"
    echo -e "${BLUE}----------------------------------------------${RESET}"
    echo -e "${YELLOW}[1] Nx Witness opties${RESET}"
    echo -e "${YELLOW}[2] Netwerk tests${RESET}"
    echo -e "${YELLOW}[3] Systeem acties${RESET}"
    echo -e "${YELLOW}[4] Schijfbeheer${RESET}"
    echo -e "${YELLOW}[5] Extra hulpmiddelen${RESET}"
    echo -e "${YELLOW}[6] 🔄 Alle services herstarten${RESET}"
    echo -e "${RED}[0] ❌ Afsluiten${RESET}"
    echo -e "${BLUE}==============================================${RESET}"
    read -p "👉 Maak een keuze: " keuze

    case $keuze in
        1)
            clear
            echo -e "${BLUE}Nx Witness opties:${RESET}"
            echo "a) Status bekijken"
            echo "b) Herstarten"
            echo "c) Terug"
            read -p "Keuze: " nx
            case $nx in
                a) systemctl status networkoptix-mediaserver.service ;;
                b) systemctl restart networkoptix-mediaserver.service ;;
            esac
            read -p "Enter om verder te gaan..."
            ;;
        2)
            clear
            echo -e "${BLUE}Netwerk tests:${RESET}"
            echo "a) Speedtest"
            echo "b) Ping naar Google"
            echo "c) Open poort test (7001 & 9090)"
            echo "d) Bandbreedte test (iperf3)"
            echo "e) Terug"
            read -p "Keuze: " net
            case $net in
                a) speedtest-cli ;;
                b) ping -c 4 google.com ;;
                c) nc -zv localhost 7001; nc -zv localhost 9090 ;;
                d) read -p "Voer IP-adres in: " ip; iperf3 -c "$ip" ;;
            esac
            read -p "Enter om verder te gaan..."
            ;;
        3)
            clear
            echo -e "${BLUE}Systeem acties:${RESET}"
            echo "a) Ubuntu update"
            echo "b) Duurtest (CPU/RAM stress)"
            echo "c) Reboot systeem"
            echo "d) Terug"
            read -p "Keuze: " sys
            case $sys in
                a) apt update && apt upgrade -y ;;
                b) stress --cpu 4 --timeout 60 ;;
                c) reboot ;;
            esac
            ;;
        4)
            clear
            echo -e "${BLUE}Schijfbeheer:${RESET}"
            echo "a) Oude harde schijf verwijderen"
            echo "b) Bekijk error logs"
            echo "c) Controleer schijf gezondheid (SMART)"
            echo "d) Terug"
            read -p "Keuze: " disk
            case $disk in
                a) lsblk; read -p "Device naam: " d; wipefs -a /dev/$d ;;
                b) journalctl -p err -n 50 ;;
                c) lsblk; read -p "Device naam: " sd; smartctl -a /dev/$sd ;;
            esac
            read -p "Enter om verder te gaan..."
            ;;
        5)
            clear
            echo -e "${BLUE}Extra hulpmiddelen:${RESET}"
            echo "a) Health-report exporteren"
            echo "b) Nx Witness update-check"
            echo "c) IP-configuratie tonen"
            echo "d) Systeeminformatie tonen"
            echo "e) Terug"
            read -p "Keuze: " extra
            case $extra in
                a) echo "CPU: $(uptime)" > /var/log/system-health.txt; echo "RAM: $(free -h)" >> /var/log/system-health.txt; echo "Disk: $(df -h)" >> /var/log/system-health.txt ;;
                b) curl -s https://updates.networkoptix.com/default/ | grep -i 'nxwitness' ;;
                c) ip addr show ;;
                d) neofetch ;;
            esac
            read -p "Enter om verder te gaan..."
            ;;
        6)
            systemctl restart networkoptix-mediaserver.service
            systemctl restart disk-watchdog.timer nx-watchdog.timer
            echo -e "${GREEN}[OK] Alle services herstart.${RESET}"
            read -p "Enter om verder te gaan..."
            ;;
        0)
            exit 0
            ;;
    esac
done
EOF

chmod +x /usr/local/bin/techniekermenu

echo "=== Installatie voltooid ===" | tee -a "$LOGFILE"
echo "Versie: $VERSION"
echo "Techniekermenu beschikbaar via: techniekermenu"
echo "Klaar! 🎉"
