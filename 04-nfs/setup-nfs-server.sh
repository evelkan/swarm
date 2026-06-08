#!/bin/bash
# =============================================================================
# setup-nfs-server.sh — Configuration du serveur NFS (swarm-nfs)
# =============================================================================
# ⚠️  À exécuter UNIQUEMENT sur swarm-nfs
#
# Ce script :
#   1. Installe nfs-kernel-server
#   2. Crée et configure le dossier partagé /srv/nfs/swarm
#   3. Configure /etc/exports
#   4. Active et démarre le service NFS
# =============================================================================

set -e

NFS_DIR="/srv/nfs/swarm"
EXPORTS_FILE="/etc/exports"
NETWORK="192.168.56.0/24"

echo "========================================"
echo "  Configuration du serveur NFS"
echo "  Partage : $NFS_DIR → $NETWORK"
echo "========================================"
echo ""

# Vérifier qu'on est sur swarm-nfs
if [ "$(hostname)" != "swarm-nfs" ]; then
    echo "⚠️  Ce script est prévu pour swarm-nfs (hostname actuel : $(hostname))."
    read -p "Continuer quand même ? (o/N) : " CONFIRM
    [[ "$CONFIRM" != "o" && "$CONFIRM" != "O" ]] && exit 0
fi

# 1. Installation
echo "📦 [1/4] Installation de nfs-kernel-server..."
sudo apt update
sudo apt install -y nfs-kernel-server

# 2. Création du dossier partagé et sous-dossiers services
echo "📁 [2/4] Création des dossiers partagés..."
sudo mkdir -p "$NFS_DIR"
sudo mkdir -p "$NFS_DIR/registry"
sudo mkdir -p "$NFS_DIR/mariadb"
sudo mkdir -p "$NFS_DIR/html"
sudo mkdir -p "$NFS_DIR/nginx"
sudo mkdir -p "$NFS_DIR/vscode"

sudo chown -R nobody:nogroup "$NFS_DIR"
sudo chmod -R 777 "$NFS_DIR"

echo "   Dossiers créés :"
ls -la "$NFS_DIR"

# 3. Configuration des exports
echo "📋 [3/4] Configuration de /etc/exports..."

EXPORT_LINE="$NFS_DIR $NETWORK(rw,sync,no_subtree_check,no_root_squash)"

if grep -q "$NFS_DIR" "$EXPORTS_FILE"; then
    echo "   ⚠️  Une entrée pour $NFS_DIR existe déjà dans /etc/exports."
else
    echo "$EXPORT_LINE" | sudo tee -a "$EXPORTS_FILE" > /dev/null
    echo "   ✅ Export ajouté : $EXPORT_LINE"
fi

# Appliquer les exports
sudo exportfs -a
echo "   Exports actifs :"
sudo exportfs -v

# 4. Activation et démarrage du service NFS
echo "🔄 [4/4] Démarrage du service NFS..."
sudo systemctl enable nfs-kernel-server
sudo systemctl restart nfs-kernel-server
sudo systemctl status nfs-kernel-server --no-pager | grep "Active:"

echo ""
echo "========================================"
echo "✅ Serveur NFS opérationnel !"
echo "   Partage : $NFS_DIR"
echo "   Réseau  : $NETWORK"
echo "========================================"
echo ""
echo "▶️  Prochaine étape : exécuter mount-nfs-client.sh sur chaque worker et le manager"
