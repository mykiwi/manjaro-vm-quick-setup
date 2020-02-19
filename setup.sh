#!/bin/bash
set -xe

while [ $# -gt 0 ]
do
    case $1 in
    --vbox)
        VIRTUALBOX=1
        ;;
    --secrets)
        SECRETS=1
        ;;

    esac
    shift
done

sudo pacman -Syyu
sudo pacman -Syyu

if [ -n "${VIRTUALBOX}" ]; then
    sudo pacman -S gcc make linux$(uname -r|sed 's/\W//g'|cut -c1-2)-headers virtualbox-guest-iso
    sudo mount -o loop /usr/lib/virtualbox/additions/VBoxGuestAdditions.iso /mnt
    sudo /mnt/VBoxLinuxAdditions.run
fi

cat <<'EOF' > /tmp/pamac.conf
RemoveUnrequiredDeps
RefreshPeriod = 6
NoUpdateHideIcon
EnableAUR
CheckAURUpdates
BuildDirectory = /var/tmp
KeepNumPackages = 3
OnlyRmUninstalled
DownloadUpdates
MaxParallelDownloads = 4
EOF
sudo mv /tmp/pamac.conf /etc/pamac.conf

pamac install --no-confirm \
  docker \
  docker-compose \
  docker-machine \
  firefox-developer-edition \
  neovim \
  pigz \
  zsh
# pigz is for docker

pamac build --no-confirm \
  brave-bin \
  jetbrains-toolbox \
  keybase-bin \
  sublime-text-dev \
  visual-studio-code-bin

sudo groupadd docker || true
sudo usermod -aG docker $USER
sudo systemctl enable docker

pamac install --no-confirm \
  nodejs \
  npm \
  php \
  php-apcu \
  php-gd \
  php-intl \
  php-mongodb \
  php-pgsql \
  php-redis \
  php-sqlite \
  php-sodium \
  xdebug
pamac build --no-confirm \
  php-amqp \
  php-blackfire

if [ ! -f "/usr/local/bin/composer" ]; then
    sudo curl -sSL -o /usr/local/bin/composer https://getcomposer.org/composer-stable.phar
    sudo chmod +x /usr/local/bin/composer
fi
if [ ! -f "/usr/local/bin/symfony" ]; then
    wget https://get.symfony.com/cli/installer -O - | bash
    sudo ln -s /home/mykiwi/.symfony/bin/symfony /usr/local/bin/symfony
fi

# Private stuff
if [ -n "${SECRETS}" ]; then
    keybase login --devicename=$(date "+%Y-%m")-vm-$(uuidgen) mykiwi

    if [ ! -d "${HOME}/.ssh" ]; then
        keybase fs cp -r /keybase/private/mykiwi/setup/linux/vm-ssh-key ~/.ssh
        chmod 700 ~/.ssh
        chmod 600 ~/.ssh/id*
        chmod 655 ~/.ssh/id*.pub
    fi

    if [ ! -d "${HOME}/.dotfiles" ]; then
        mkdir -p ~/dev/github.com/mykiwi
        git clone --recursive git@github.com:mykiwi/dotfiles.git ~/dev/github.com/mykiwi/dotfiles
        sh -c 'cd ~/dev/github.com/mykiwi/dotfiles && install.sh'
        git clone --recursive git@github.com:mykiwi/dotfiles.private.git ~/dev/github.com/mykiwi/dotfiles.private
        sh -c 'cd ~/dev/github.com/mykiwi/dotfiles.private/ && install.sh'
    fi

    if [ ${SHELL} != "/usr/bin/zsh" ]; then
        chsh -s /usr/bin/zsh
    fi
fi
