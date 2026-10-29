include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-dashboard
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT

LUCI_TITLE:=System Dashboard for LuCI
# +luci-compat 提供 Lua 控制器/模板运行环境（本包 controller 与 view 均为 Lua 实现）
LUCI_DEPENDS:=+luci-base +luci-mod-status +luci-compat
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))

