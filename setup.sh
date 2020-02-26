#!/bin/bash
set -e

NEED_PASSWORD=0
if [ $# -eq 0 ]; then
    SYSTEM=1
    PACKAGES=1
    KEYBASE=1
    SSH=1
    ZSH=1
    FONTS=1
fi

while [ $# -gt 0 ]
do
    case $1 in
    all)
        SYSTEM=1
        PACKAGES=1
        KEYBASE=1
        SSH=1
        ZSH=1
        FONTS=1
        ;;
    system)
        SYSTEM=1
        NEED_PASSWORD=1
        ;;
    packages)
        PACKAGES=1
        NEED_PASSWORD=1
        ;;
    keybase)
        KEYBASE=1
        ;;
    ssh)
        SSH=1
        ;;
    zsh)
        ZSH=1
        NEED_PASSWORD=1
        ;;
    fonts)
        FONTS=1
        ;;

    -d | --debug)
        set -x
        ;;
    -h | --help)
        cat <<EOF
Specific parameters
  all
  system
  packages
  keybase
  ssh
  zsh
  fonts
EOF
        exit
        ;;

    esac
    shift
done

if [ -n "${NEED_PASSWORD}" ]; then
    echo -n "[sudo] password for $USER: "
    read -s PASSWORD
fi

if [ -n "${SYSTEM}" ]; then
    yes $PASSWORD | sudo pacman -Syyu
fi

## VirtualBox / deprecated
# sudo pacman -S gcc make linux$(uname -r|sed 's/\W//g'|cut -c1-2)-headers virtualbox-guest-iso
# sudo mount -o loop /usr/lib/virtualbox/additions/VBoxGuestAdditions.iso /mnt
# sudo /mnt/VBoxLinuxAdditions.run

if [ -n "${PACKAGES}" ]; then
    # clock issue
    yes $PASSWORD | sudo pacman -S --noconfirm --needed ntp
    yes $PASSWORD | sudo timedatectl set-ntp true

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
    yes $PASSWORD | sudo mv /tmp/pamac.conf /etc/pamac.conf

    yes $PASSWORD | pamac install --no-confirm \
        docker \
        docker-compose \
        docker-machine \
        firefox-developer-edition \
        gnu-netcat \
        httpie \
        jq \
        neovim \
        pigz \
        zsh
    # pigz is for docker

    yes $PASSWORD | pamac build --no-confirm \
        brave-bin \
        jetbrains-toolbox \
        keybase-bin \
        sublime-text-dev \
        visual-studio-code-bin

    yes $PASSWORD | sudo groupadd docker || true
    yes $PASSWORD | sudo usermod -aG docker $USER
    yes $PASSWORD | sudo systemctl enable docker

    yes $PASSWORD | pamac install --no-confirm \
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
    yes $PASSWORD | pamac build --no-confirm \
        php-amqp \
        php-blackfire

    if [ ! -f "/usr/local/bin/composer" ]; then
        yes $PASSWORD | curl -sSL -o /usr/local/bin/composer https://getcomposer.org/composer-stable.phar
        yes $PASSWORD | chmod +x /usr/local/bin/composer
    fi
    if [ ! -f "/usr/local/bin/symfony" ]; then
        wget https://get.symfony.com/cli/installer -O - | bash
        yes $PASSWORD | ln -s /home/mykiwi/.symfony/bin/symfony /usr/local/bin/symfony
    fi
fi


if [ -n "${KEYBASE}" ]; then
    keybase login --devicename=$(date "+%Y-%m")-vm-$(uuidgen) mykiwi
    sleep 1
fi

if [ -n "${SSH}" ]; then
    KEYBASE_OK=$(keybase login)
    if [ $KEYBASE_OK -ne 0 ]; then
        echo "Must be login on Keybase"
        exit 1
    fi

    if [ ! -d "${HOME}/.ssh" ]; then
        keybase fs cp -r /keybase/private/mykiwi/setup/linux/vm-ssh-key ~/.ssh
        chmod 700 ~/.ssh
        chmod 600 ~/.ssh/id*
        chmod 655 ~/.ssh/id*.pub
    fi
fi

if [ -n "${ZSH}" ]; then
    if [ ! -d "${HOME}/.dotfiles" ]; then
        mkdir -p ~/dev/github.com/mykiwi
        git clone --recursive git@github.com:mykiwi/dotfiles.git ~/dev/github.com/mykiwi/dotfiles
        sh -c 'cd ~/dev/github.com/mykiwi/dotfiles && ./install.sh'
        git clone --recursive git@github.com:mykiwi/dotfiles.private.git ~/dev/github.com/mykiwi/dotfiles.private
        sh -c 'cd ~/dev/github.com/mykiwi/dotfiles.private/ && ./install.sh'
    fi

    if [ ${SHELL} != "/usr/bin/zsh" ]; then
        chsh -s /usr/bin/zsh
    fi
fi

if [ -n "${FONTS}" ]; then

    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts
    curl -fLo "JetBrains Mono Regular Nerd Font Complete Mono.otf" https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/JetBrainsMono/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete%20Mono.ttf
    curl -fLo "JetBrains Mono Regular Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/JetBrainsMono/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete.ttf
    fc-cache -f -v

fi
