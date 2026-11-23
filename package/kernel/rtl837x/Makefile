include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=dsa-rtl837x
PKG_VERSION:=20260917
PKG_RELEASE:=1
PKG_MAINTAINER:=air jinkela (air_jinkela@163.com)
PKG_LICENSE:=GPL-2.0-only AND LicenseRef-Realtek-Proprietary
PKG_LICENSE_FILES:=LICENSE LICENSE.realtek

include $(INCLUDE_DIR)/package.mk

define KernelPackage/dsa-rtl837x
  SUBMENU:=Network Devices
  TITLE:=Realtek RTL8372N DSA switch driver
  KCONFIG:=CONFIG_NET_DSA_TAG_RTL837X_8021AD
  FILES:= \
	$(PKG_BUILD_DIR)/rtl837x_dsa.ko \
	$(LINUX_DIR)/net/dsa/tag_rtl837x_8021ad.ko
  AUTOLOAD:=$(call AutoLoad,99,rtl837x_dsa)
  # 本驱动依赖内核树内的 net/dsa/tag_rtl837x_8021ad（枚举 DSA_TAG_PROTO_RTL837X_8021AD）。
  # 该内核补丁不在 upstream，由本仓库按 target 各自携带（内容完全相同）：
  #   target/linux/qualcommbe/patches-6.18/0003-752-net-dsa-add-rtl837x-8021ad-tag-driver.patch
  #   target/linux/mediatek/patches-6.18/738-net-dsa-add-rtl837x-8021ad-tag-driver.patch
  # 缺了补丁的 target 编译必然报
  #   rtl837x_dsa_ops.c:607: error: 'DSA_TAG_PROTO_RTL837X_8021AD' undeclared
  # 使用方：
  #   target/linux/qualcommbe/image/ipq53xx.mk（GL-BE9300，IPQ5332）
  #   target/linux/mediatek/image/filogic.mk（TP-Link TL-7DR7299 v1，MT7988A）
  # 新增使用方前，先把上面的内核补丁复制到该 target 的 patches-<kver>/ 下。
  DEPENDS:=@(TARGET_qualcommbe||TARGET_mediatek) +kmod-dsa +kmod-regmap-core
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		CONFIG_RTL837X_DSA=m \
		modules
endef

$(eval $(call KernelPackage,dsa-rtl837x))
