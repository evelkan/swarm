#!/bin/bash
# =============================================================================
# mount-nfs-client.sh — Montage NFS sur les workers et le manager
# =============================================================================
# À exécuter sur : swarm-manager, swarm-worker1, swarm-worker2, swarm-worker3
#
# Ce script :
#   1. Installe le client NFS
#   2. Crée le point de montage
#   3. Monte le partage NFS
#   4. Rend le montage permanent via /etc/fstab
# =============================================================================

set -e

NFS_SERVER="192.168.56.20"          # swarm-nfs
NFS_SHARE="/srv/nfs/swarm"
MOUNT_POINT="/mnt/nfs/swarm"
FSTAB_FILE="/etc/fstab"

echo "========================================"
echo "  Montage NFS — $(hostname)"
echo "  Serveur : $NFS_SERVER:$NFS_SHARE"
echo "  Point   : $MOUNT_POINT"
echo "========================================"
echo ""

# 1. Installation du client NFS
echo "📦 [1/4] Installation de nfs-common..."
sudo apt update
sudo apt install -y nfs-common

# 2. Vérification que le serveur NFS est joignable
echo "🔍 [2/4] Vérification de la connexion au serveur NFS..."
if ! ping -c 1 -W 2 "$NFS_SERVER" &>/dev/null; then
    echo "❌ swarm-nfs ($NFS_SERVER) n'est pas joignable."
    echo "   Vérifier : VM démarrée, IP configurée, /etc/hosts à jour."
    exit 1
fi
echo "   ✅ swarm-nfs est joignable."

# 3. Création du point de montage
echo "📁 [3/4] Création du point de montage $MOUNT_POINT..."
sudo mkdir -p "$MOUNT_POINT"

# 4. Montage
echo "🔗 [4/4] Montage du partage NFS..."

# Vérifier si déjà monté
if mountpoint -q "$MOUNT_POINT"; then
    echo "   ⚠️  $MOUNT_POINT est déjà monté."
else
    sudo mount "$NFS_SERVER:$NFS_SHARE" "$MOUNT_POINT"
    echo "   ✅ Montage effectué."
fi

# Vérification du montage
echo ""
echo "📊 Vérification :"
df -h | grep nfs

# Persistance dans /etc/fstab
FSTAB_ENTRY="$NFS_SERVER:$NFS_SHARE $MOUNT_POINT nfs defaults 0 0"

if grep -q "$NFS_SHARE" "$FSTAB_FILE"; then
    echo ""
    echo "ℹ️  Une entrée NFS existe déjà dans /etc/fstab."
else
    echo "$FSTAB_ENTRY" | sudo tee -a "$FSTAB_FILE" > /dev/null
    echo ""
    echo "✅ Entrée ajoutée dans /etc/fstab (montage permanent au démarrage)"
fi

echo ""
echo "========================================"
echo "✅ NFS monté sur $(hostname) : $MOUNT_POINT"
echo "========================================"
