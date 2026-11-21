#!/bin/bash
# 主题换 vantage + 去 argon + iStore + 中文包（在源码根目录执行）
set -e
cd "${1:-.}"

echo "== 1/6 移除 argon =="
rm -rf feeds/luci/themes/luci-theme-argon feeds/luci/applications/luci-app-argon-config \
       package/luci-theme-argon package/luci-app-argon-config

echo "== 2/6 引入 luci-theme-vantage =="
if [ ! -d package/luci-theme-vantage ]; then
  git clone --depth 1 https://github.com/anothaDev/luci-theme-vantage package/luci-theme-vantage
fi

echo "== 3/6 引入 iStore feed =="
grep -q '^src-git istore ' feeds.conf.default || \
  echo 'src-git istore https://github.com/linkease/istore.git' >> feeds.conf.default
./scripts/feeds update -a
./scripts/feeds install -a -p istore || true
./scripts/feeds install -a

echo "== 4/6 默认主题替换 =="
for f in feeds/luci/collections/luci/Makefile feeds/luci/collections/luci-light/Makefile; do
  [ -f "$f" ] && sed -i 's/luci-theme-argon/luci-theme-vantage/g; s/luci-theme-bootstrap/luci-theme-vantage/g' "$f" || true
done
# 打开 luci-i18n-*-zh-cn 生成（部分树把该 foreach 注释掉了）
if [ -f feeds/luci/luci.mk ]; then
  sed -i 's/^# \$(foreach lang,\$(LUCI_LANGUAGES)/$(foreach lang,$(LUCI_LANGUAGES)/' feeds/luci/luci.mk || true
fi

echo "== 5/6 写入配置与默认主题 =="
cat >> .config <<'EOF'
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-theme-vantage=y
CONFIG_PACKAGE_luci-theme-bootstrap=n
CONFIG_PACKAGE_luci-theme-argon=n
CONFIG_PACKAGE_luci-app-argon-config=n
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-lib-taskd=y
CONFIG_PACKAGE_luci-lib-xterm=y
CONFIG_PACKAGE_taskd=y
CONFIG_PACKAGE_libuci-lua=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_tar=y
CONFIG_PACKAGE_mount-utils=y
CONFIG_PACKAGE_xz-utils=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
EOF
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-default-theme <<'EOF'
#!/bin/sh
# 首启默认值：主题 vantage、界面语言简体中文、iStore 依赖的 taskd 自启
uci -q batch <<-EOT
	set luci.main.mediaurlbase='/luci-static/vantage'
	set luci.main.lang='zh_cn'
	commit luci
EOT
[ -x /etc/init.d/taskd ] && { /etc/init.d/taskd enable; /etc/init.d/taskd start; }
exit 0
EOF
chmod +x files/etc/uci-defaults/99-default-theme

echo "== 6/6 首页仪表盘（quickstart） =="
# vendor 两件套（LuCI 前端 + 守护进程），再补官方包缺的两处：默认首页 title/order 与开机自启
if [ ! -f package/luci-app-quickstart/Makefile ] || [ ! -f package/quickstart/Makefile ]; then
  tmp="$(mktemp -d)"
  git clone -q --depth 1 --filter=blob:none --sparse \
    https://github.com/kiddin9/op-packages.git "$tmp/repo"
  git -C "$tmp/repo" sparse-checkout set luci-app-quickstart quickstart
  for p in luci-app-quickstart quickstart; do
    rm -rf "package/feeds/istore/$p" "package/feeds/luci/$p" "package/$p"
    cp -a "$tmp/repo/$p" "package/$p"
  done
  rm -rf "$tmp"
fi
bash "$(dirname "$0")/quickstart-fix.sh" .

echo "[done] customize"
