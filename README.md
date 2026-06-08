# 🐳 Docker Swarm — Scripts d'infrastructure

> Projet réalisé dans le cadre d'un apprentissage DevOps à La Plateforme.  
> Déploiement d'un cluster Docker Swarm haute disponibilité sur 5 VMs Debian 12 (VMware Workstation).

---

## 📐 Architecture

| Rôle      | Hostname       | IP              | RAM   | CPU    | Disque |
|-----------|----------------|-----------------|-------|--------|--------|
| Manager   | swarm-manager  | 192.168.56.10   | 2 Go  | 2 vCPU | 15 Go  |
| Worker 1  | swarm-worker1  | 192.168.56.11   | 2 Go  | 2 vCPU | 15 Go  |
| Worker 2  | swarm-worker2  | 192.168.56.12   | 2 Go  | 2 vCPU | 15 Go  |
| Worker 3  | swarm-worker3  | 192.168.56.13   | 2 Go  | 2 vCPU | 15 Go  |
| NFS       | swarm-nfs      | 192.168.56.20   | 512 Mo| 1 vCPU | 20 Go  |

**Réseau Host-Only :** VMnet1 — `192.168.56.0/24`  
**Interface NAT :** `ens32` | **Interface Host-Only :** `ens34`

---

## 📁 Structure du dépôt

```
.
├── 00-base/
│   └── hosts-template          # Contenu type du fichier /etc/hosts
├── 01-network/
│   ├── set-hostname.sh         # Changement du hostname
│   ├── set-static-ip.sh        # Configuration IP statique
│   ├── populate-hosts.sh       # Remplissage /etc/hosts
│   ├── regen-ssh-keys.sh       # Régénération des clés SSH (clones)
│   └── test-connectivity.sh    # Test de ping inter-VMs
├── 02-docker/
│   ├── install-docker.sh       # Installation de Docker CE
│   └── fix-ipv6.sh             # Correction IPv6 daemon Docker
├── 03-swarm/
│   ├── init-manager.sh         # Initialisation du Swarm (manager)
│   └── join-worker.sh          # Jonction des workers au Swarm
├── 04-nfs/
│   ├── setup-nfs-server.sh     # Configuration du serveur NFS
│   └── mount-nfs-client.sh     # Montage NFS sur les workers/manager
├── 05-stacks/
│   ├── registry.yml            # Stack Registry Docker privé
│   ├── mariadb.yml             # Stack MariaDB
│   ├── web.yml                 # Stack Nginx + PHP
│   ├── vscode.yml              # Stack VSCode Server
│   └── deploy-all.sh           # Déploiement de toutes les stacks
└── 06-pca-pra/
    ├── test1-kill-container.sh  # Test 1 : perte d'un conteneur
    ├── test2-kill-node.sh       # Test 2 : perte d'un nœud worker
    └── test3-nfs-persistence.sh # Test 3 : persistance données NFS
```

---

## 🚀 Ordre de déploiement

```
1. Cloner les VMs dans VMware (4 clones complets depuis swarm-manager)
2. 01-network/ → configurer hostname, IP, /etc/hosts, SSH sur chaque VM
3. 02-docker/  → installer Docker sur manager + workers (pas NFS)
4. 03-swarm/   → initialiser le cluster Swarm
5. 04-nfs/     → configurer le serveur NFS, monter sur tous les nœuds
6. 05-stacks/  → déployer les services
7. 06-pca-pra/ → exécuter les tests de résilience
```

---

## 🔧 Services déployés

| Service       | URL d'accès                    | Réplicas | Nœud    |
|---------------|--------------------------------|----------|---------|
| Registry      | http://192.168.56.10:5000      | 1/1      | Manager |
| MariaDB       | (interne)                      | 1/1      | Worker  |
| Nginx         | http://192.168.56.10           | 2/2      | Workers |
| PHP           | (interne, via Nginx)           | 2/2      | Workers |
| VSCode Server | http://192.168.56.11:8080      | 1/1      | Worker  |

---

## 📋 Résultats PCA/PRA

| Test   | Scénario                   | RTO         | Résultat            |
|--------|----------------------------|-------------|---------------------|
| Test 1 | Perte d'un conteneur Nginx | ~45 secondes| ✅ Redémarrage auto |
| Test 2 | Perte d'un nœud Worker     | ~2 minutes  | ✅ Basculement auto |
| Test 3 | Persistance données NFS    | —           | ✅ Données intactes |
