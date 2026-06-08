#!/bin/bash
# =============================================================================
# init-manager.sh — Initialisation du cluster Docker Swarm (Manager)
# =============================================================================
# ⚠️  À exécuter UNIQUEMENT sur swarm-manager
#
# Ce script :
#   1. Initialise le Swarm sur l'IP Host-Only (192.168.56.10)
#   2. Affiche le token à utiliser sur chaque worker
#   3. Vérifie l'état du nœud manager
# =============================================================================

set -e

MANAGER_IP="192.168.56.10"

echo "========================================"
echo "  Initialisation du cluster Docker Swarm"
echo "========================================"
echo ""

# Vérifier qu'on est bien sur le manager
if [ "$(hostname)" != "swarm-manager" ]; then
    echo "⚠️  Ce script est prévu pour swarm-manager (hostname actuel : $(hostname))."
    read -p "Continuer quand même ? (o/N) : " CONFIRM
    [[ "$CONFIRM" != "o" && "$CONFIRM" != "O" ]] && exit 0
fi

# Vérifier que Docker est installé
if ! command -v docker &>/dev/null; then
    echo "❌ Docker n'est pas installé. Exécutez d'abord install-docker.sh"
    exit 1
fi

# Vérifier si un Swarm est déjà initialisé
SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
if [ "$SWARM_STATE" = "active" ]; then
    echo "⚠️  Un Swarm est déjà initialisé sur ce nœud."
    docker node ls
    echo ""
    echo "ℹ️  Pour récupérer le token worker : docker swarm join-token worker"
    exit 0
fi

# Initialisation du Swarm
echo "🐝 Initialisation du Swarm sur $MANAGER_IP (port 2377)..."
docker swarm init --advertise-addr "$MANAGER_IP"

echo ""
echo "========================================"
echo "✅ Swarm initialisé — swarm-manager est Leader"
echo "========================================"
echo ""

# Afficher le token worker
echo "📋 Token pour les workers (à copier sur chaque worker) :"
echo ""
docker swarm join-token worker
echo ""

# Vérification
echo "🔍 État du cluster :"
docker node ls

echo ""
echo "▶️  Prochaine étape : exécuter join-worker.sh sur chaque worker"
echo "   en copiant la commande 'docker swarm join --token ...' ci-dessus."
