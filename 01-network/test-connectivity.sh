#!/bin/bash
# =============================================================================
# test-connectivity.sh — Tests de ping inter-VMs depuis swarm-manager
# =============================================================================
# À exécuter depuis swarm-manager une fois tous les nœuds configurés.
# Vérifie que chaque nœud est joignable par nom ET par IP.
# =============================================================================

NODES_NAME=("swarm-worker1" "swarm-worker2" "swarm-worker3" "swarm-nfs")
NODES_IP=("192.168.56.11"   "192.168.56.12"  "192.168.56.13"  "192.168.56.20")

PASS=0
FAIL=0

echo "========================================"
echo "  Test de connectivité — Cluster Swarm  "
echo "========================================"
echo ""

ping_test() {
    local TARGET="$1"
    local LABEL="$2"
    if ping -c 2 -W 2 "$TARGET" &>/dev/null; then
        echo "  $LABEL ($TARGET) — OK"
        ((PASS++))
    else
        echo "   $LABEL ($TARGET) — ÉCHEC"
        ((FAIL++))
    fi
}

echo "--- Ping par nom (résolution /etc/hosts) ---"
for NAME in "${NODES_NAME[@]}"; do
    ping_test "$NAME" "$NAME"
done

echo ""
echo "--- Ping par IP ---"
for i in "${!NODES_IP[@]}"; do
    ping_test "${NODES_IP[$i]}" "${NODES_NAME[$i]}"
done

echo ""
echo "========================================"
echo "  Résultat : $PASS succès / $FAIL échec(s)"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo " En cas d'échec, vérifier :"
    echo "   - La VM cible est bien démarrée"
    echo "   - L'IP statique est configurée sur ens34"
    echo "   - /etc/hosts est bien rempli sur cette VM"
    exit 1
fi

echo ""
echo "Tous les nœuds sont joignables — réseau Swarm opérationnel !"
