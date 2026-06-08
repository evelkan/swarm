#!/bin/bash
# =============================================================================
# fix-ipv6.sh — Forcer Docker en IPv4 (correction connexion Docker Hub)
# =============================================================================
# Par défaut, Docker tente de joindre Docker Hub en IPv6, ce qui échoue si
# IPv6 n'est pas configuré sur les VMs. Ce script force l'utilisation d'IPv4.
# =============================================================================

set -e

DAEMON_FILE="/etc/docker/daemon.json"

echo " Configuration du daemon Docker (désactivation IPv6)..."

# Créer ou remplacer le fichier de configuration
sudo tee "$DAEMON_FILE" > /dev/null << 'EOF'
{
  "ipv6": false
}
EOF

echo " $DAEMON_FILE créé."

# Redémarrer Docker
echo " Redémarrage de Docker..."
sudo systemctl restart docker
sudo systemctl status docker --no-pager | grep "Active:"

echo ""
echo " Test de fonctionnement (docker run hello-world)..."
docker run --rm hello-world

echo ""
echo " Docker fonctionne correctement en IPv4 !"
