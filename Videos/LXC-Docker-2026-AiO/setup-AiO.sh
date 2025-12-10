#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "### System aktualisieren..."
apt update && apt upgrade -y

echo "### Benötigte Pakete installieren..."
apt install ca-certificates curl -y 

echo "### Verzeichnis für GPG-Key erstellen..."
install -m 0755 -d /etc/apt/keyrings

echo "### Docker GPG-Schlüssel herunterladen..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

echo "### Leserechte für GPG-Schlüssel setzen..."
chmod a+r /etc/apt/keyrings/docker.asc

echo "### Docker-Repository hinzufügen..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "### Paketlisten erneut aktualisieren..."
apt update

echo "### Docker und zugehörige Komponenten installieren..."
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo "### Docker Compose manuell installieren..."
curl -L https://github.com/docker/compose/releases/download/v$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "### Portainer Container starten..."
docker run -d -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "### Installation abgeschlossen!"
