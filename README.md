# cfd
## 🧹 一键删除所有 Cloudflare Tunnel 脚本
##一键清理删除
```bash
bash <(curl -s https://raw.githubusercontent.com/usbog232/cfd/main/delete_all_cloudflare_tunnel.sh)

##
## docker版本一键安装


bash <(curl -fsSL https://raw.githubusercontent.com/usbog232/cfd/refs/heads/main/install_cloudflared.sh)

## 🧹 卸载

docker rm -f cloudflared
rm -rf /etc/cloudflared/
