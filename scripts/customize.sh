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
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_uhttpd=y
CONFIG_PACKAGE_uhttpd-mod-ubus=y
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

echo "== 5.5/6 追加机型附加包（packages.txt 单点维护） =="
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKGLIST="$HERE/devices-pack/ew6000gxpro/packages.txt"
if [ -f "$PKGLIST" ]; then
  n=0
  while IFS= read -r pkg || [ -n "$pkg" ]; do
    pkg="$(printf '%s' "$pkg" | tr -d '\r' | sed 's/[[:space:]]*$//')"
    case "$pkg" in ''|'#'*) continue ;; esac
    echo "CONFIG_PACKAGE_${pkg}=y" >> .config
    n=$((n + 1))
  done < "$PKGLIST"
  echo "[info] 附加包 $n 个（$PKGLIST）"
else
  echo "::warning::未找到 $PKGLIST，跳过附加包"
fi
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-default-theme <<'EOF'
#!/bin/sh
# 首启默认值：主题 vantage、界面语言简体中文、iStore 依赖的 taskd 自启
# hostname 也要改：vantage 登录页的大标题直接显示 hostname，不改就还是默认值
uci -q batch <<-EOT
	set luci.main.mediaurlbase='/luci-static/vantage'
	set luci.main.lang='zh_cn'
	commit luci
	set system.@system[0].hostname='Lede'
	commit system
EOT
[ -x /etc/init.d/taskd ] && { /etc/init.d/taskd enable; /etc/init.d/taskd start; }
# LuCI 的 web 入口与 rpcd 必须开机自启，否则刷完只有 ssh 能进
for s in uhttpd rpcd; do
	[ -x "/etc/init.d/$s" ] && { "/etc/init.d/$s" enable; "/etc/init.d/$s" restart 2>/dev/null || true; }
done
exit 0
EOF
chmod +x files/etc/uci-defaults/99-default-theme
cat > files/etc/uci-defaults/98-lan-ip <<'EOF'
#!/bin/sh
# 后台管理地址固定 192.168.110.1（board.d 生成的 lan 配置在这里改写，首启生效）
uci -q batch <<-EOT
	set network.lan.ipaddr='192.168.110.1'
	set network.lan.netmask='255.255.255.0'
	commit network
	set dhcp.lan.start='100'
	set dhcp.lan.limit='150'
	set dhcp.lan.leasetime='12h'
	commit dhcp
EOT
exit 0
EOF
chmod +x files/etc/uci-defaults/98-lan-ip

echo "== 6/6 后台首页 =="
# 曾经 vendor 过 kiddin9/op-packages 的 quickstart 当首页，实机验证不行：
# 它的 home.htm 是独立的单页壳子，前端要靠 /admin/quickstart/* 的 XHR 拉数据，
# 精简固件里后端守护进程拉不起来，XHR 一失败整页就只剩「正在加载首页...」，
# 连带侧边栏都没有（vantage 的 rail 由页面自身渲染）。
# 现在恢复标准 LuCI 布局：状态 -> 概览作为登录后首页，侧边栏和菜单都在。
# 需要 quickstart 时把下面 5 行取消注释即可（脚本已兼容 apk 版本号问题）。
# if [ ! -f package/luci-app-quickstart/Makefile ]; then
#   bash "$(dirname "$0")/vendor-quickstart.sh" .
# fi
# bash "$(dirname "$0")/quickstart-fix.sh" .
echo "[ok] 使用标准 LuCI 首页（状态-概览），不引入 quickstart"

echo "== 7/7 品牌 + 默认展开左侧导航 =="
# 7.1 品牌：把 VERSION_DIST 默认值固定成 Lede。它是 /etc/openwrt_release 的
#     DISTRIB_ID 来源，make defconfig 会把 .config 里的临时值重置回默认值。
if [ -f package/base-files/image-config.in ]; then
  sed -i 's/^\(\s*\)default "LEDE"$/\1default "Lede"/' package/base-files/image-config.in
  grep -q 'default "Lede"' package/base-files/image-config.in \
    && echo "[ok] VERSION_DIST 默认值 = Lede" \
    || echo "::warning::VERSION_DIST 默认值替换失败"
fi

# 7.2 vantage 左侧是图标栏（rail），默认收起、点「Expand navigation」才展开，
#     状态存在 localStorage 的 vantage.rail。这里把默认值改成展开（pinned）；
#     用户手动收起时写 'unpinned'，仍然用户偏好优先。
VUT=package/luci-theme-vantage/ucode/template/themes/vantage/header.ut
VMJ=package/luci-theme-vantage/htdocs/luci-static/resources/menu-vantage.js
python3 - "$VUT" "$VMJ" <<'PY'
import io
import sys

hut, mjs = sys.argv[1], sys.argv[2]


def patch(path, pairs):
    try:
        s = io.open(path, encoding="utf-8").read()
    except IOError:
        print("::warning::未找到 %s" % path)
        return
    hit = 0
    for a, b in pairs:
        if a in s:
            s = s.replace(a, b)
            hit += 1
    io.open(path, "w", encoding="utf-8", newline="\n").write(s)
    print("[ok] %s 替换 %d 处" % (path, hit))


patch(hut, [
    ("localStorage.getItem('vantage.rail') || ''",
     "localStorage.getItem('vantage.rail') || 'pinned'"),
    ("if (rail === 'pinned') r.setAttribute('data-rail', 'pinned');",
     "if (rail !== 'unpinned') r.setAttribute('data-rail', 'pinned');"),
])
patch(mjs, [
    ("storageSet(RAIL_KEY, pinned ? null : 'pinned');",
     "storageSet(RAIL_KEY, pinned ? 'unpinned' : 'pinned');"),
])
PY

# board.d 覆盖脚本需要可执行位（apply-pack 用 copyfile 复制，不带权限）
chmod 755 files/etc/board.d/* 2>/dev/null || true

# iStore 界面中文化（没有内置 iStore 的机型会自己跳过）
bash "$(dirname "$0")/fix-istore-lang.sh" . || true

echo "[done] customize"
