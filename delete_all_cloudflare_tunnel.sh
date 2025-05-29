#!/bin/bash

set -euo pipefail

echo "🚀 开始 Cloudflared 安装与配置..."

# ======= 用户自定义部分 ========
TUNNEL_NAME="myhome"                  # Tunnel 名称（不能和旧的重复）
DOMAIN="yourdomain.com"              # 替换为你的主域名
SUBDOMAIN="n8n"                      # 替换为你希望的子域名
SERVICE_URL="http://localhost:5678"  # 本地服务 URL
# =================================

CONFIG_DIR="/etc/cloudflared"
CLOUDFLARED_BIN="/usr/bin/cloudflared"
TUNNEL_ID_FILE="$HOME/.cloudflared/${TUNNEL_NAME}.json"

# Step 1: 清理旧配置
echo "🧹 正在清理旧配置..."
sudo systemctl stop cloudflared || true
sudo systemctl disable cloudflared || true
sudo rm -f /etc/systemd/system/cloudflared.service
sudo rm -rf /etc/cloudflared
sudo rm -rf ~/.cloudflared
sudo systemctl daemon-reload

# Step 2: 登录 Cloudflare
echo "🔐 登录 Cloudflare..."
$CLOUDFLARED_BIN tunnel login

# Step 3: 创建 Tunnel
echo "📦 创建新 Tunnel：$TUNNEL_NAME..."
$CLOUDFLARED_BIN tunnel create $TUNNEL_NAME

# Step 4: 获取 Tunnel ID 和凭证路径
TUNNEL_ID=$(grep -oE '[-a-f0-9]{36}' <<< $($CLOUDFLARED_BIN tunnel list | grep $TUNNEL_NAME))
CREDENTIALS_FILE="$HOME/.cloudflared/${TUNNEL_ID}.json"

# Step 5: 创建配置文件
echo "📝 写入 config.yml 配置..."
sudo mkdir -p $CONFIG_DIR
cat <<EOF | sudo tee $CONFIG_DIR/config.yml
tunnel: ${TUNNEL_ID}
credentials-file: ${CREDENTIALS_FILE}

ingress:
  - hostname: ${SUBDOMAIN}.${DOMAIN}
    service: ${SERVICE_URL}

  - service: http_status:404
EOF

# Step 6: 创建 DNS 记录
echo "🌐 配置 Cloudflare DNS 解析：${SUBDOMAIN}.${DOMAIN}"
$CLOUDFLARED_BIN tunnel route dns ${TUNNEL_NAME} ${SUBDOMAIN}.${DOMAIN}

# Step 7: 安装服务并设置开机启动
echo "🔧 安装并启用 systemd 服务..."
sudo $CLOUDFLARED_BIN --config $CONFIG_DIR/config.yml service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# Step 8: 状态检查
sleep 2
sudo systemctl status cloudflared --no-pager

echo "✅ 安装与配置完成！现在你可以访问：https://${SUBDOMAIN}.${DOMAIN}"
