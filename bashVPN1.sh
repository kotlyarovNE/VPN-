#!/usr/bin/env bash

set -e

echo "=== Установка WireGuard (wg-easy в Docker) ==="

# Спрашиваем IP сервера
read -p "Введите публичный IP-адрес вашего сервера: " SERVER_IP

if [[ -z "$SERVER_IP" ]]; then
  echo "Ошибка: IP-адрес не задан. Выход."
  exit 1
fi

echo
echo "IP сервера: ${SERVER_IP}"
echo

# Установка Docker
echo "=== Устанавливаю Docker... ==="
curl -sSL https://get.docker.com | sh

# Добавление пользователя в группу docker
echo "=== Добавляю пользователя $(whoami) в группу docker... ==="
sudo usermod -aG docker "$(whoami)"

echo
echo "Внимание!"
echo "Чтобы права группы docker применились, нужно выйти из системы и зайти снова."
echo "НО я попробую запустить контейнер через sudo docker, чтобы не ждать повторного входа."
echo

# Создаём директорию для конфигов wg-easy (если нет)
mkdir -p "${HOME}/.wg-easy"

echo "=== Запускаю контейнер wg-easy... ==="

sudo docker run -d \
  --name=wg-easy \
  -e WG_HOST="${SERVER_IP}" \
  -e PASSWORD="1234" \
  -e WG_DEFAULT_DNS="94.140.14.14" \
  -v "${HOME}/.wg-easy:/etc/wireguard" \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  weejewel/wg-easy

echo
echo "=== Готово! ==="
echo
echo "Управление VPN доступами"
echo
echo "Вбиваем в строку браузера -  ${SERVER_IP}:51821"
echo "где ${SERVER_IP} — IP-адрес вашего сервера."
echo
echo "Если веб-панель не открывается, проверьте:"
echo " - Открыты ли порты 51820/udp и 51821/tcp в firewall/панели хостинга"
echo " - Статус контейнера: sudo docker ps -a | grep wg-easy"

