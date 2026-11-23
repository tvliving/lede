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
  # CONFIG_ALL_NONSHARED=y 的 CI 会把所有无 target 限定的内核模块一起编，故显式限定 target。
  # 使用方：target/linux/qualcommbe/image/ipq53xx.mk（DEVICE_PACKAGES 里的 kmod-dsa-rtl837x）。
  DEPENDS:=@TARGET_qualcommbe +kmod-dsa +kmod-regmap-core
endef

define Build/Compile
	+$(KERNEL_MAKE) $(PKG_JOBS) \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		CONFIG_RTL837X_DSA=m \
		modules
endef

$(eval $(call KernelPackage,dsa-rtl837x))
