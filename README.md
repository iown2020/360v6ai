# 360V6 (RE-CS-02) OpenWRT NSS 加固精简固件编译工程

## 硬件规格

| 项目 | 参数 |
|------|------|
| 设备型号 | 360 安全路由 V6 (RE-CS-02) |
| SoC | Qualcomm IPQ6000 (4 核 Cortex-A53 @ 1.5GHz) |
| NPU | NSS 网络加速引擎 |
| Flash | 128MB NAND |
| RAM | **512MB**（出厂） |
| WiFi | QCN5022 (2.4G) + QCN5052 (5G) |
| 网口 | 1×WAN + 3×LAN (千兆) |
| USB | 1×USB 2.0 |
| OpenWrt 目标 | qualcommax / ipq60xx |
| 设备名 | qihoo_360v6 |

---

## 固件方案

### 源码基础

基于 **laipeng668/openwrt-6.x** 的 `25.12-nss` 分支编译：
- **Linux 6.12 内核**，完整 NSS 硬件加速支持
- 源自 ImmortalWrt/LibWrt，包含全功能 NSS 驱动（kmod-qca-nss-*）
- NSS 固件版本：v11.4
- 360V6 原生 512MB 内存，ath11k 使用 `ATH11K_MEM_PROFILE_512M`（源码仅支持 1G/512M/256M）

### 预装软件包

| 类别 | 软件包 |
|------|--------|
| **管理界面** | LuCI 全套 + Aurora 主题（简体中文） |
| **NSS 加速** | 全套 qca-nss 驱动 + ECM 连接管理器 + NSS DP |
| **科学上网** | **OpenClash**（含 TUN/TProxy 依赖） |
| **内网组网** | **EasyTier 2.4.5**（由官方 v2.4.5 tag 构建） |
| **局域网共享** | **Samba4** |
| **存储支持** | USB 存储驱动（ext4/vfat/msdos）+ U 盘自动挂载 |
| **系统工具** | bash、htop、nano、openssh-sftp-server、ttyd 终端 |
| **运维插件** | luci-app-wol（网络唤醒）、luci-app-autoreboot（定时重启）、luci-app-upnp、autocore（硬件状态） |
| **CPU 调频** | cpufreq 服务 + luci-app-cpufreq：performance 策略，864MHz~1.2GHz（默认值写入 `/etc/config/cpufreq`，界面可调） |
| **交换分区** | zram-swap（256MB / LZ4） |

---

## 出厂自动加固（首次开机执行）

### 1. CPU 锁频 1.2GHz — 根治电源过流锁死

- 内核编译了全部频率档位（864/1056/1200/1320/1440/1512 MHz 全芯片可用，1608/1800 仅 IPQ6010），**运行时**由 cpufreq 服务把上限设为 1.2GHz（uci 持久化，重启不丢）
- 360V6 原厂 12V 1.5A 适配器老化后滤波电容 ESR 上升，CPU 从休眠跃升到 1.512GHz 时电压瞬跌会触发电源内部 PWM 过流闭锁（Latch-off），表现为**突发掉电且看门狗无法重启**
- 锁频 1.2GHz 后 CPU 动态功耗比 1.5GHz 降低约 45%，彻底消除瞬态电流尖峰
- NSS 硬件加速已承担千兆转发，CPU 日常负载 <20%，收益极低

> 手动解锁满频：已换 12V 2A+ 电源后，进入「系统 → CPU Freq（CPU 调频）」把最大频率改成 `1512000` 保存即可（cpufreq 会自动应用并持久化）。

### 2. Wi-Fi 射频保护与协议栈加固

- **纯 WPA2-PSK**：关闭 WPA3-SAE 与 PMF (802.11w)，规避 ath11k 闭源 Q6 DSP 微码竞态死锁
- **5GHz 23dBm (200mW) / 2.4GHz 20dBm (100mW)**：防止 FEM 功放满负荷过热导致 EVM 恶化、Wi-Fi 降速
- 功率**按 band（频段）自动匹配**，不依赖 radio0/radio1 枚举顺序，避免不同 DTS 下 phy 顺序差异导致错配
- **休眠唤醒防踢出**：关闭低 ACK 解关联探测，手机息屏不掉线

### 3. 内核 Order-3 内存防崩溃

- `vm.min_free_kbytes=16384` 预留 16MB 连续物理内存，防止 ath11k 驱动在大流量下 GFP_ATOMIC 分配失败死锁
- `vm.vfs_cache_pressure=150` 激进回收 Slab 缓存

### 4. NSS ECM 独占硬件加速

- 出厂自动关闭 fw4 的 `flow_offloading` / `flow_offloading_hw` / FullCone 以及 `packet_steering`，这些软件加速与 NSS ECM 互斥，同时开启会导致丢包和高延迟

### 5. PPPoE LCP 保活优化

- 关闭默认 5 秒 3 次的激进 LCP keepalive，链路轻微抖动即触发重拨

---

## 编译步骤（GitHub Actions 云编译）

### 前置准备

1. 注册/登录 GitHub 账号
2. **Fork 本仓库**到你自己的账号

### 步骤一：配置仓库权限

1. 进入你 Fork 后的仓库
2. 点击 **Settings** → **Actions** → **General**
3. 下滑到 **Workflow permissions**，选择 **Read and write permissions**
4. 点击 **Save**

### 步骤二：触发编译

1. 点击 **Actions** 标签
2. 左侧选择 **360V6 OpenWRT NSS Firmware Build**
3. 点击右侧 **Run workflow** 按钮，确认分支为 `main`，点击绿色 **Run workflow**

### 步骤三：等待编译

- 编译预计耗时：**1~2 小时**（首次编译；后续有三层缓存加速：ccache 编译缓存 + staging_dir 工具链 + `dl/` 源码包缓存，dl 按源码分支复用，不再每次重下）
- 编译成功后自动创建 **Release**（标签 `R<构建序号>`），在仓库 **Releases** 页下载固件、`sha256sums`、`config.buildinfo`
- 编译前有**预检**：设备目标、512M profile、Aurora、仪表盘、cpufreq、zram-swap/kmod-zram/LZ4 后端，任一缺失立即 FAIL，不会白跑几小时
- 编译失败会在该次运行页面底部 **Artifacts** 中提供 `build-failed-log`

---

## 默认访问信息

| 项目 | 默认值 |
|:---|:---|
| **后台 IP** | `192.168.50.1` |
| **登录用户** | `root` |
| **管理密码** | 无（首次登录自行设置） |
| **无线 SSID** | `2024`（2.4G / 5G 同名） |
| **无线密码** | `20242024`（WPA2-PSK） |

---

## 刷机方法

### 方式 A：sysupgrade 升级（已在 OpenWrt 下）

LuCI 界面：**系统 → 备份/升级 → 刷写新的固件** → 上传 `sysupgrade.bin`
- 跨大版本升级建议**不保留配置**，让出厂加固脚本完整生效

### 方式 B：U-Boot 刷入（救砖/首次刷机）

通过串口连接 U-Boot，使用 TFTP 刷入 `factory.ubi`。

---

## 刷后验证

### 验证 NSS 加速

```sh
lsmod | grep nss
cat /sys/kernel/debug/qca-nss-drv/stats
```

跑满速时 CPU 占用率应 **<20%**，rx_bytes/tx_bytes 持续增长。

### 验证加固脚本

```sh
# CPU 锁频（应输出 1200000 / performance）
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Wi-Fi 功率
iwinfo radio0 txpower; iwinfo radio1 txpower

# 内存保护与 zram
sysctl vm.min_free_kbytes
cat /sys/block/zram0/disksize 2>/dev/null
cat /sys/block/zram0/comp_algorithm   # 期望 [lz4]
```

---

## 文件结构

```
360V6-NSS-AI-Modified/
├── .github/workflows/build-openwrt.yml   # 云编译 + 预检 + ccache/dl 缓存 + Release 发布
├── configs/
│   ├── IPQ60XX.config                    # 目标平台 + 512M 内存 Profile + NSS 固件版本
│   └── General.config                    # 预装/禁用软件包列表
├── scripts/Roc-script.sh                 # 编译前：改 IP、Aurora、OpenClash、EasyTier feed、files 复制
├── files/
│   ├── etc/uci-defaults/99-custom-stability  # 首次开机：cpufreq/Wi-Fi/射频/防火墙/ECM/dnsmasq/主题/zram
│   ├── etc/config/cpufreq                    # cpufreq 默认值：performance / 864-1200MHz
│   ├── etc/init.d/custom-tune                # 每次开机：irqbalance + sysctl
│   └── etc/sysctl.d/99-kernel-tune.conf      # 内核内存/网络栈调优
└── README.md
```

---

## 参考链接

- [laipeng668/openwrt-6.x NSS 源码](https://github.com/laipeng668/openwrt-6.x/tree/25.12-nss) — 编译基础（Linux 6.12 + NSS v11.4）
- [ThinkPad88/360V6-NSS-AI](https://github.com/ThinkPad88/360V6-NSS-AI) — 本工程上游原始仓库
- [zhiffu/360v6-openwrt](https://github.com/zhiffu/360v6-openwrt) — 360V6 设备适配与加固方案参考
- [OpenClash 官方仓库](https://github.com/vernesong/OpenClash)
- [EasyTier 官方仓库](https://github.com/EasyTier/EasyTier)
- [Aurora 主题](https://github.com/eamonxg/luci-theme-aurora)
