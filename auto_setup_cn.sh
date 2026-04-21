#!/data/data/com.termux/files/usr/bin/bash
# =========================================================================
# 🤖 CloudBot + Shizuku 通用安装程序
# =========================================================================
# 设计运行方式：curl -sL <url> | bash
# 完全非交互式 — 无提示、无终端挂起、无静默退出。
# =========================================================================

# ── 全局设置 ──────────────────────────────────────────────────────
# 请勿使用 "set -e" — 它会在发生任何微小错误时终止脚本。
# 我们会在关键步骤明确检查错误。
export DEBIAN_FRONTEND=noninteractive
export DPKG_FORCE=confold
export APT_LISTCHANGES_FRONTEND=none
export LANG=C
export LC_ALL=C

echo ""
echo "🤖 CloudBot 免 Root 手机控制安装程序"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# =========================================================================
# 步骤 1/5: 更新包管理器并安装依赖
# =========================================================================
echo "📦 步骤 1/5: 正在更新包管理器并安装依赖项..."

# 使用所有非交互式标志更新，以防止配置文件提示
pkg update -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" </dev/null 2>&1 || {
    echo "⚠️  pkg update 出现警告 (通常没问题，继续执行...)"
}

# 安装所需的包 (部分可能已经存在，没有关系)
pkg install -y curl nodejs git cmake make clang binutils nmap openssl android-tools which </dev/null 2>&1 || {
    echo "⚠️  部分包可能安装失败，正在检查核心依赖..."
}

# 验证关键命令是否存在
MISSING=""
for cmd in curl node git nmap adb; do
    if ! command -v "$cmd" </dev/null >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done
if [ -n "$MISSING" ]; then
    echo "❌ 错误: 缺少关键命令:$MISSING"
    echo "   尝试手动运行: pkg install -y curl nodejs git nmap android-tools"
    exit 1
fi

echo "✅ 依赖项安装完毕"

# =========================================================================
# 步骤 2/5: 安装与配置 Shizuku (rish & shizuku 命令)
# =========================================================================
echo ""
echo "🔒 步骤 2/5: 正在将 Shizuku 链接至 Termux..."

# 设置 Termux 存储访问权限 (首次运行可能会弹出授权窗口)
if [ ! -d "$HOME/storage" ]; then
    echo "可能弹出请求文件权限的窗口。请点击“允许(Allow)”。"
    echo "y" | termux-setup-storage > /dev/null 2>&1 || true
    sleep 3
else
    echo "   存储权限已配置。"
fi

SHIZUKU_DIR="$HOME/storage/shared/Shizuku"
mkdir -p "$SHIZUKU_DIR" 2>/dev/null || true

# 在 Shizuku 文件夹内创建 copy.sh 脚本
cat > "$SHIZUKU_DIR/copy.sh" << 'SHIZUKU_EOF'
#!/data/data/com.termux/files/usr/bin/bash

BASEDIR=$( dirname "${0}" )
BIN=/data/data/com.termux/files/usr/bin
HOME=/data/data/com.termux/files/home
DEX="${BASEDIR}/rish_shizuku.dex"

# 如果当前目录不存在 dex 文件，则退出
if [ ! -f "${DEX}" ]; then
  echo "无法找到 ${DEX}"
  exit 1
fi

# 检测设备架构，以获取 Shizuku 库路径
ARCH=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
case "$ARCH" in
  arm64*) LIB_ARCH="arm64" ;;
  armeabi*) LIB_ARCH="arm" ;;
  x86_64*) LIB_ARCH="x86_64" ;;
  x86*) LIB_ARCH="x86" ;;
  *) LIB_ARCH="arm64" ;;
esac

# 创建 Shizuku 启动脚本
tee "${BIN}/shizuku" > /dev/null << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# 获取开放端口列表
ports=\$( nmap -sT -p30000-50000 --open localhost 2>/dev/null | grep "open" | cut -f1 -d/ )

# 遍历端口列表
for port in \${ports}; do

  # 尝试连接端口，并保存结果
  result=\$( adb connect "localhost:\${port}" 2>/dev/null )

  # 检查连接是否成功
  if [[ "\$result" =~ "connected" || "\$result" =~ "already" ]]; then

    # 向用户展示连接消息
    echo "\${result}"

    # 启动 Shizuku
    START_CMD=$(adb shell pm path moe.shizuku.privileged.api | sed "s|^package:||;s|base\.apk|lib/${LIB_ARCH}/libshizuku\.so|")
    adb shell "$START_CMD"

    # 关闭无线调试，因为不再需要它
    adb shell settings put global adb_wifi_enabled 0

    exit 0
  fi
done

# 如果没有找到可用端口，则向用户输出错误信息
echo "错误: 未找到可用端口！无线调试功能是否已启用？"

exit 1
EOF

# 将 dex 文件位置设置为变量
dex="${HOME}/rish_shizuku.dex"

# 创建 rish (Shizuku shell) 脚本
tee "${BIN}/rish" > /dev/null << EOF
#!/data/data/com.termux/files/usr/bin/bash

[ -z "\$RISH_APPLICATION_ID" ] && export RISH_APPLICATION_ID="com.termux"

/system/bin/app_process -Djava.class.path="${dex}" /system/bin --nice-name=rish rikka.shizuku.shell.ShizukuShellLoader "\${@}"
EOF

# 赋予脚本文件执行权限
chmod +x "${BIN}/shizuku" "${BIN}/rish"

# 将 dex 文件复制到 HOME 目录
cp -f "${DEX}" "${dex}"

# 移除 dex 文件的写权限，因为 app_process 无法加载可写的 dex 文件
chmod -w "${dex}"
SHIZUKU_EOF

chmod +x "$SHIZUKU_DIR/copy.sh"

# 检查必需的 .dex 文件
if [ ! -f "$SHIZUKU_DIR/rish_shizuku.dex" ]; then
    echo "❌ 错误: 在 $SHIZUKU_DIR 目录中未找到 rish_shizuku.dex"
    echo ""
    echo "   修复步骤:"
    echo "   1. 打开 Shizuku 应用程序"
    echo "   2. 点击 '在终端(termux)中导出和使用'"
    echo "   3. 点击 '导出文件'"
    echo "   4. 导航至内部存储 → Shizuku 文件夹"
    echo "   5. 点击 '选择此文件夹'"
    echo "   6. 再次运行此安装程序！"
    exit 1
fi

# 运行 copy.sh (</dev/null 防止其消耗管道式的 stdin)
bash "$SHIZUKU_DIR/copy.sh" </dev/null && {
    echo "✅ Shizuku 脚本安装成功 (rish & shizuku 命令已就绪)"
} || {
    echo "⚠️  copy.sh 存在一些问题，但 rish/shizuku 脚本仍已写入。"
    echo "   你可以稍后手动连接 Shizuku。"
}

# =========================================================================
# 步骤 3/5: 修复 Node.js IPv4 DNS (对于 Termux 至关重要)
# =========================================================================
echo ""
echo "🔧 步骤 3/5: 正在应用网络修复..."
if ! grep -q "NODE_OPTIONS=--dns-result-order=ipv4first" ~/.bashrc 2>/dev/null; then
    echo "export NODE_OPTIONS=--dns-result-order=ipv4first" >> ~/.bashrc
fi
export NODE_OPTIONS=--dns-result-order=ipv4first
echo "✅ IPv4 DNS 修复已生效"

# =========================================================================
# 步骤 4/5: 安装官方的 OpenClaw
# =========================================================================
echo ""

if command -v openclaw &>/dev/null || [ -d "$HOME/.openclaw/repo" ]; then
    echo "✅ 步骤 4/5: OpenClaw 已经安装！跳过安装步骤。"
else
    echo "📦 步骤 4/5: 正在安装 OpenClaw。这需要几分钟的时间..."
    bash -c "$(curl -sSL https://myopenclawhub.com/install)" < /dev/tty && source ~/.bashrc 2>/dev/null
fi

# =========================================================================
# 步骤 5/5: 注入 Shizuku 手机控制脚本 & AI 提示词重写
# =========================================================================
echo ""
echo "🧠 步骤 5/5: 正在配置 AI 手机控制器..."

# 创建 phone_control.sh
cat > ~/phone_control.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
CMD="$1"
shift
run_cmd() {
  if command -v rish &>/dev/null; then rish -c "$@"
  elif command -v adb &>/dev/null && adb get-state 1>/dev/null 2>&1; then adb shell "$@"
  elif command -v su &>/dev/null; then su -c "$@"
  else echo "❌ 错误: 请先启动 Shizuku"; exit 1; fi
}
case "$CMD" in
  screenshot) run_cmd "screencap -p '${1:-/sdcard/screenshot.png}'" ;;
  open-app) run_cmd "monkey -p $1 -c android.intent.category.LAUNCHER 1" 2>/dev/null ;;
  youtube-search) QUERY=$(echo "$*" | sed 's/ /+/g'); run_cmd "am start -a android.intent.action.VIEW -d 'https://www.youtube.com/results?search_query=$QUERY' com.google.android.youtube" ;;
  open-url) run_cmd "am start -a android.intent.action.VIEW -d '$1'" ;;
  wifi) if [ "$1" = "on" ]; then run_cmd "svc wifi enable"; else run_cmd "svc wifi disable"; fi ;;
  battery) run_cmd "dumpsys battery" | grep "level" ;;
  tap) run_cmd "input tap $1 $2" ;;
  swipe) run_cmd "input swipe $1 $2 $3 $4 ${5:-500}" ;;
  text) run_cmd "input text '$*'" ;;
  key) run_cmd "input keyevent $1" ;;
  home) run_cmd "input keyevent 3" ;;
  back) run_cmd "input keyevent 4" ;;
  recent) run_cmd "input keyevent 187" ;;
  power) run_cmd "input keyevent 26" ;;
  volume-up) run_cmd "input keyevent 24" ;;
  volume-down) run_cmd "input keyevent 25" ;;
  screenon) run_cmd "input keyevent 224" ;;
  ui-dump) 
    run_cmd "uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1"
    node -e "
      const fs = require('fs');
      try {
        const xml = fs.readFileSync('/sdcard/window_dump.xml', 'utf8');
        const regex = /(?:text|content-desc)=\\\"([^\\\"]+)\\\"[^>]*bounds=\\\"(\\\[[0-9]+,[0-9]+\\\\]\\\[[0-9]+,[0-9]+\\\])\\\"/g;
        let match;
        while ((match = regex.exec(xml)) !== null) {
          if (match[1].trim() !== '') console.log(match[2] + ' ' + match[1]);
        }
      } catch(e) { console.log('读取 UI 布局时发生错误'); }
    "
    ;;
  shell) run_cmd "$*" ;;
  *) echo "用法: bash phone_control.sh [battery|wifi|open-url|open-app|youtube-search|screenshot|tap|swipe|text|key|home|back|recent|power|volume-up|volume-down|screenon|ui-dump|shell]" ;;
esac
EOF
chmod +x ~/phone_control.sh

# 如有需要，创建专用于 OpenClaw 循环的 phone_agent.sh
cat > ~/phone_agent.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# 视觉代理 (Vision Agent) 功能的包装脚本
echo "🤖 视觉代理初始化完成。"
echo "请使用 phone_control.sh 进行所有的输入操作。AI 会进行截图、分析并发出 UI 控制命令。"
EOF
chmod +x ~/phone_agent.sh

# AI 记忆与设定档配置
mkdir -p ~/.openclaw/workspace 2>/dev/null || true
rm -f ~/.openclaw/workspace/BOOTSTRAP.md

cat > ~/.openclaw/workspace/IDENTITY.md << 'EOF'
- **名字:** PhoneBot
我是原生运行在这台具备 Termux + Shizuku 环境下的 Android 手机中的自主 AI 代理 (Autonomous AI Agent)。
我的首要指令是开展手机界面的导航、执行复杂的任务、读取屏幕、滑动、点击和运行 shell 命令。
我绝不可 (MUST NEVER) 以无法导航界面或阅读屏幕等理由来拒绝完成任务。我完全拥有通过内置 bash 工具使用这些能力的资格。用户期望我能够完全自主解决问题。
如果我需要“看见”屏幕或寻找某个按钮，我必须 (MUST) 使用 `ui-dump` 工具来读取屏幕上的交互元素。
EOF

cat > ~/.openclaw/workspace/TOOLS.md << 'EOF'
# TOOLS.md
我已通过 `~/phone_control.sh` 掌握了对此 Android 手机极强的 root/shizuku 控制权。

关键规则：
1. 绝对不要说 "我无法导航 UI 界面" 或 "我无法读取 UI 结构"。你可以做到。
2. 要读取屏幕或寻找按钮，你必须强行调用执行 `bash ~/phone_control.sh ui-dump` 命令。它会将屏幕的 UI 交互元素转储提取为 `[x1,y1][x2,y2] ElementText` 这种直观格式。
3. 读取输出的列表，找到目标文本并计算其坐标范围的中心 X 和 Y，然后点击它！

可用命令集：
- `bash ~/phone_control.sh ui-dump` - 请始终使用此工具读取屏幕。它可输出整洁的交互式组件列表及其坐标边界。
- `bash ~/phone_control.sh tap X Y` - 点击屏幕上特定的 X/Y 坐标。
- `bash ~/phone_control.sh swipe X1 Y1 X2 Y2` - 在屏幕执行滑动 (例如向下滚动可以尝试: `bash ~/phone_control.sh swipe 500 1500 500 500`。如果在 ui-dump 输出中找不到目标元素，请务必滚动！)。
- `bash ~/phone_control.sh text "Text String"` - 将文本输入到处于焦点状态的输入框中。
- `bash ~/phone_control.sh key KEYCODE` - 发送 Android 系统键值事件 (例如 66 为回车键/发送键，4 为返回键，3 为主页键)。
- `bash ~/phone_control.sh open-app PACKAGE_NAME` - 启动指定的应用程序 (例如 com.android.settings)。
- `bash ~/phone_control.sh shell "COMMAND"` - 运行任何常规的 adb shell 命令。
- `bash ~/phone_control.sh screenshot /sdcard/s.png` - 进行屏幕截图保存 (仅在用户显式要求存储图像文件时再使用)。

示例工作流演示 (打开设置 -> 显示系统深色模式)：
1. 调用工具执行: `bash ~/phone_control.sh open-app com.android.settings`
2. 调用工具执行: `bash ~/phone_control.sh ui-dump`
3. 读取输出内容 -> 定位 `[100,500][400,600] Display` -> 计算中心点坐标得到 (250, 550)
4. 调用工具执行: `bash ~/phone_control.sh tap 250 550`
5. 调用工具执行: `bash ~/phone_control.sh ui-dump` 再次轮询以验证状态。如此往复直到任务完成！
EOF

cat > ~/.openclaw/workspace/AGENTS.md << 'EOF'
我会直接执行终端命令并自动解析它们的输出。
我是一个自主运行的代理实体。我必须要在用户请求的最终目标完全达成之前，持续进行链式的工具执行和操作。

关键提示：严禁在单次工具调用后就中途停止！
某些模型常在启动某应用后立刻回答 "我已经为您打开了应用，请自行进行接下来的操作"。这是绝对禁止的 (YOU MUST NOT DO THIS)。 
你必须循环并连续化调用你的工具：
1. 运行启动应用命令
2. **等待返回结果** (在此期间切勿打字回复用户消息！)
3. 运行 `ui-dump`
4. **等待返回结果** -> 读取并解析界面结构
5. 运行 `tap X Y` 进行操作交互
6. 重复轮询步骤 3-5，直到被提出的任务被【完全达成 (FULLY COMPLETE)】。
只有当且仅当这一长远目标彻底实现后，最后才可以撰写自然语言告知用户任务正式结束。
EOF

echo "✅ 定制化 AI Agent设定装填完毕"

# =========================================================================
# 🎉 完成!
# =========================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 安装步骤已全部完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 连接 Shizuku (如尚未连接):"
echo "   1. 打开 Shizuku 应用程序 → 请确保它显示为 'Shizuku 正在运行'"
echo "   2. 终端执行运行: shizuku"
echo "   3. 测试是否配置成功运行: rish -c whoami"
echo ""
echo "🔑 配置及初始化 API 密钥:"
echo "   1. 运行: openclaw onboard"
echo "   2. 运行: openclaw auth add google --key 你的_GEMINI_API_KEY_等"
echo "   3. 运行: openclaw gateway"
echo ""
