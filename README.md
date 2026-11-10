
# AnyTLS 一键安装与卸载脚本

支持 **Debian** 和 **Alpine** 系统，自动判断架构（`amd64` / `arm64`），一键配置后台运行、开机自启并生成客户端连接链接与二维码。

安装
在 VPS 终端中以 `root` 权限执行以下一键安装脚本：


sh -c "$(curl -fsSL [https://raw.githubusercontent.com/5fu/anytlsoneclick/main/install.sh](https://raw.githubusercontent.com/5fu/anytlsoneclick/main/install.sh))"

卸载
在 VPS 终端中以 `root` 权限执行以下一键安装脚本：


sh -c "$(curl -fsSL https://raw.githubusercontent.com/5fu/anytlsoneclick/main/uninstall.sh)"
