#!/bin/bash
# =============================================================================
# join-worker.sh — Jonction d'un worker au cluster Swarm
# =============================================================================
# ⚠️  À exécuter sur chaque worker : swarm-worker1, worker2, worker3
#
# Usage : bash join-worker.sh <token> [ip-manager]
# Exemple:
#   bash join-worker.sh SWMTKN-1-3qbwvfae1sm38xcgn4hkjq0lure71fn3ckzzp3nsq1hr0yyru7-2o443t98hv5jb8u1g8z45j6sx
#
# Le token est affiché par init-manager.sh ou via :
#   docker swarm join-token worker   (depuis le manager)
# =============================================================================

set -e

MANAGER_IP="${2:-192.168.56.10}"
MANAGER_PORT="2377"

if [ -z "$1" ]; then
    echo "❌ Usage : bash join-worker.sh <token> [ip-manager]"
    echo ""
    echo "   Récupérer le token depuis swarm-manager :"
    echo "   docker swarm join-token worker"
    exit 1
fi

TOKEN="$1"

echo "========================================"
echo "  Jonction au cluster Swarm"
echo "  Manager : $MANAGER_IP:$MANAGER_PORT"
echo "========================================"
echo ""

# Vérifier qu'on n'est pas déjà dans un Swarm
SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo "inactive")
if [ "$SWARM_STATE" = "active" ]; then
    echo "⚠️  Ce nœud est déjà membre d'un Swarm."
    docker info --format 'Rôle : {{.Swarm.NodeID}}'
    exit 0
fi

# Jonction au Swarm
echo "🐝 Jonction au Swarm..."
docker swarm join --token "$TOKEN" "$MANAGER_IP:$MANAGER_PORT"

echo ""
echo "✅ $(hostname) a rejoint le Swarm en tant que worker !"
echo ""
echo "ℹ️  Vérifier depuis swarm-manager :"
echo "   docker node ls"
