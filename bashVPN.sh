#!/usr/bin/env bash

set -e

echo "=== Установка wg-easy (WireGuard VPN) ==="

read -p "Введите публичный IP-адрес вашего сервера: " SERVER_IP

if [[ -z "$SERVER_IP" ]]; then
  echo "Ошибка: IP-адрес не задан. Выход."
  exit 1
fi

echo "Установка Docker..."
curl -sSL https://get.docker.com | sh

echo "Добавляем пользователя $(whoami) в группу docker..."
sudo usermod -aG docker "$(whoami)"

echo "Установка завершена. Пожалуйста, выйдите из текущей сессии и войдите снова, или выполните команду: exec su - \$USER"
echo "После повторного входа запустите этот скрипт ещё раз, чтобы развернуть контейнер."
exit 0

# После повторного входа:
echo "Запускаем контейнер wg-easy..."
docker run -d \
  --name=wg-easy \
  -e WG_HOST="${SERVER_IP}" \
  -e PASSWORD="1234" \
  -e WG_DEFAULT_DNS="94.140.14.14" \
  -v ~/.wg-easy:/etc/wireguard \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  weejewel/wg-easy

echo
echo "Управление VPN-доступами"
echo "Вбиваем в строку браузера - http://${SERVER_IP}:51821"
echo "где ${SERVER_IP} — IP-адрес вашего сервера."

