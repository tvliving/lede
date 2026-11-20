#!/bin/bash
# 让 luci-app-quickstart 首页仪表盘真正生效（在 lede / openwrt 源码根目录执行）
#
# 官方包（kiddin9/op-packages）vendor 进来后有两个坑，导致「装了但刷进去看不到」：
#   1. entry 没有 title。dispatcher 访问 / 时走 firstchild，只在「有 title」的子节点里
#      按 order 挑最小者，所以 admin/quickstart 永远不会成为登录后的默认页。
#   2. 自带的 uci-defaults 只在 PKG_UPGRADE=1（升级安装）时才 enable/start 守护进程，
#      全新刷机不自启 —— controller 里 `pgrep quickstart` 失败就直接重定向回 admin/status，
#      仪表盘等于不存在。
#
# 用法：bash scripts/quickstart-fix.sh [源码根目录]
set -e
root="${1:-.}"
cd "$root"

CTRL=package/luci-app-quickstart/luasrc/controller/quickstart.lua
[ -f "$CTRL" ] || { echo "::error::未找到 $CTRL，请先把 luci-app-quickstart vendor 到 package/"; exit 1; }

echo "== quickstart 修复：默认首页 + 守护进程自启 =="

# 1) 给 admin/quickstart 补 title（Home）与 order=1，让它成为登录后的默认首页
if ! grep -q 'template("quickstart/home"), _("Home"), 1' "$CTRL"; then
  sed -i 's|entry({"admin", "quickstart"}, template("quickstart/home")).leaf = true|entry({"admin", "quickstart"}, template("quickstart/home"), _("Home"), 1).leaf = true|' "$CTRL"
fi
grep -q 'template("quickstart/home"), _("Home"), 1' "$CTRL" \
  || { echo "::error::未能给 quickstart 菜单项补上 title/order"; exit 1; }

# 2) 补一个 uci-defaults，保证全新刷机也开机自启守护进程
DEF=package/luci-app-quickstart/root/etc/uci-defaults/60-quickstart-enable
mkdir -p "$(dirname "$DEF")"
cat > "$DEF" <<'EOF'
#!/bin/sh
# quickstart 自带 defaults 仅在 PKG_UPGRADE=1 时 enable/start，全新刷机这里兜底
/etc/init.d/quickstart enable
/etc/init.d/quickstart start
exit 0
EOF
chmod 755 "$DEF"

# 3) .config 已存在时确保两个包被选中（不存在则由各 workflow 自己的配置段负责）
if [ -f .config ]; then
  for s in luci-app-quickstart quickstart; do
    grep -q "^CONFIG_PACKAGE_${s}=y$" .config || echo "CONFIG_PACKAGE_${s}=y" >> .config
  done
fi

echo "✔ 仪表盘已是默认首页，quickstart 守护进程开机自启"
