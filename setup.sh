#!/bin/bash

sudo pacman -Syyu
sudo pacman -S gcc make linux$(uname -r|sed 's/\W//g'|cut -c1-2)-headers virtualbox-guest-iso
sudo mount -o loop /usr/lib/virtualbox/additions/VBoxGuestAdditions.iso /mnt
sudo /mnt/VBoxLinuxAdditions.run

cat <<'EOF' > pamac.conf
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
sudo mv pamac.conf /etc/pamac.conf

pamac install --no-confirm \
  docker \
  docker-compose \
  docker-machine \
  firefox-developer-edition \
  neovim \
  pigz # for docker

pamac build --no-confirm \
  brave-bin \
  jetbrains-toolbox \
  sublime-text-dev \
  vscodium-bin

sudo groupadd docker || true
sudo usermod -aG docker $USER
sudo systemctl enable docker
