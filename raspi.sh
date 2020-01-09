#!/bin/bash

# Copyright (C) 2020 by Jonas Moehle <ad-min@mailbox.org>
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

COMPOSE_VERSION="1.25.0"
COMPOSE_PATH="/usr/local/bin"
#CERTBOT_PATH="/tmp/nginx_certbot"
#USER=archfan
#export domains=""
#export email=""
domain="0x61.xyz"

distro=`awk -F= '/^NAME/{print $2}' /etc/os-release | sed 's/\"//g'` # 2. Spalte / sed ersetzt die Anfuehrungszeichen
if [ "$distro" != "Ubuntu" ]; then
 echo "Dieses Script funktioniert derzeit nur mit Ubuntu. $distro wird nicht unterstuetzt."
 exit 42;
fi

if [ "$EUID" -ne 0 ]; then # id -u
 echo "Dieses Script benoetigt Root-Rechte."
 exit 43;
fi

case $(uname -m) in
x86_64)
    ARCH=amd64
    ;;
armv7l)
    ARCH=armhf
    ;;
aarch64)
    ARCH=arm64
    ;;
esac

if [ ! -x "$(command -v docker)" ]; then
 echo "Docker wird installiert."
 sleep 1
 apt update && apt install -y apt-transport-https ca-certificates curl software-properties-common
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

 sudo add-apt-repository \
   "deb [arch=$ARCH] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

 apt update && apt install -y docker-ce docker-ce-cli containerd.io
fi


if [[ ! -f $COMPOSE_PATH/docker-compose && "$ARCH" =~ ^('amd64|armhf')$ ]]; then
 echo "Docker Compose fuer $ARCH wird installiert."
 curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o $COMPOSE_PATH/docker-compose
 chmod +x $COMPOSE_PATH/docker-compose
elif [[ ! -x "$(command -v docker-compose)" && "$ARCH" = "arm64" ]]; then
 echo "Docker Compose fuer $ARCH wird installiert."
 apt update && apt install -y make libc-dev gcc libssl-dev libffi-dev python3-dev python3-pip
 pip3 install docker-compose
fi

# docker nginx stuerzt aus bisher unerklaerlichen Gruenden ab
#if ! [ -d $CERTBOT_PATH ]; then
#git clone https://github.com/archfan/nginx-certbot.git $CERTBOT_PATH && cd $CERTBOT_PATH
#source ./init-letsencrypt.sh
#fi

if [ ! -x "$(command -v nginx)" ]; then
echo "nginx und certbot werden installiert."
add-apt-repository universe
add-apt-repository ppa:certbot/certbot
apt update && apt install -y nginx certbot python-certbot-nginx
mkdir -p /var/www/$domain

rm -f /etc/nginx/sites-enabled/default
cp -v conf/*.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/*.conf /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
fi
