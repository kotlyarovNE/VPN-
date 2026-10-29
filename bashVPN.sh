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


docker run -d \
  --name=wg-easy \
  -e WG_HOST="ТВОЙ АЙПИ" \
  -e PORT=51821 \
  -e HOST=0.0.0.0 \
  -e INSECURE=true \
  -v ~/.wg-easy:/etc/wireguard \
  -v /lib/modules:/lib/modules \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.ip_forward=1" \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy:15

  _______________________


  #!/bin/bash

# Останавливаем скрипт при любой ошибке
set -e

echo "======================================================"
echo "🚀 Начинаем установку и настройку Tailscale..."
echo "======================================================"

# 1. Установка Tailscale
echo "⏳ [1/4] Установка Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# 2. Включение IP-форвардинга (IPv4 и IPv6)
echo "⏳ [2/4] Настройка форвардинга пакетов (IP Forwarding)..."
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf > /dev/null

# 3. Авторизация в сети Tailscale
echo "⏳ [3/4] Авторизация Tailscale..."
echo "⚠️  ВАЖНО: Сейчас появится ссылка. Скопируйте её, откройте в браузере и войдите в свой аккаунт (tablovo@gmail.com)."
echo "Скрипт будет ждать, пока вы не завершите авторизацию..."
tailscale up

# 4. Объявление сервера как Exit Node
echo "⏳ [4/4] Включение режима Exit Node..."
tailscale set --advertise-exit-node

echo "======================================================"
echo "✅ ВСЁ ГОТОВО!"
echo "======================================================"
echo "Не забудьте зайти в веб-панель Tailscale (https://login.tailscale.com/admin/machines),"
echo "нажать на меню (три точки) возле сервера, выбрать 'Edit route settings...'"
echo "и поставить галочку 'Use as exit node'."
