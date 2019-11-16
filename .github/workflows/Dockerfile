FROM zalox/manjaro

RUN set -xe \
 && pacman --noconfirm --noprogressbar -Syyu \
 && pacman --noconfirm --noprogressbar -Syyu \
 && pacman --noconfirm --noprogressbar -S pamac sudo \
 && useradd --create-home --password=foo mykiwi

WORKDIR /home/mykiwi
USER mykiwi
