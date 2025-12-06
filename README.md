Automatische Installatie & Watchdog Services voor Ubuntu Desktop 24.04 LTS
Auteur: Stijn Pans BV
Versie: 1.0
Datum: 2025-12-06

Beschrijving
Dit script automatiseert de installatie en configuratie van een Ubuntu Desktop 24.04 LTS systeem voor gebruik met Nx Witness Server en Client en voegt twee belangrijke watchdog-mechanismen toe:


Disk Watchdog

Controleert extra schijven, maakt partities en labels aan indien nodig.
Mount schijven automatisch via UUID en LABEL.
Voert een reboot uit als geen enkele schijf gemount is (max. 1x per uur).



NX Watchdog

Controleert of de Nx Witness mediaserver draait.
Herstart de service indien deze niet actief is.



Daarnaast configureert het script:

Basisinstallatie van essentiële pakketten.
Unattended upgrades voor automatische updates.
Welkomstbanner met systeeminformatie.
Systemd timers voor periodieke uitvoering van watchdog scripts.
Cockpit inclusief Network Manager voor IP-configuratie via webinterface.
Nx Witness Client installatie voor desktopgebruik.


Installatie

Zorg dat je rootrechten hebt.
Download het script en voer het uit:


chmod +x install-ubuntu-desktop.sh
sudo ./install-ubuntu-desktop.sh

Het script installeert:

openssh-server, cockpit, cockpit-networkmanager, bpytop, unattended-upgrades, neofetch, figlet, wget, curl, parted, e2fsprogs, lsb-release
Nx Witness Server (versie 6.1.0.42176)
Nx Witness Client (versie 6.1.0.42176)
Welkomstbanner in /etc/motd




Nx Witness details

Server downloadlink:
https://updates.networkoptix.com/default/42176/linux/nxwitness-server-6.1.0.42176-linux_x64.deb
Client downloadlink:
https://updates.networkoptix.com/default/42176/linux/nxwitness-client-6.1.0.42176-linux_x64.deb


IP-configuratie via Cockpit
Na installatie kun je IP-adressen beheren via Cockpit:

Open Cockpit in je browser:
https://<server-ip>:9090


Log in met je servergebruikersnaam.
Ga naar Netwerk → wijzig IP-instellingen via cockpit-networkmanager.

Dit toestel en software wordt beheerd door de firma Stijn Pans BV.
Voor ondersteuning kan je ons bereiken via:
• 	📧 support@stijn-pans.be
• 	☎️ 016 77 08 0
