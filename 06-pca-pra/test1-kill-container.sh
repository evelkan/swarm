#!/bin/bash
# =============================================================================
# test1-kill-container.sh — PCA Test 1 : Simulation perte d'un conteneur Nginx
# =============================================================================
# Ce test simule la panne brutale d'un conteneur Nginx.
# On tue manuellement le conteneur et on mesure le temps de reprise (RTO).
#
# Résultat attendu :
#   - Swarm détecte la panne (exit code 137 = kill forcé)
#   - Redémarrage automatique sur le même worker
#   - RTO mesuré : ~45 secondes
# =============================================================================

set -e

SERVICE="web_nginx"
WATCH_INTERVAL=3
TIMEOUT=120   # secondes max d'attente

echo "========================================"
echo "  PCA — Test 1 : Perte d'un conteneur   "
echo "  Service : $SERVICE                     "
echo "========================================"
echo ""

# Vérifier qu'on est sur le manager
if ! docker node ls &>/dev/null; then
    echo "❌ Ce script doit être exécuté sur le manager Swarm."
    exit 1
fi

# État initial
echo "📊 État initial du service :"
docker service ps "$SERVICE" --no-trunc | head -5
echo ""

# Trouver le premier conteneur Nginx en cours d'exécution
CONTAINER_INFO=$(docker service ps "$SERVICE" --filter "desired-state=running" --format "{{.Node}} {{.Name}}.{{.ID}}" | head -1)
NODE=$(echo "$CONTAINER_INFO" | awk '{print $1}')
CONTAINER_NAME=$(echo "$CONTAINER_INFO" | awk '{print $2}')

if [ -z "$NODE" ]; then
    echo "❌ Aucun conteneur $SERVICE en cours d'exécution."
    exit 1
fi

echo "🎯 Conteneur cible : $CONTAINER_NAME sur $NODE"
echo ""

# Enregistrer l'heure de la panne
TIME_START=$(date '+%H:%M:%S')
TS_START=$(date +%s)

echo "💥 Simulation de la panne à $TIME_START..."
echo "   Commande à exécuter SUR $NODE :"
echo ""
echo "   docker ps | grep nginx"
echo "   docker rm -f <ID_CONTENEUR>"
echo ""
echo "⚠️  Exécutez ces commandes manuellement sur $NODE dans un autre terminal."
echo "   Appuyez sur Entrée ici quand c'est fait..."
read -r

echo ""
echo "👁️  Surveillance de la reprise (toutes les ${WATCH_INTERVAL}s, timeout ${TIMEOUT}s)..."
echo ""

RECOVERED=false
ELAPSED=0

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    RUNNING=$(docker service ps "$SERVICE" --filter "desired-state=running" --format "{{.CurrentState}}" | grep -c "Running" || true)

    printf "\r   [%3ds] Conteneurs Running : %d/2" "$ELAPSED" "$RUNNING"

    if [ "$RUNNING" -ge 2 ]; then
        echo ""
        TIME_END=$(date '+%H:%M:%S')
        TS_END=$(date +%s)
        RTO=$((TS_END - TS_START))
        RECOVERED=true
        break
    fi

    sleep "$WATCH_INTERVAL"
    ELAPSED=$((ELAPSED + WATCH_INTERVAL))
done

echo ""
echo ""
echo "========================================"
if [ "$RECOVERED" = true ]; then
    echo "✅ Service rétabli automatiquement !"
    echo ""
    echo "   Heure de la panne  : $TIME_START"
    echo "   Heure de reprise   : $TIME_END"
    echo "   RTO mesuré         : ~${RTO} secondes"
    echo "   Action Swarm       : Redémarrage automatique"
else
    echo "⚠️  Timeout dépassé — vérifier manuellement :"
    echo "   docker service ps $SERVICE"
fi
echo "========================================"
echo ""

echo "📊 État final du service :"
docker service ps "$SERVICE"
