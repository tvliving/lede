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
  # 本驱动依赖内核树内的 net/dsa/tag_rtl837x_8021ad（枚举 DSA_TAG_PROTO_RTL837X_8021AD），
  # 该内核补丁只在 target/linux/qualcommbe/patches-6.18/0003-752-net-dsa-add-rtl837x-8021ad-tag-driver.patch
  # 里提供。其它 target（如 mediatek/filogic）没有这个枚举，编译必然报
  #   rtl837x_dsa_ops.c:607: error: 'DSA_TAG_PROTO_RTL837X_8021AD' undeclared
  # 使用方：target/linux/qualcommbe/image/ipq53xx.mk（DEVICE_PACKAGES 里的 kmod-dsa-rtl837x）。
  #
  # 限定方式必须写在文件末尾的 KernelPackage 定义处（见该文件最后），不能只靠这里的
  # DEPENDS:=@TARGET_qualcommbe：本树的 kconfig（scripts/config/symbol.c 的 sym_calc_value）
  # 在依赖不满足时（dir_dep=no 且 rev_dep=no）走 EXPR_OR 分支、不会回落成 no，于是
  # package-metadata.pl 生成的 `default m if ALL||ALL_NONSHARED||ALL_KMODS`
  # 会照旧写进 .config。CONFIG_ALL_NONSHARED=y 的 CI 因此仍会
  # CONFIG_PACKAGE_kmod-dsa-rtl837x=m 并进入 world 编译（实测 514beb72 就死在这里）。
  DEPENDS:=@TARGET_qualcommbe +kmod-dsa +kmod-regmap-core
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		CONFIG_RTL837X_DSA=m \
		modules
endef

# 只在提供了 tag_rtl837x_8021ad 内核补丁的 target 下定义本包。定义层面剔除后该包不会出现在
# tmp/.config-package.in，CONFIG_ALL_NONSHARED 也就无从把它写进 .config，世界编译不会去编它。
ifneq ($(CONFIG_TARGET_qualcommbe),)
$(eval $(call KernelPackage,dsa-rtl837x))
endif
