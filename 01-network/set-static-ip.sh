#!/bin/bash
# =============================================================================
# set-static-ip.sh — Configuration de l'IP statique sur ens34 (Host-Only)
# =============================================================================
# Usage : sudo bash set-static-ip.sh <adresse-ip>
# Exemple: sudo bash set-static-ip.sh 192.168.56.11
#
# Plan d'adressage :
#   swarm-manager  → 192.168.56.10
#   swarm-worker1  → 192.168.56.11
#   swarm-worker2  → 192.168.56.12
#   swarm-worker3  → 192.168.56.13
#   swarm-nfs      → 192.168.56.20
# =============================================================================

set -e

INTERFACE="ens34"          # Carte Host-Only VMnet1
NETMASK="255.255.255.0"

if [ -z "$1" ]; then
    echo " Usage : sudo bash set-static-ip.sh <adresse-ip>"
    echo ""
    echo "   swarm-manager  → 192.168.56.10"
    echo "   swarm-worker1  → 192.168.56.11"
    echo "   swarm-worker2  → 192.168.56.12"
    echo "   swarm-worker3  → 192.168.56.13"
    echo "   swarm-nfs      → 192.168.56.20"
    exit 1
fi

STATIC_IP="$1"

echo " Configuration de l'IP statique $STATIC_IP sur $INTERFACE..."

# Vérifier que l'interface existe
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo " Interface $INTERFACE introuvable."
    echo "   Interfaces disponibles :"
    ip link show | grep -E "^[0-9]" | awk '{print "   -", $2}'
    exit 1
fi

# Sauvegarder le fichier interfaces original
INTERFACES_FILE="/etc/network/interfaces"
BACKUP_FILE="/etc/network/interfaces.bak"

if [ ! -f "$BACKUP_FILE" ]; then
    sudo cp "$INTERFACES_FILE" "$BACKUP_FILE"
    echo " Sauvegarde créée : $BACKUP_FILE"
fi

# Ajouter la configuration statique si elle n'existe pas déjà
if grep -q "iface $INTERFACE inet static" "$INTERFACES_FILE"; then
    echo " Une configuration statique existe déjà pour $INTERFACE."
    echo "   Éditer manuellement $INTERFACES_FILE si nécessaire."
else
    cat >> "$INTERFACES_FILE" << EOF

# Interface Host-Only — Cluster Swarm
auto $INTERFACE
iface $INTERFACE inet static
    address $STATIC_IP
    netmask $NETMASK
EOF
    echo " Configuration ajoutée dans $INTERFACES_FILE"
fi

# Appliquer la configuration
echo " Redémarrage du service réseau..."
sudo systemctl restart networking

# Vérification
echo ""
echo " Vérification de l'IP attribuée :"
ip addr show "$INTERFACE" | grep "inet "

echo ""
echo "✅ IP statique $STATIC_IP configurée sur $INTERFACE"
