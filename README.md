
# AnyTLS 一键安装与卸载脚本

支持 **Debian** 和 **Alpine** 系统，自动判断架构（`amd64` / `arm64`），一键配置后台运行、开机自启并生成客户端连接链接与二维码。

安装
在 VPS 终端中以 `root` 权限执行以下一键安装脚本：

sh -c "$(curl -fsSL https://raw.githubusercontent.com/5fu/anytlsoneclick/main/install.sh | tr -d '\r')"
如果是 v2rayN / 类似客户端： 右键点击该节点选择 “编辑节点”（或查看 json 配置），找到 “跳过证书验证”（Allow Insecure）选项，将其从 false 手动勾选或改为 true，然后保存。
如果是 JSON 格式配置： 在该节点的 TLS 配置段（tls）中，把 allow_insecure 或 allowInsecure 这一行明确改为 true：


卸载
在 VPS 终端中以 `root` 权限执行以下一键安装脚本：


sh -c "$(curl -fsSL https://raw.githubusercontent.com/5fu/anytlsoneclick/main/uninstall.sh)"
