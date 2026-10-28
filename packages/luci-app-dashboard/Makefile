include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-dashboard
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT

LUCI_TITLE:=System Dashboard for LuCI
LUCI_DEPENDS:=+luci-base +luci-mod-status
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))

