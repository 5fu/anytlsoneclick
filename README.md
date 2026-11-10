
# AnyTLS 一键安装与卸载脚本

支持 **Debian** 和 **Alpine** 系统，自动判断架构（`amd64` / `arm64`），一键配置后台运行、开机自启并生成客户端连接链接与二维码。

---

## 📥 安装命令

在 VPS 终端中以 `root` 权限执行以下一键安装脚本：


sh -c "$(curl -fsSL [https://raw.githubusercontent.com/5fu/anytlsoneclick/main/install.sh](https://raw.githubusercontent.com/5fu/anytlsoneclick/main/install.sh))"

卸载与清理指南
如果你想将 AnyTLS 服务、下载的二进制文件、配置文件以及开机自启服务完全卸载干净，请根据你的 VPS 系统类型执行对应的清理命令：

第一步：停止并清理开机自启服务
如果是 Debian / Ubuntu 系统：
systemctl stop anytls
systemctl disable anytls
rm -f /etc/systemd/system/anytls.service
systemctl daemon-reload
如果是 Alpine 系统：
service anytls stop
rc-update del anytls default
rm -f /etc/init.d/anytls
第二步：清理残留的进程（防止后台有孤儿进程在跑）
killall anytls-server
第三步：删除程序文件及工作目录
直接将安装时创建的目录和压缩包全部删掉：
rm -rf /etc/anytls
(注：如果你曾经把 anytls-server 软链接到了 /usr/local/bin 等目录，也可以顺便执行 rm -f /usr/local/bin/anytls-server 彻底清理干净。)
