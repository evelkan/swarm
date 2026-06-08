#!/bin/bash
# =============================================================================
# test2-kill-node.sh — PRA Test 2 : Simulation perte d'un nœud Worker
# =============================================================================
# Ce test simule la panne complète de swarm-worker1.
# On éteint la VM et on observe la redistribution automatique des conteneurs.
#
# Résultat attendu :
#   - Swarm détecte la disparition du nœud après un timeout
#   - Replanification des conteneurs sur les workers restants
#   - Réintégration automatique au redémarrage de la VM
#   - RTO mesuré : ~2 minutes (timeout Swarm inclus)
# =============================================================================

set -e

TARGET_NODE="swarm-worker1"
SERVICE="web_nginx"
WATCH_INTERVAL=10
TIMEOUT=300   # 5 minutes max

echo "========================================"
echo "  PRA — Test 2 : Perte d'un nœud Worker "
echo "  Nœud cible : $TARGET_NODE              "
echo "========================================"
echo ""

# Vérification
if ! docker node ls &>/dev/null; then
    echo "❌ Ce script doit être exécuté sur le manager Swarm."
    exit 1
fi

# État initial
echo "📊 État initial du cluster :"
docker node ls
echo ""
echo "📊 État initial des services :"
docker service ls
echo ""

echo "🔴 ÉTAPE 1 — Éteindre $TARGET_NODE"
echo "   Connectez-vous à $TARGET_NODE et exécutez :"
echo "   sudo poweroff"
echo ""
echo "   Appuyez sur Entrée ici quand la VM est éteinte..."
read -r

TIME_START=$(date '+%H:%M:%S')
TS_START=$(date +%s)

echo ""
echo "👁️  Surveillance du cluster (toutes les ${WATCH_INTERVAL}s)..."
echo ""

NODE_DOWN=false
SERVICES_RECOVERED=false
ELAPSED=0

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    NODE_STATUS=$(docker node ls --filter "name=$TARGET_NODE" --format "{{.Status}}" 2>/dev/null || echo "unknown")
    RUNNING=$(docker service ps "$SERVICE" --filter "desired-state=running" --format "{{.CurrentState}}" 2>/dev/null | grep -c "Running" || true)

    printf "\r   [%3ds] Nœud %s : %-12s | Conteneurs Running : %d" \
        "$ELAPSED" "$TARGET_NODE" "$NODE_STATUS" "$RUNNING"

    if [ "$NODE_STATUS" = "Down" ] && [ "$NODE_DOWN" = false ]; then
        echo ""
        echo "   ⚠️  [$( date '+%H:%M:%S')] $TARGET_NODE détecté comme Down par Swarm"
        NODE_DOWN=true
    fi

    if [ "$RUNNING" -ge 2 ] && [ "$NODE_DOWN" = true ]; then
        echo ""
        TIME_END=$(date '+%H:%M:%S')
        TS_END=$(date +%s)
        RTO=$((TS_END - TS_START))
        SERVICES_RECOVERED=true
        break
    fi

    sleep "$WATCH_INTERVAL"
    ELAPSED=$((ELAPSED + WATCH_INTERVAL))
done

echo ""
echo ""
echo "========================================"
if [ "$SERVICES_RECOVERED" = true ]; then
    echo "✅ Basculement automatique réussi !"
    echo ""
    echo "   Heure de la panne       : $TIME_START"
    echo "   Heure de reprise        : $TIME_END"
    echo "   RTO mesuré              : ~${RTO} secondes"
    echo "   Worker de basculement   : voir docker service ps $SERVICE"
else
    echo "⚠️  Timeout ou état inattendu — vérifier manuellement :"
    echo "   docker node ls"
    echo "   docker service ps $SERVICE"
fi
echo "========================================"
echo ""

echo "📊 État du cluster après panne :"
docker node ls
echo ""
echo "📊 Redistribution des services :"
docker service ps "$SERVICE"

echo ""
echo "🔵 ÉTAPE 2 — Redémarrer $TARGET_NODE"
echo "   Allumez la VM depuis VMware Workstation."
echo "   Le nœud devrait réintégrer le cluster automatiquement."
echo ""
echo "   Pour surveiller la réintégration :"
echo "   watch docker node ls"
