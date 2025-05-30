#!/bin/bash

set -e

echo "🚀 开始部署 Cloudflare Tunnel（Docker 版本）"

if ! command -v docker &> /dev/null; then
    echo "🔧 未检测到 Docker，正在安装..."
    curl -fsSL https://get.docker.com | bash
else
    echo "✅ Docker 已安装"
fi

read -p "请输入 Cloudflare Tunnel 名称（如：mytunnel）: " TUNNEL_NAME
read -p "请输入认证 JSON 文件路径（如：/root/cloudflared/xxx.json）: " CRED_JSON
read -p "容器名称（默认 cloudflared）: " CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-cloudflared}

CONFIG_FILE="/root/cloudflared/config.yml"

mkdir -p $(dirname "$CRED_JSON")
mkdir -p $(dirname "$CONFIG_FILE")

# 自动生成 config.yml
cat <<EOF > $CONFIG_FILE
tunnel: $TUNNEL_NAME
credentials-file: /etc/cloudflared/$(basename $CRED_JSON)

ingress:
  - hostname: n8n111.jdssl112.sbs
    service: http://192.168.123.203:5678

  - hostname: nas1111.jdssl112.sbs
    service: https://192.168.123.50:5001
    originRequest:
      noTLSVerify: true

  - hostname: ope222.jdssl112.sbs
    service: http://192.168.123.3:80

  - hostname: jellyfin111.jdssl112.sbs
    service: http://192.168.123.50:8096

  - service: http_status:404
EOF

docker rm -f $CONTAINER_NAME >/dev/null 2>&1 || true

docker run -d \
  --name $CONTAINER_NAME \
  --restart always \
  -v "$CRED_JSON":/etc/cloudflared/$(basename $CRED_JSON) \
  -v "$CONFIG_FILE":/etc/cloudflared/config.yml \
  cloudflare/cloudflared:latest tunnel \
  --no-autoupdate \
  --config /etc/cloudflared/config.yml \
  run

echo "✅ Cloudflare Tunnel 容器已启动：$CONTAINER_NAME"
echo "📄 config.yml 配置文件路径：$CONFIG_FILE"
echo "📄 credentials-file 路径：$CRED_JSON"
