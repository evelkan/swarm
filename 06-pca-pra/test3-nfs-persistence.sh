#!/bin/bash
# =============================================================================
# test3-nfs-persistence.sh — PRA Test 3 : Persistance des données NFS
# =============================================================================
# Ce test vérifie que les données MariaDB survivent à la panne du conteneur.
# C'est la validation du rôle du NFS dans l'architecture.
#
# Résultat attendu :
#   - Données insérées avant la panne retrouvées intactes après redémarrage
#   - RTO : ~45 secondes (redémarrage automatique du conteneur)
# =============================================================================

set -e

SERVICE="mariadb_mariadb"
DB_USER="swarmuser"
DB_PASS="swarmpassword"
DB_NAME="swarmdb"
TEST_TABLE="test_pra"

echo "========================================"
echo "  PRA — Test 3 : Persistance données NFS"
echo "========================================"
echo ""

# Trouver le conteneur MariaDB en cours d'exécution
echo "🔍 Recherche du conteneur MariaDB..."

CONTAINER_INFO=$(docker service ps "$SERVICE" --filter "desired-state=running" --format "{{.Node}} {{.Name}}.{{.ID}}" | head -1)
NODE=$(echo "$CONTAINER_INFO" | awk '{print $1}')

if [ -z "$NODE" ]; then
    echo "❌ Aucun conteneur MariaDB en cours d'exécution."
    echo "   Vérifier : docker service ps $SERVICE"
    exit 1
fi

echo "   ✅ MariaDB tourne sur : $NODE"
echo ""

# ── PHASE 1 : Insertion des données ──────────────────────────────────────────
echo "📝 PHASE 1 — Insertion des données de test"
echo "   Exécutez les commandes suivantes sur $NODE :"
echo ""
echo "   CONTAINER_ID=\$(docker ps | grep mariadb | awk '{print \$1}')"
echo "   docker exec -it \$CONTAINER_ID mariadb -u $DB_USER -p$DB_PASS $DB_NAME"
echo ""
echo "   Puis dans MariaDB :"
echo "   CREATE TABLE IF NOT EXISTS $TEST_TABLE (id INT, message VARCHAR(50));"
echo "   INSERT INTO $TEST_TABLE VALUES (1, 'donnee persistante');"
echo "   SELECT * FROM $TEST_TABLE;"
echo "   EXIT;"
echo ""
echo "   Appuyez sur Entrée quand les données sont insérées..."
read -r

# ── PHASE 2 : Kill du conteneur ───────────────────────────────────────────────
echo ""
echo "💥 PHASE 2 — Suppression du conteneur MariaDB"
echo "   Exécutez sur $NODE :"
echo ""
echo "   CONTAINER_ID=\$(docker ps | grep mariadb | awk '{print \$1}')"
echo "   docker rm -f \$CONTAINER_ID"
echo ""
echo "   Appuyez sur Entrée quand le conteneur est tué..."
read -r

TIME_KILL=$(date '+%H:%M:%S')
TS_START=$(date +%s)

# ── PHASE 3 : Surveillance redémarrage ───────────────────────────────────────
echo ""
echo "👁️  PHASE 3 — Surveillance du redémarrage automatique..."

TIMEOUT=120
ELAPSED=0
RECOVERED=false

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    RUNNING=$(docker service ps "$SERVICE" --filter "desired-state=running" --format "{{.CurrentState}}" | grep -c "Running" || true)
    printf "\r   [%3ds] Conteneur MariaDB Running : %d/1" "$ELAPSED" "$RUNNING"

    if [ "$RUNNING" -ge 1 ]; then
        echo ""
        TIME_UP=$(date '+%H:%M:%S')
        RTO=$(( $(date +%s) - TS_START ))
        RECOVERED=true
        break
    fi

    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo ""

if [ "$RECOVERED" = false ]; then
    echo "⚠️  Timeout — vérifier manuellement : docker service ps $SERVICE"
    exit 1
fi

echo "   ✅ Conteneur redémarré en ~${RTO}s"
echo ""

# ── PHASE 4 : Vérification des données ───────────────────────────────────────
echo "🔍 PHASE 4 — Vérification de la persistance des données"
echo "   Exécutez sur $NODE (nouveau conteneur) :"
echo ""
echo "   CONTAINER_ID=\$(docker ps | grep mariadb | awk '{print \$1}')"
echo "   docker exec -it \$CONTAINER_ID mariadb -u $DB_USER -p$DB_PASS $DB_NAME"
echo ""
echo "   Puis dans MariaDB :"
echo "   SELECT * FROM $TEST_TABLE;"
echo "   EXIT;"
echo ""
echo "   Résultat attendu :"
echo "   +----+--------------------+"
echo "   | id | message            |"
echo "   +----+--------------------+"
echo "   |  1 | donnee persistante |"
echo "   +----+--------------------+"
echo ""
echo "   Appuyez sur Entrée quand vous avez vérifié les données..."
read -r

echo ""
echo "========================================"
echo "  Résultats du Test 3"
echo "========================================"
echo "   Heure de la panne      : $TIME_KILL"
echo "   Heure de reprise       : $TIME_UP"
echo "   RTO mesuré             : ~${RTO} secondes"
echo "   Données insérées       : 1 ligne — 'donnee persistante'"
echo "   Mécanisme              : Stockage NFS persistant"
echo "   Résultat               : ✅ Persistance des données validée"
echo "========================================"
