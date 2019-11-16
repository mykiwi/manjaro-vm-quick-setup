FROM zalox/manjaro

RUN set -xe \
 && pacman --noconfirm --noprogressbar -Syyu \
 && pacman --noconfirm --noprogressbar -Syyu \
 && pacman --noconfirm --noprogressbar -S pamac sudo \
 && useradd --create-home --password=foo --groups=wheel mykiwi \
 && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /home/mykiwi
USER mykiwi
