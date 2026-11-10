#!/bin/sh

# 确保以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用 root 权限运行此脚本 (sudo sh uninstall.sh)"
    exit 1
fi

echo "========================================="
echo "       AnyTLS 卸载与清理工具"
echo "========================================="

# 1. 停止并删除自启服务
if [ -f /etc/systemd/system/anytls.service ]; then
    echo "检测到 systemd (Debian/Ubuntu)，正在清理..."
    systemctl stop anytls
    systemctl disable anytls
    rm -f /etc/systemd/system/anytls.service
    systemctl daemon-reload
elif [ -f /etc/init.d/anytls ]; then
    echo "检测到 OpenRC (Alpine)，正在清理..."
    service anytls stop
    rc-update del anytls default
    rm -f /etc/init.d/anytls
else
    echo "未检测到系统自启服务文件，跳过..."
fi

# 2. 终止残留进程
echo "正在清理残留进程..."
killall anytls-server 2>/dev/null

# 3. 删除程序文件及目录
echo "正在清理安装目录..."
rm -rf /etc/anytls
rm -f /usr/local/bin/anytls-server

echo "========================================="
echo "       AnyTLS 已成功完全卸载！"
echo "========================================="
