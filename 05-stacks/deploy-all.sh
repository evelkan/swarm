#!/bin/bash
# =============================================================================
# deploy-all.sh — Déploiement de toutes les stacks Docker Swarm
# =============================================================================
# ⚠️  À exécuter UNIQUEMENT sur swarm-manager
#
# Prérequis :
#   - Swarm initialisé (init-manager.sh exécuté)
#   - NFS monté sur tous les nœuds (mount-nfs-client.sh exécuté)
#   - Dossiers NFS créés (setup-nfs-server.sh exécuté)
# =============================================================================

set -e

STACKS_DIR="$(dirname "$0")"
NFS_BASE="/mnt/nfs/swarm"

echo "========================================"
echo "  Déploiement des stacks Docker Swarm   "
echo "========================================"
echo ""

# Vérifications préalables
echo "🔍 Vérifications préalables..."

# Swarm actif ?
SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
if [ "$SWARM_STATE" != "active" ]; then
    echo "❌ Ce nœud n'est pas dans un Swarm. Exécutez d'abord init-manager.sh"
    exit 1
fi
echo "   ✅ Swarm actif"

# NFS monté ?
if ! mountpoint -q "$NFS_BASE"; then
    echo "❌ NFS non monté sur $NFS_BASE. Exécutez d'abord mount-nfs-client.sh"
    exit 1
fi
echo "   ✅ NFS monté"

# Nombre de workers ?
WORKERS=$(docker node ls --filter "role=worker" --format "{{.Status}}" | grep -c "Ready" || true)
echo "   ✅ Workers Ready : $WORKERS"

echo ""

# ── Préparer les fichiers sur le NFS ──────────────────────────────────────────
echo "📁 Préparation des fichiers NFS..."

# Page PHP de test
if [ ! -f "$NFS_BASE/html/index.php" ]; then
    echo '<?php phpinfo(); ?>' | sudo tee "$NFS_BASE/html/index.php" > /dev/null
    echo "   ✅ index.php créé"
fi

# Config Nginx
if [ ! -f "$NFS_BASE/nginx/default.conf" ]; then
    sudo cp "$STACKS_DIR/nginx-default.conf" "$NFS_BASE/nginx/default.conf"
    echo "   ✅ nginx default.conf copié"
fi

echo ""

# ── Déploiement des stacks ────────────────────────────────────────────────────
deploy_stack() {
    local NAME="$1"
    local FILE="$2"
    echo "🚀 Déploiement de la stack : $NAME"
    docker stack deploy -c "$FILE" "$NAME"
    echo "   ✅ $NAME déployée"
    echo ""
}

deploy_stack "registry" "$STACKS_DIR/registry.yml"
sleep 5

deploy_stack "mariadb"  "$STACKS_DIR/mariadb.yml"
sleep 5

deploy_stack "web"      "$STACKS_DIR/web.yml"
sleep 5

deploy_stack "vscode"   "$STACKS_DIR/vscode.yml"

# ── Résumé ─────────────────────────────────────────────────────────────────────
echo "⏳ Attente du démarrage des services (30s)..."
sleep 30

echo ""
echo "========================================"
echo "  Résumé des services déployés          "
echo "========================================"
docker service ls

echo ""
echo "📋 Accès aux services :"
echo "   Registry    → http://192.168.56.10:5000"
echo "   Nginx/PHP   → http://192.168.56.10"
echo "   VSCode      → http://192.168.56.11:8080  (mdp: vscode123)"
echo ""
echo "✅ Déploiement terminé !"
