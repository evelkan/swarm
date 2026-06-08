#!/bin/bash
# =============================================================================
# set-hostname.sh — Changement du hostname de la VM
# =============================================================================
# Usage : sudo bash set-hostname.sh <nouveau-hostname>
# Exemple: sudo bash set-hostname.sh swarm-worker1
# =============================================================================

set -e

if [ -z "$1" ]; then
    echo "❌ Usage : sudo bash set-hostname.sh <hostname>"
    echo "   Valeurs possibles : swarm-manager | swarm-worker1 | swarm-worker2 | swarm-worker3 | swarm-nfs"
    exit 1
fi

NEW_HOSTNAME="$1"

echo "🔧 Changement du hostname → $NEW_HOSTNAME"
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

# Mettre à jour /etc/hostname
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null

echo "✅ Hostname défini : $(hostname)"
echo "ℹ️  Reconnectez-vous pour que le prompt soit mis à jour."
