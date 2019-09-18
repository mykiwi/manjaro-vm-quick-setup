#!/bin/bash

sudo pacman -Syyu
sudo pacman -S gcc make linux$(uname -r|sed 's/\W//g'|cut -c1-2)-headers virtualbox-guest-iso
sudo mount -o loop /usr/lib/virtualbox/additions/VBoxGuestAdditions.iso /mnt
sudo /mnt/VBoxLinuxAdditions.run
