#!/bin/bash

set -e  # Stoppe le script en cas d'erreur

# Met à jour la liste des paquets
sudo dnf clean all
sudo dnf makecache
sudo dnf -y update

# Installe les dépendances nécessaires
sudo dnf install -y dnf-utils curl git epel-release

# Ajoute le dépôt Docker officiel
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Installe Docker et ses dépendances
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Ajoute l'utilisateur 'vagrant' au groupe Docker
sudo usermod -aG docker vagrant

# Active et démarre Docker
sudo systemctl enable --now docker

# Installe Docker Compose
DOCKER_COMPOSE_VERSION="2.22.0"
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Vérifie si Docker Compose fonctionne bien
if ! /usr/local/bin/docker-compose version &> /dev/null; then
    echo "⚠️ Erreur : Docker Compose ne s'est pas installé correctement."
    exit 1
fi


# Vérifie si l'utilisateur veut installer Zsh
if [[ -n "$ENABLE_ZSH" && "$ENABLE_ZSH" == "true" ]]; then
    echo "🛠️ Installation de Zsh..."
    sudo dnf -y install zsh git

    # Change le shell de l'utilisateur vagrant
    sudo usermod --shell /bin/zsh vagrant

    # Installe Oh My Zsh
    su - vagrant -c 'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

    # Ajoute des plugins
    su - vagrant -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

    # Configure `.zshrc`
    su - vagrant -c "sed -i 's/^plugins=/#&/' ~/.zshrc"
    su - vagrant -c "echo 'plugins=(git docker docker-compose colored-man-pages aliases copyfile copypath dotenv zsh-syntax-highlighting jsontools)' >> ~/.zshrc"
    su - vagrant -c "sed -i 's/^ZSH_THEME=.*/ZSH_THEME=\"agnoster\"/' ~/.zshrc"
else
    echo "ℹ️ Zsh ne sera pas installé."
fi

# Récupère l'adresse IP
IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
echo "🔹 L'adresse IP de cette machine est : $IP_ADDRESS"
