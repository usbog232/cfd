#!/bin/bash

echo "🚨 即将删除所有 cloudflared tunnel、凭证与配置！"

# 确认 cloudflared 是否存在
if ! command -v cloudflared &> /dev/null; then
    echo "❌ cloudflared 未安装，跳过..."
    exit 1
fi

echo "🔍 获取现有 tunnel 列表..."
cloudflared tunnel list --output json > /tmp/tunnel_list.json

tunnel_ids=$(jq -r '.[].id' /tmp/tunnel_list.json)
tunnel_names=$(jq -r '.[].name' /tmp/tunnel_list.json)

for id in $tunnel_ids; do
    echo "🧹 删除 Tunnel ID: $id"
    cloudflared tunnel delete "$id"
done

# 删除本地凭证和配置
echo "🗑️ 删除本地配置与凭证文件..."
rm -rf /root/.cloudflared
rm -rf /etc/cloudflared
rm -rf /root/cloudflared

# 停止并禁用 systemd 服务
echo "🛑 停止并禁用 systemd 服务..."
systemctl stop cloudflared 2>/dev/null
systemctl disable cloudflared 2>/dev/null

echo "✅ 所有清理完成！现在可以重新登录 Cloudflare 帐号了"
