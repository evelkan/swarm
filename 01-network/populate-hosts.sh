#!/bin/bash
# =============================================================================
# populate-hosts.sh — Remplissage de /etc/hosts avec tous les nœuds du cluster
# =============================================================================
# À exécuter sur CHAQUE VM du cluster (manager, workers, nfs).
# =============================================================================

set -e

HOSTS_FILE="/etc/hosts"
MARKER="# Cluster Docker Swarm"

echo "🔧 Mise à jour de /etc/hosts..."

# Vérifier si les entrées existent déjà
if grep -q "$MARKER" "$HOSTS_FILE"; then
    echo "⚠️  Les entrées du cluster sont déjà présentes dans $HOSTS_FILE."
    echo "   Contenu actuel :"
    grep -A6 "$MARKER" "$HOSTS_FILE"
    echo ""
    read -p "Voulez-vous les remplacer ? (o/N) : " CONFIRM
    if [[ "$CONFIRM" != "o" && "$CONFIRM" != "O" ]]; then
        echo "⏭️  Annulé."
        exit 0
    fi
    # Supprimer les anciennes entrées
    sudo sed -i "/$MARKER/,+6d" "$HOSTS_FILE"
fi

# Ajouter les entrées du cluster
sudo tee -a "$HOSTS_FILE" > /dev/null << 'EOF'

# Cluster Docker Swarm
192.168.56.10   swarm-manager
192.168.56.11   swarm-worker1
192.168.56.12   swarm-worker2
192.168.56.13   swarm-worker3
192.168.56.20   swarm-nfs
EOF

echo "✅ /etc/hosts mis à jour :"
echo ""
grep -A6 "$MARKER" "$HOSTS_FILE"
