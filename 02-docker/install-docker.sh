#!/bin/bash
# =============================================================================
# install-docker.sh — Installation de Docker CE sur Debian 12
# =============================================================================
# À exécuter sur : swarm-manager, swarm-worker1, swarm-worker2, swarm-worker3
# ⚠️  NE PAS exécuter sur swarm-nfs (serveur NFS, pas besoin de Docker)
# =============================================================================

set -e

echo "========================================"
echo "  Installation de Docker CE — Debian 12 "
echo "========================================"
echo ""

# Vérifier qu'on n'est pas sur swarm-nfs
if [ "$(hostname)" = "swarm-nfs" ]; then
    echo "❌ Ce script ne doit pas être exécuté sur swarm-nfs."
    exit 1
fi

# 1. Mise à jour et dépendances
echo "📦 [1/5] Installation des dépendances..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# 2. Clé GPG officielle Docker
echo "🔑 [2/5] Ajout de la clé GPG Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Ajout du dépôt Docker
echo "📋 [3/5] Ajout du dépôt Docker..."
echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Installation de Docker
echo "🐳 [4/5] Installation de Docker CE..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 5. Ajout de l'utilisateur au groupe docker
echo "👤 [5/5] Ajout de $USER au groupe docker..."
sudo usermod -aG docker "$USER"

echo ""
echo "========================================"
echo "✅ Docker installé avec succès !"
echo "========================================"
echo ""

# Vérification version
docker --version

echo ""
echo "⚠️  IMPORTANT : Pour utiliser Docker sans sudo, vous devez vous déconnecter"
echo "   et vous reconnecter (ou exécuter : newgrp docker)"
echo ""
echo "▶️  Prochaine étape : bash fix-ipv6.sh"
