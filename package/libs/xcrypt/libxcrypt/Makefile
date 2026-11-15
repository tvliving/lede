include $(TOPDIR)/rules.mk
include ../libxcrypt-common.mk

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/libxcrypt
$(Package/libxcrypt/Default)
  BUILDONLY:=1
endef

define Package/libxcrypt/description
  libxcrypt is a modern library for one-way hashing of passwords. It supports
  a wide variety of both modern and historical hashing methods: yescrypt,
  gost-yescrypt, scrypt, bcrypt, sha512crypt, sha256crypt, md5crypt, SunMD5,
  sha1crypt, NT, bsdicrypt, bigcrypt, and descrypt. It provides the traditional
  Unix crypt and crypt_r interfaces, as well as a set of extended interfaces
  pioneered by Openwall Linux, crypt_rn, crypt_ra, crypt_gensalt,
  crypt_gensalt_rn, and crypt_gensalt_ra.
endef

CONFIGURE_ARGS += \
	--with-pic \
	--enable-year2038 \
	--disable-xcrypt-compat-files \
	--disable-shared \
	--disable-failure-tokens \
	--disable-obsolete-api \
	--enable-hashes=solaris \
	--disable-werror

# libxcrypt 的 configure 默认 warnings_are_errors=true（即自动加 -Werror）。
# 它的 lib/gen-des-tables.c 用非字面量 format 调 snprintf/sprintf，而 musl 的
# fortify/stdio.h 在这种情况下会触发：
#   error: format not a string literal, argument types not checked
#          [-Werror=format-nonliteral]
# 结果 lib/gen-des-tables.o 编译失败，整包 Error 2。
# 这里显式 --disable-werror 关掉上游的 -Werror（GCC 13 起 fortify 更严格，
# 这个报错是必现的）。

# libxcrypt 的 configure 会用 perl 跑 build-aux/scripts/expand-selected-hashes，
# 该脚本开头是 `use open qw(:std :utf8);`，需要 perl 核心模块 open.pm。
# 构建树里一旦装过精简版 host perl（staging_dir/host/bin/perl，PATH 优先级高于
# /usr/bin），configure 就会挑到它，于是报：
#   Can't locate open.pm in @INC ... at build-aux/scripts/expand-selected-hashes line 20
#   configure: error: bad value 'solaris' for --enable-hashes
# 这里直接把 configure 的 PERL 缓存变量钉到系统 perl（模块完整）。
HOST_PERL:=$(shell command -v /usr/bin/perl 2>/dev/null || command -v perl 2>/dev/null)
CONFIGURE_ARGS += $(if $(HOST_PERL),ac_cv_path_PERL=$(HOST_PERL))

define Package/libxcrypt/install
	true
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/*.h $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib/libxcrypt
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libcrypt.{a,la} $(1)/usr/lib/libxcrypt
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libxcrypt.pc $(1)/usr/lib/pkgconfig/
endef

$(eval $(call BuildPackage,libxcrypt))
