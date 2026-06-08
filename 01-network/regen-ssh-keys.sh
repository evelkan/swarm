#!/bin/bash
# =============================================================================
# regen-ssh-keys.sh — Régénération des clés SSH hôte (clones VMware)
# =============================================================================
#  À exécuter sur CHAQUE CLONE après le clonage depuis swarm-manager.
#     Les clones partagent les mêmes clés SSH par défaut — cela pose un
#     problème de sécurité et peut empêcher les connexions SSH correctes.
# =============================================================================

set -e

echo " Régénération des clés SSH hôte..."
echo " Cette opération va supprimer les clés existantes et en générer de nouvelles."
echo ""

read -p "Confirmer ? (o/N) : " CONFIRM
if [[ "$CONFIRM" != "o" && "$CONFIRM" != "O" ]]; then
    echo " Annulé."
    exit 0
fi

# Supprimer les anciennes clés
echo " Suppression des anciennes clés..."
sudo rm -f /etc/ssh/ssh_host_*

# Régénérer les clés
echo " Génération de nouvelles clés..."
sudo dpkg-reconfigure openssh-server

# Redémarrer SSH
echo "Redémarrage du service SSH..."
sudo systemctl restart ssh

echo ""
echo " Nouvelles clés SSH générées :"
ls -la /etc/ssh/ssh_host_*
echo ""
echo " Si vous vous reconnectez en SSH depuis votre hôte, acceptez la nouvelle clé"
echo "   ou supprimez l'ancienne entrée dans ~/.ssh/known_hosts :"
echo "   ssh-keygen -R $(hostname -I | awk '{print $1}')"
