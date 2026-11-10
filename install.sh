#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用 root 权限运行此脚本 (sudo sh install.sh)"
    exit 1
fi

echo "========================================="
echo "        AnyTLS 自动化安装脚本"
echo "========================================="

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
elif [ -f /etc/alpine-release ]; then
    OS_NAME="alpine"
elif [ -f /etc/debian_version ]; then
    OS_NAME="debian"
else
    echo "错误：无法识别当前的系统类型，仅支持 Debian 和 Alpine。"
    exit 1
fi

case "$OS_NAME" in
    debian*|ubuntu*)
        OS_TYPE="debian"
        echo "检测到系统为：Debian/Ubuntu 系列"
        ;;
    alpine*)
        OS_TYPE="alpine"
        echo "检测到系统为：Alpine Linux"
        ;;
    *)
        echo "错误：暂不支持的系统类型: $OS_NAME"
        exit 1
        ;;
esac

ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        ANYTLS_ARCH="amd64"
        ;;
    aarch64|arm64)
        ANYTLS_ARCH="arm64"
        ;;
    *)
        echo "错误：不支持的架构: $ARCH"
        exit 1
        ;;
esac

echo "正在检查并安装必要依赖 (curl, unzip)..."
if [ "$OS_TYPE" = "debian" ]; then
    apt-get update -y && apt-get install -y curl unzip
elif [ "$OS_TYPE" = "alpine" ]; then
    apk update && apk add curl unzip
fi

echo "正在获取服务器 IP 地址..."
SERVER_IP=$(curl -s4 icanhazip.com || curl -s6 icanhazip.com)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="127.0.0.1"
fi

echo ""
read -p "请输入 AnyTLS 监听端口 (默认 443): " ANYTLS_PORT
ANYTLS_PORT=${ANYTLS_PORT:-443}

read -p "请输入 AnyTLS 连接密码: " ANYTLS_PASS
while [ -z "$ANYTLS_PASS" ]; do
    echo "密码不能为空！"
    read -p "请输入 AnyTLS 连接密码: " ANYTLS_PASS
done

DEFAULT_NAME="${SERVER_IP}-anytls"
read -p "请输入节点显示名称 (默认 $DEFAULT_NAME): " ANYTLS_NAME
ANYTLS_NAME=${ANYTLS_NAME:-$DEFAULT_NAME}

WORK_DIR="/etc/anytls"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

echo "正在从 GitHub 获取最新版 anytls-go 下载链接..."
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/anytls/anytls-go/releases/latest | grep "browser_download_url" | grep "linux" | grep "$ANYTLS_ARCH" | grep "\.zip" | head -n 1 | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    DOWNLOAD_URL="https://github.com/anytls/anytls-go/releases/latest/download/anytls-server-linux-$ANYTLS_ARCH.zip"
fi

echo "正在下载：$DOWNLOAD_URL"
curl -L -o anytls.zip "$DOWNLOAD_URL"

if [ ! -f "anytls.zip" ]; then
    echo "错误：下载失败，请检查网络。"
    exit 1
fi

echo "正在解压..."
unzip -o anytls.zip
chmod +x anytls-server

echo "正在启动 AnyTLS 服务..."
nohup ./anytls-server -l 0.0.0.0:"$ANYTLS_PORT" -p "$ANYTLS_PASS" > /dev/null 2>&1 &

if [ "$OS_TYPE" = "debian" ]; then
    SERVICE_FILE="/etc/systemd/system/anytls.service"
    echo "正在配置 systemd 开机自启服务..."
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=AnyTLS Server
After=network.target

[Service]
Type=simple
WorkingDirectory=$WORK_DIR
ExecStart=$WORK_DIR/anytls-server -l 0.0.0.0:$ANYTLS_PORT -p $ANYTLS_PASS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable anytls
    systemctl restart anytls

elif [ "$OS_TYPE" = "alpine" ]; then
    INIT_FILE="/etc/init.d/anytls"
    echo "正在配置 OpenRC 开机自启服务..."
    cat << EOF > "$INIT_FILE"
#!/sbin/openrc-run

name="anytls"
description="AnyTLS Server"
command="$WORK_DIR/anytls-server"
command_args="-l 0.0.0.0:$ANYTLS_PORT -p $ANYTLS_PASS"
command_background="yes"
pidfile="/var/run/anytls.pid"

depend() {
    need net
}
EOF

    chmod +x "$INIT_FILE"
    rc-update add anytls default
    service anytls restart
fi

ENCODED_NAME=$(echo "$ANYTLS_NAME" | sed 's/ /%20/g')
# 确保这里正确拼接了 allowInsecure=true
ANYTLS_LINK="anytls://$ANYTLS_PASS@$SERVER_IP:$ANYTLS_PORT?allowInsecure=true#$ENCODED_NAME"

echo ""
echo "========================================="
echo "        AnyTLS 安装与配置成功！"
echo "========================================="
echo "监听端口 : $ANYTLS_PORT"
echo "连接密码 : $ANYTLS_PASS"
echo "节点名称 : $ANYTLS_NAME"
echo "跳过证书 : true (允许自签/不安全证书)"
echo "-----------------------------------------"
echo "【AnyTLS 客户端连接链接】:"
echo "$ANYTLS_LINK"
echo "-----------------------------------------"
echo "【手机扫码二维码 (网页直链)】:"
echo "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$(echo "$ANYTLS_LINK" | sed 's/:/%3A/g;s/\//%2F/g;s/@/%40/g;s/#/%23/g;s/\?/%3F/g;s/=/./g;s/&/%26/g')"
echo "========================================="
