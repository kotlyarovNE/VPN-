#!/usr/bin/env bash
set -e

echo "=============================================="
echo "  Установка 3X-UI (VLESS + Reality)"
echo "  Аналог wg-easy, но не блокируется DPI/ТСПУ"
echo "=============================================="
echo

# ─── Проверка root ───
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Запустите скрипт от root: sudo bash install-3xui.sh"
  exit 1
fi

# ─── Определяем IP сервера ───
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip)
if [[ -z "$SERVER_IP" ]]; then
  read -p "Не удалось определить IP. Введите IP сервера вручную: " SERVER_IP
fi
echo "IP сервера: ${SERVER_IP}"
echo

# ─── Порт для панели (чтобы не конфликтовать с wg-easy) ───
PANEL_PORT=2053

# ─── Установка Docker (если ещё нет) ───
if ! command -v docker &>/dev/null; then
  echo "=== Устанавливаю Docker... ==="
  curl -sSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
  echo "✅ Docker установлен"
else
  echo "✅ Docker уже установлен"
fi
echo

# ─── Создаём директории ───
mkdir -p /root/3x-ui/db
mkdir -p /root/3x-ui/cert

# ─── Запуск 3X-UI в Docker ───
echo "=== Запускаю 3X-UI... ==="

# Останавливаем старый контейнер, если есть
docker stop 3x-ui 2>/dev/null || true
docker rm 3x-ui 2>/dev/null || true

docker run -itd \
  -e XRAY_VMESS_AEAD_FORCED=false \
  -v /root/3x-ui/db/:/etc/x-ui/ \
  -v /root/3x-ui/cert/:/root/cert/ \
  --network=host \
  --restart=unless-stopped \
  --name 3x-ui \
  ghcr.io/mhsanaei/3x-ui:latest

echo
echo "⏳ Жду запуска панели (15 сек)..."
sleep 15

# ─── Проверяем, что контейнер работает ───
if docker ps | grep -q 3x-ui; then
  echo "✅ 3X-UI запущен!"
else
  echo "❌ Ошибка запуска. Проверьте: docker logs 3x-ui"
  exit 1
fi

# ─── Открываем порты (если ufw активен) ───
if command -v ufw &>/dev/null && ufw status | grep -q "active"; then
  echo "=== Открываю порты в UFW... ==="
  ufw allow ${PANEL_PORT}/tcp comment "3X-UI Panel"
  ufw allow 443/tcp comment "VLESS Reality"
  echo "✅ Порты открыты"
fi

echo
echo "=============================================="
echo "  ✅ 3X-UI УСТАНОВЛЕН!"
echo "=============================================="
echo
echo "📋 ШАГ 1 — Войдите в панель:"
echo "   Откройте в браузере: http://${SERVER_IP}:${PANEL_PORT}"
echo "   Логин:  admin"
echo "   Пароль: admin"
echo "   ⚠️  СРАЗУ СМЕНИТЕ ПАРОЛЬ в настройках панели!"
echo
echo "📋 ШАГ 2 — Создайте подключение VLESS+Reality:"
echo "   1. Перейдите в «Inbounds» (Подключения)"
echo "   2. Нажмите «Add Inbound» (Добавить подключение)"
echo "   3. Заполните:"
echo "      - Remark (Имя):     любое, например «mama-vpn»"
echo "      - Protocol:         vless"
echo "      - Port:             443"
echo "      - Client → Email:   mama (или любое имя)"
echo "      - Client → Flow:    xtls-rprx-vision"
echo "   4. Внизу в Security выберите: reality"
echo "      - uTLS:   chrome"
echo "      - Dest:   dl.google.com:443"
echo "      - SNI:    dl.google.com"
echo "   5. Нажмите «Get New Cert» (генерация ключей)"
echo "   6. Включите Sniffing"
echo "   7. Нажмите «Create»"
echo
echo "📋 ШАГ 3 — Получите QR-код для мамы:"
echo "   1. В списке подключений нажмите «+» рядом с созданным"
echo "   2. Нажмите иконку QR-кода рядом с клиентом"
echo "   3. Покажите QR-код маме — она сканирует его в приложении"
echo
echo "📱 ШАГ 4 — Приложение для планшета мамы:"
echo "   Android:  Hiddify (Google Play) или v2rayNG"
echo "   iPad:     Streisand (App Store) или V2Box"
echo "   В приложении: «+» → «Сканировать QR-код» → готово!"
echo
echo "💡 WireGuard (wg-easy) остаётся работать параллельно."
echo "   VLESS — для WiFi из РФ (обходит DPI)."
echo "   WireGuard — для мобильного интернета (там не блокируют)."
echo
echo "=============================================="