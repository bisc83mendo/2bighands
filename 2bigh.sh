#!/bin/bash

# Versione dello script
# v0.1.14

# Pulisce lo schermo del terminale all'avvio
clear

# Codici di escape ANSI per i colori e la formattazione
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
GRAY='\033[0;37m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BLINK='\033[5m' # Codice per far lampeggiare il testo

# Funzione per visualizzare un riquadro di benvenuto
function welcome_box() {
    echo -e "${CYAN}┌───────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  ${GREEN}Script di Connessione Wireless Scrcpy${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────┘${NC}"
    echo
}

# Funzione per gestire l'uscita in caso di errore
function on_error() {
  echo -e "${RED}═════════════════════════════════════════════${NC}"
  echo -e "${RED} ${BOLD}ERRORE:${NC} Si è verificato un problema."
  echo -e "          Assicurati che il telefono sia collegato e che il debug USB sia abilitato."
  echo -e "${RED}═════════════════════════════════════════════${NC}"
  exit 1
}

# Funzione per gestire l'uscita pulita quando si preme CTRL+C
function clean_exit() {
    echo
    echo -e "${YELLOW}${BOLD}» Disconnessione in corso...${NC}"
    adb disconnect "$IP_ADDRESS:5555"
    echo -e "${GREEN}${BOLD}✓ Disconnessione completata!${NC}"
    echo
    exit 0
}

trap on_error ERR
trap clean_exit INT EXIT

welcome_box

echo -e "${CYAN}» Versione dello script:${NC} ${BOLD}v0.1.14${NC}"
echo

# --- Promemoria per il Debug USB ---
echo -e "${BLUE}${BOLD}RICORDA DI ABILITARE IL ${BLINK}DEBUG USB${NC}"
echo -e "${BLUE}${BOLD}DALLE 'OPZIONI SVILUPPATORE'${NC}"
echo -e "${BLUE}${BOLD}DEL TUO DISPOSITIVO ANDROID!${NC}"
echo
echo -e "${YELLOW}Premi ${GREEN}INVIO${NC} per continuare."
read -p ""
echo

# --- Controllo delle dipendenze ---
echo -e "${YELLOW}${BOLD}» Controllo delle dipendenze (adb, scrcpy)...${NC}"
function check_dependency() {
    local command_name=$1
    if ! command -v "$command_name" &> /dev/null; then
        echo -e "${RED}═════════════════════════════════════════════${NC}"
        echo -e "${RED} ${BOLD}ERRORE:${NC} Il comando '$command_name' non è stato trovato."
        echo -e "          È necessario installarlo per eseguire lo script."
        echo -e " ${BOLD}Istruzioni per l'installazione (basate sul gestore pacchetti):${NC}"

        if command -v pacman &> /dev/null; then
            echo -e "${CYAN}    # Arch Linux (e derivate come Garuda, CachyOS)${NC}"
            echo -e "${GREEN}    sudo pacman -S android-tools scrcpy${NC}"
        elif command -v apt &> /dev/null; then
            echo -e "${CYAN}    # Debian/Ubuntu (e derivate)${NC}"
            echo -e "${GREEN}    sudo apt install adb scrcpy${NC}"
        elif command -v dnf &> /dev/null; then
            echo -e "${CYAN}    # Fedora (e derivate)${NC}"
            echo -e "${GREEN}    sudo dnf install android-tools scrcpy${NC}"
        else
            echo -e "${CYAN}    # Altre distribuzioni:${NC}"
            echo -e "${GREEN}    Consulta la documentazione della tua distribuzione per installare 'adb' e 'scrcpy'.${NC}"
        fi
        echo -e "${RED}═════════════════════════════════════════════${NC}"
        exit 1
    fi
}

check_dependency adb
check_dependency scrcpy
echo -e "${GREEN}${BOLD}✓ Dipendenze trovate!${NC}"
echo

# --- Sezione di Pre-Avvio ---
echo -e "${YELLOW}${BOLD}» Pulizia delle connessioni ADB attive...${NC}"
adb disconnect &>/dev/null
echo -e "${GREEN}${BOLD}✓ Fatto!${NC}"
echo

# --- Sezione 1: Connessione USB Automatica ---
echo -e "${YELLOW}${BOLD}» Passo 1:${NC} In attesa del collegamento del cellulare tramite USB..."
while true; do
    if adb devices | grep -q "device$"; then
        break
    fi
    sleep 1
done

# Ottenere il seriale del dispositivo USB
SERIAL=$(adb devices | grep -E 'device$' | awk '{print $1}')

if [ -z "$SERIAL" ]; then
    on_error
fi

# Rilevamento dell'indirizzo IP
echo -e "${YELLOW}${BOLD}» Rilevamento dell'indirizzo IP...${NC}"
IP_ADDRESS=$(adb -s "$SERIAL" shell ip addr show wlan0 | grep -E 'inet ' | awk '{print $2}' | cut -d '/' -f 1)

if [ -z "$IP_ADDRESS" ]; then
    echo -e "${RED} ${BOLD}ERRORE:${NC} Impossibile rilevare l'indirizzo IP del telefono."
    echo -e "          Assicurati che il Wi-Fi sia attivo e che il telefono sia connesso alla stessa rete."
    exit 1
fi

echo -e "${GREEN}${BOLD}✓ Trovato!${NC} L'indirizzo IP del telefono è: ${CYAN}${BOLD}$IP_ADDRESS${NC}"
echo

echo -e "${GREEN}${BOLD}✓ Fatto!${NC} Avvio della modalità TCP/IP su adb..."
adb -s "$SERIAL" tcpip 5555
echo

echo -e "${GREEN}${BOLD}✓ Fatto!${NC} Telefono connesso correttamente. ${CYAN}Rimuovi il cavo USB.${NC}"
echo -e "${YELLOW}${BOLD}» In attesa dello scollegamento del cavo...${NC}"
while adb devices | grep -q "device$"; do
    sleep 1
done
echo -e "${GREEN}${BOLD}✓ Cavo scollegato!${NC}"
echo

# --- Sezione 2: Connessione Wireless ---
echo
echo -e "${YELLOW}${BOLD}» Passo 2:${NC} Connessione wireless al telefono in corso..."
adb connect "$IP_ADDRESS:5555"
echo

echo -e "${GREEN}${BOLD}✓ Connesso! Avvio di scrcpy in corso...${NC}"
echo -e "${RED}${BOLD}${BLINK}PREMERE CTRL+C PER INTERROMPERE E DISCONNETTERE${NC}"
scrcpy --stay-awake --window-width 1080 --window-height 1920

# --- Sezione 3: Pulizia Finale ---
echo
echo -e "${YELLOW}${BOLD}» Disconnessione del telefono...${NC}"
adb disconnect "$IP_ADDRESS:5555"
echo

echo -e "${GREEN}${BOLD}✓ Operazione completata!${NC} Premi ${GREEN}INVIO${NC} per uscire."
read -p ""
