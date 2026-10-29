#!/bin/bash
# ============================================================
# 360V6 (qihoo_360v6) OpenWRT NSS 固件 - 加固精简版 自定义编译脚本
# 源码: laipeng668/openwrt-6.x 25.12-nss 分支 (Linux 6.12 + 全功能 NSS)
# 核心: OpenClash + EasyTier 2.4.5 组网 + NSS ECM 硬件加速
# 加固: CPU 1.2GHz 锁频 / WPA2-PSK 纯协议 / 射频功率保护 / 防掉电
# ============================================================

set -e

echo "=== 开始加载自定义配置 ==="

# --- 1. 修改默认 IP 和主机名 ---
# 默认 IP 改为 192.168.50.1（与加固脚本一致）
sed -i 's/192.168.1.1/192.168.50.1/g' package/base-files/files/bin/config_generate
sed -i "s/hostname='.*'/hostname='Openwrt'/g" package/base-files/files/bin/config_generate
echo "默认 IP 已修改为 192.168.50.1"

# --- 2. 修改固件版本号 ---
date_version=$(date +"%y.%m.%d")
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
    if [ -n "$orig_version" ]; then
        sed -i "s/${orig_version}/R${date_version}/g" package/lean/default-settings/files/zzz-default-settings
        echo "版本号已修改为: R${date_version}"
    fi
fi

# --- 3. 移除不需要的 LuCI 应用源码 ---
# PassWall 全套（与 OpenClash 功能重复）
rm -rf feeds/luci/applications/luci-app-passwall 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-passwall2 2>/dev/null || true
rm -rf package/passwall-packages 2>/dev/null || true
rm -rf package/luci-app-passwall 2>/dev/null || true
rm -rf package/luci-app-passwall2 2>/dev/null || true

# 内网穿透
rm -rf feeds/luci/applications/luci-app-frpc 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-frps 2>/dev/null || true
rm -rf feeds/packages/net/frp 2>/dev/null || true

# 下载类（aria2/AriaNG/amule 已禁用）
rm -rf feeds/luci/applications/luci-app-aria2 2>/dev/null || true
rm -rf feeds/packages/net/ariang 2>/dev/null || true

# cpufreq（原仓库故意清理，加固脚本改用 sysfs 直接锁频）
rm -rf feeds/luci/applications/luci-app-cpufreq 2>/dev/null || true

# 其他不常用应用
rm -rf feeds/luci/applications/luci-app-wechatpush 2>/dev/null || true
rm -rf package/luci-app-wechatpush 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-appfilter 2>/dev/null || true
rm -rf feeds/packages/net/open-app-filter 2>/dev/null || true
rm -rf package/OpenAppFilter 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-diskman 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-hd-idle 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-wol 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-vlmcsd 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-autoreboot 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-wifischedule 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-banip 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-acme 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-arpbind 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-usb-printer 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-watchcat 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-smartdns 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-zerotier 2>/dev/null || true
rm -rf package/luci-app-lucky 2>/dev/null || true
rm -rf package/openlist2 2>/dev/null || true
rm -rf package/luci-app-gecoosac 2>/dev/null || true
rm -rf package/luci-app-athena-led 2>/dev/null || true

# --- 3.5 NSS 冲突清理 ---
# shortcut-fe 是软件快速路径，与高通 NSS ECM 硬件快速路径冲突，必须移除
# 覆盖常见的 3 个可能位置（不同 feed 源放置位置不同）
rm -rf feeds/kiddin9/shortcut-fe 2>/dev/null || true
rm -rf feeds/luci/applications/luci-app-shortcut-fe 2>/dev/null || true
rm -rf package/shortcut-fe 2>/dev/null || true
rm -rf package/luci-app-shortcut-fe 2>/dev/null || true
# wpad 切 mbedtls 版（体积更小，WPA2/WPA3 个人版均支持）
sed -i "s/wpad-openssl/wpad-mbedtls/g" target/linux/qualcommax/Makefile 2>/dev/null || true

# --- 4. 添加 EasyTier 2.4.5 feed 源 ---
# 锁定官方 v2.4.5 tag，确保版本稳定
grep -q "luci-app-easytier" feeds.conf.default 2>/dev/null || \
    echo "src-git easytier https://github.com/EasyTier/luci-app-easytier.git;v2.4.5" >> feeds.conf.default
echo "EasyTier v2.4.5 feed 已添加"

# --- 5. 克隆 Aurora 主题 ---
echo "=== 克隆 Aurora 主题 ==="
rm -rf feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora

# --- 6. 克隆最新 OpenClash ---
echo "=== 克隆最新 OpenClash ==="
rm -rf feeds/luci/applications/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# --- 6.5 集成自定义 LuCI 仪表盘 ---
echo "=== 集成自定义 LuCI 仪表盘 ==="
rm -rf package/luci-app-dashboard
cp -r $GITHUB_WORKSPACE/packages/luci-app-dashboard package/luci-app-dashboard
chmod +x package/luci-app-dashboard/files/www/cgi-bin/dashboard-data
echo "仪表盘包已复制到 package/luci-app-dashboard"

# --- 7. 复制 files 目录（加固脚本 + sysctl 内存保护）---
if [ -d "$GITHUB_WORKSPACE/files" ]; then
    echo "=== 复制加固 files 目录 ==="
    cp -rf $GITHUB_WORKSPACE/files .
    chmod +x files/etc/uci-defaults/* 2>/dev/null || true
    echo "加固 files 已复制（CPU锁频/WPA2纯协议/射频保护/内存保护）"
fi

# --- 8. 更新并安装 feeds ---
echo "=== 更新 feeds ==="
./scripts/feeds update -a
./scripts/feeds install -a

# --- 8.5 zram-swap 上限锁 256MB ---
# 上游 init 脚本路径为 package/system/zram-swap/files/zram.init（注意文件名是 zram.init）
# 其默认值为 ram_size(kB) / 2048 = 物理内存的一半（512M 机型约 240MB）
# 这里显式钉成 256MB，避免不同内核 MemTotal 差异导致数值漂移
ZRAM_INIT="package/system/zram-swap/files/zram.init"
if [ ! -f "$ZRAM_INIT" ]; then
    ZRAM_INIT=$(find package feeds -type f \( -name "zram.init" -o -name "zram" \) 2>/dev/null | head -1)
fi
if [ -n "$ZRAM_INIT" ] && [ -f "$ZRAM_INIT" ]; then
    # 默认值表达式: echo $(( ram_size / 2048 ))  ->  echo 256
    sed -i 's|\$(( ram_size / 2048 ))|256|' "$ZRAM_INIT"
    if grep -q 'echo 256' "$ZRAM_INIT"; then
        echo "[zram] 默认大小已锁定 256MB ($ZRAM_INIT)"
    else
        echo "[zram] 警告：patch 未命中，$ZRAM_INIT 内容可能已变更（将按默认 = 内存一半约 240MB）"
    fi
else
    echo "[zram] 警告：未找到 zram-swap init，将按默认值（内存一半约 240MB）"
fi

# --- 9. 设置默认登录页为仪表盘 ---
echo "=== 设置默认首页为系统仪表盘 ==="
LUCI_CONFIG="package/feeds/luci/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CONFIG" ]; then
    if ! grep -q "option home" "$LUCI_CONFIG"; then
        sed -i "/config internal 'main'/a\\\toption home '/admin/dashboard'" "$LUCI_CONFIG"
        echo "已设置默认首页为 /admin/dashboard"
    else
        sed -i "s|option home.*|option home '/admin/dashboard'|" "$LUCI_CONFIG"
        echo "已更新默认首页为 /admin/dashboard"
    fi
else
    echo "警告: 未找到 LuCI 配置文件 $LUCI_CONFIG"
fi

echo "=== 自定义配置加载完成 ==="
