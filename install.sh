#!/bin/sh

# 确保以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用 root 权限运行此脚本 (sudo sh install.sh)"
    exit 1
fi

echo "========================================="
echo "       AnyTLS 自动化安装脚本"
echo "========================================="

# 1. 判断 VPS 系统类型 (Debian / Alpine)
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
        echo "错误：暂不支持的系统类型: $OS_NAME (仅支持 debian 和 alpine)"
        exit 1
        ;;
esac

# 2. 判断系统架构
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

# 3. 安装依赖工具 (curl, unzip)
echo "正在检查并安装必要依赖 (curl, unzip)..."
if [ "$OS_TYPE" = "debian" ]; then
    apt-get update -y && apt-get install -y curl unzip
elif [ "$OS_TYPE" = "alpine" ]; then
    apk update && apk add curl unzip
fi

# 4. 引导用户输入端口和密码
echo ""
read -p "请输入 AnyTLS 监听端口 (默认 443): " ANYTLS_PORT
ANYTLS_PORT=${ANYTLS_PORT:-443}

read -p "请输入 AnyTLS 连接密码: " ANYTLS_PASS
while [ -z "$ANYTLS_PASS" ]; do
    echo "密码不能为空！"
    read -p "请输入 AnyTLS 连接密码: " ANYTLS_PASS
done

# 5. 创建安装目录并下载解压
INSTALL_DIR="/usr/local/bin"
WORK_DIR="/etc/anytls"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

echo "正在从 GitHub 获取最新版 anytls-go 下载链接..."
# 获取最新版本的 zip 下载链接
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/anytls/anytls-go/releases/latest | grep "browser_download_url" | grep "linux" | grep "$ANYTLS_ARCH" | grep "\.zip" | head -n 1 | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "警告：未能自动获取最新版下载链接，尝试使用通用命名规则..."
    # 兜底方案（如果 API 获取失败，可根据实际 release 调整）
    DOWNLOAD_URL="https://github.com/anytls/anytls-go/releases/latest/download/anytls-server-linux-$ANYTLS_ARCH.zip"
fi

echo "正在下载：$DOWNLOAD_URL"
curl -L -o anytls.zip "$DOWNLOAD_URL"

if [ ! -f "anytls.zip" ]; then
    echo "错误：下载失败，请检查网络或 GitHub 连通性。"
    exit 1
fi

echo "正在解压..."
unzip -o anytls.zip
chmod +x anytls-server

# 移动到系统路径或保持在工作目录
# 这里我们假设解压出来的可执行文件名叫 anytls-server，如果名称不同请按实际调整

# 6. 后台运行测试
echo "正在启动 AnyTLS 服务..."
nohup ./anytls-server -l 0.0.0.0:"$ANYTLS_PORT" -p "$ANYTLS_PASS" > /dev/null 2>&1 &
nohup ./anytls-server -l 0.0.0.0:"$ANYTLS_PORT" -p "$ANYTLS_PASS" &

# 7. 根据系统类型自动生成开机自启服务
if [ "$OS_TYPE" = "debian" ]; then
    # Debian 使用 systemd
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
    echo "Debian 自启配置完成 (systemd)。"

elif [ "$OS_TYPE" = "alpine" ]; then
    # Alpine 使用 OpenRC
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
    echo "Alpine 自启配置完成 (OpenRC)。"
fi

echo "========================================="
echo "       AnyTLS 安装与配置成功！"
echo "========================================="
echo "安装目录: $WORK_DIR"
echo "监听端口: $ANYTLS_PORT"
echo "连接密码: $ANYTLS_PASS"
echo "服务状态已设为开机自启。"
echo "========================================="