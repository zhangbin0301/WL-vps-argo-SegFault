#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# Script version
VERSION="1.0.1"

# Log file
LOG_FILE="/tmp/vps_script.log"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to display and log messages
print_and_log() {
    local level="$1"
    local message="$2"
    local color="$PLAIN"
    
    case "$level" in
        "INFO") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
    esac
    
    echo -e "${color}${message}${PLAIN}"
    log_message "$level" "$message"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_and_log "WARNING" "当前非root用户，某些功能可能受限"
        return 1
    fi
    return 0
}

# Check if systemd is available
has_systemd() {
    if command -v systemctl >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Get system information
get_system_info() {
    ARCH=$(uname -m)
    KERNEL=$(uname -r)
    OS_TYPE=$(uname -s)
    
    # Try to detect virtualization
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        VIRT=$(systemd-detect-virt 2>/dev/null || echo "Unknown")
    elif [ -f "/proc/cpuinfo" ]; then
        if grep -q "hypervisor" /proc/cpuinfo; then
            VIRT="VM-based"
        elif dmesg | grep -qi "kvm\|qemu\|virtualbox\|vmware\|xen\|docker\|lxc"; then
            VIRT="Container/VM"
        else
            VIRT="Likely Physical"
        fi
    else
        VIRT="Unknown"
    fi
    
    # Get OS distribution if possible
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        DISTRO="${ID}-${VERSION_ID}"
    else
        DISTRO="Unknown"
    fi
    
    print_and_log "INFO" "系统信息: $OS_TYPE $ARCH ($KERNEL)"
    print_and_log "INFO" "发行版: $DISTRO"
    print_and_log "INFO" "虚拟化类型: $VIRT"
}

# Check and install dependencies
check_and_install_dependencies() {
    print_and_log "INFO" "正在检查依赖项..."
    
    # List of dependencies
    dependencies=("curl" "wget" "pgrep" "pidof" "grep" "sed" "awk")
    
    local missing_deps=()
    
    # Check for missing dependencies
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Install missing dependencies if any
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_and_log "INFO" "需要安装的依赖项: ${missing_deps[*]}"
        
        # Try to determine package manager
        if command -v apt-get &>/dev/null; then
            print_and_log "INFO" "使用apt-get安装依赖项"
            apt-get update -qq
            apt-get install -y "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        elif command -v yum &>/dev/null; then
            print_and_log "INFO" "使用yum安装依赖项"
            yum install -y "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        elif command -v dnf &>/dev/null; then
            print_and_log "INFO" "使用dnf安装依赖项"
            dnf install -y "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        elif command -v apk &>/dev/null; then
            print_and_log "INFO" "使用apk安装依赖项"
            apk add --no-cache "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        else
            print_and_log "ERROR" "无法确定包管理器，请手动安装以下依赖项: ${missing_deps[*]}"
            return 1
        fi
        
        # Verify dependencies were installed
        local still_missing=()
        for dep in "${missing_deps[@]}"; do
            if ! command -v "$dep" &>/dev/null; then
                still_missing+=("$dep")
            fi
        done
        
        if [ ${#still_missing[@]} -gt 0 ]; then
            print_and_log "ERROR" "以下依赖项安装失败: ${still_missing[*]}"
            print_and_log "WARNING" "脚本将继续运行，但可能出现问题"
        else
            print_and_log "INFO" "所有依赖项安装成功"
        fi
    else
        print_and_log "INFO" "所有依赖项已安装"
    fi
    
    return 0
}

# Initialize configuration variables with defaults
init_config_vars() {
    # Define default file names
    export ne_file=${ne_file:-'nenether.js'}
    export cff_file=${cff_file:-'cfnfph.js'}
    export web_file=${web_file:-'webssp.js'}
    
    # Set file path with proper handling
    if [[ "$PWD" == */ ]]; then
        FLIE_PATH="${FLIE_PATH:-${PWD}worlds/}"
    else
        FLIE_PATH="${FLIE_PATH:-${PWD}/worlds/}"
    fi
    
    # Ensure the path exists with proper permissions
    if [ ! -d "${FLIE_PATH}" ]; then
        print_and_log "INFO" "创建目录: ${FLIE_PATH}"
        if ! mkdir -p -m 755 "${FLIE_PATH}"; then
            print_and_log "ERROR" "创建目录失败，权限不足: ${FLIE_PATH}"
            print_and_log "INFO" "尝试在/tmp目录下创建备用目录"
            FLIE_PATH="/tmp/worlds/"
            if ! mkdir -p -m 755 "${FLIE_PATH}"; then
                print_and_log "ERROR" "创建备用目录失败: ${FLIE_PATH}"
                return 1
            fi
        fi
    fi
    
    # Clean up any existing log files
    if [ -f "/tmp/list.log" ]; then
        rm -rf /tmp/list.log
    fi
    if [ -f "${FLIE_PATH}list.log" ]; then
        rm -rf "${FLIE_PATH}list.log"
    fi
    
    print_and_log "INFO" "配置初始化完成"
    print_and_log "INFO" "文件路径: ${FLIE_PATH}"
    return 0
}

# Get user configuration input
get_user_config() {
    print_and_log "INFO" "开始配置节点..."
    
    # Node type
    echo -e -n "${GREEN}请输入节点类型 (可选: vls, vms, rel, hy2, tuic, 3x 默认: vls):${PLAIN}"
    read TMP_ARGO
    export TMP_ARGO=${TMP_ARGO:-'vls'}
    print_and_log "INFO" "节点类型: $TMP_ARGO"
    
    # Port for specific protocols
    if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hy2" ] || [ "${TMP_ARGO}" = "hys" ] || [ "${TMP_ARGO}" = "tuic" ] || [ "${TMP_ARGO}" = "3x" ]; then
        echo -e -n "${GREEN}请输入节点端口 (默认443):${PLAIN}"
        read SERVER_PORT
        export SERVER_PORT=${SERVER_PORT:-"443"}
        print_and_log "INFO" "节点端口: $SERVER_PORT"
    fi
    
    # Node upload URL
    echo -e -n "${GREEN}请输入节点上传地址: ${PLAIN}"
    read SUB_URL
    print_and_log "INFO" "节点上传地址: $SUB_URL"
    
    # Node name
    echo -e -n "${GREEN}请输入节点名称 (默认: vps): ${PLAIN}"
    read SUB_NAME
    export SUB_NAME=${SUB_NAME:-"vps"}
    print_and_log "INFO" "节点名称: $SUB_NAME"
    
    # NEZHA monitoring configuration
    echo -e -n "${GREEN}请输入 NEZHA_SERVER (不需要，留空即可): ${PLAIN}"
    read NEZHA_SERVER
    print_and_log "INFO" "NEZHA_SERVER: $NEZHA_SERVER"
    
    echo -e -n "${GREEN}请输入NEZHA_KEY (不需要，留空即可): ${PLAIN}"
    read NEZHA_KEY
    print_and_log "INFO" "NEZHA_KEY: $NEZHA_KEY"
    
    echo -e -n "${GREEN}请输入 NEZHA_PORT (默认443): ${PLAIN}"
    read NEZHA_PORT
    export NEZHA_PORT=${NEZHA_PORT:-"443"}
    print_and_log "INFO" "NEZHA_PORT: $NEZHA_PORT"
    
    echo -e -n "${GREEN}是否启用哪吒tls (1 启用, 0 关闭，默认启用): ${PLAIN}"
    read NEZHA_TLS
    export NEZHA_TLS=${NEZHA_TLS:-"1"}
    print_and_log "INFO" "NEZHA_TLS: $NEZHA_TLS"
    
    # Tunnel configuration for specific protocols
    if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ] || [ "${TMP_ARGO}" = "xhttp" ] || [ "${TMP_ARGO}" = "spl" ] || [ "${TMP_ARGO}" = "3x" ]; then
        echo -e -n "${GREEN}请输入固定隧道TOKEN(不填，则使用临时隧道): ${PLAIN}"
        read TOK
        print_and_log "INFO" "隧道TOKEN: $TOK"
        
        echo -e -n "${GREEN}请输入固定隧道域名 (临时隧道不用填): ${PLAIN}"
        read ARGO_DOMAIN
        print_and_log "INFO" "隧道域名: $ARGO_DOMAIN"
        
        echo -e -n "${GREEN}请输入cf优选IP或域名(默认 ip.sb): ${PLAIN}"
        read CF_IP
    fi
    export CF_IP=${CF_IP:-"ip.sb"}
    print_and_log "INFO" "CF_IP: $CF_IP"
    
    # Add server IP if available
    SERVER_IP=$(curl -s4m8 ip.sb || curl -s6m8 ip.sb)
    export SERVER_IP=${SERVER_IP:-"Unknown"}
    print_and_log "INFO" "服务器IP: $SERVER_IP"
    
    return 0
}

# Create startup script
create_startup_script() {
    local script_path="${FLIE_PATH}start.sh"
    print_and_log "INFO" "创建启动脚本: $script_path"
    
    cat <<EOL > "$script_path"
#!/bin/bash
## ===========================================设置参数（删除或加入#即可切换是否使用）==========================================

# 设置固定隧道参数（默认使用临时隧道，去掉前面的注释#即可使用固定隧道）
export TOK='$TOK'
export ARGO_DOMAIN='$ARGO_DOMAIN'

# 设置哪吒监控参数（NEZHA_TLS='1'启用tls，设置为其他关闭tls）
export NEZHA_SERVER='$NEZHA_SERVER'
export NEZHA_KEY='$NEZHA_KEY'
export NEZHA_PORT='$NEZHA_PORT'
export NEZHA_TLS='$NEZHA_TLS'

# 设置节点协议与reality参数（vls,vms,rel）
export TMP_ARGO=${TMP_ARGO:-'vls'}  # 设置节点使用的协议
export SERVER_PORT="${SERVER_PORT:-${PORT:-443}}" # ip不能被墙，端口不能占用，不能开启防火墙
export SNI=${SNI:-'www.apple.com'} # tls网站

# 设置app参数（默认x-ra-y参数，如更改了下载地址，则需要修改UUID和VPATH）
export FLIE_PATH='$FLIE_PATH'
export CF_IP='$CF_IP'
export SUB_NAME='$SUB_NAME'
export SERVER_IP='$SERVER_IP'
## ===========================================设置x-ra-y下载地址（建议使用默认）==========================================

export SUB_URL='$SUB_URL'
## ===================================
export ne_file='$ne_file'
export cff_file='$cff_file'
export web_file='$web_file'

# 检测下载工具并设置下载命令
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -sL"
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget -qO-"
else
    echo "错误: 找不到curl或wget，请安装其中一个。"
    sleep 30
    exit 1
fi

# 根据架构选择正确的二进制文件
arch=\$(uname -m)
if [[ \$arch == "x86_64" ]]; then
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-amd > /tmp/app
else
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-arm > /tmp/app
fi

chmod 777 /tmp/app && /tmp/app >> /tmp/app.log 2>&1
EOL
    
    # Make script executable
    chmod +x "$script_path"
    
    if [ $? -ne 0 ]; then
        print_and_log "ERROR" "创建启动脚本失败"
        return 1
    fi
    
    print_and_log "INFO" "启动脚本创建成功"
    return 0
}

# Configure system startup for the script
configure_system_startup() {
    local script_path="${FLIE_PATH}start.sh"
    print_and_log "INFO" "正在配置系统启动..."
    
    # Check if root (required for most startup methods)
    if ! check_root; then
        print_and_log "ERROR" "配置开机启动需要root权限"
        return 1
    fi
    
    # Try different methods based on what's available
    if has_systemd; then
        print_and_log "INFO" "检测到systemd，配置systemd服务..."
        
        # Create systemd service file
        cat <<EOL > /etc/systemd/system/tunnel_node.service
[Unit]
Description=Tunnel Node Service
After=network.target

[Service]
Type=simple
ExecStart=${script_path}
Restart=always
RestartSec=10
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOL
        
        # Enable and start the service
        systemctl daemon-reload
        systemctl enable tunnel_node.service
        systemctl restart tunnel_node.service
        
        if [ $? -ne 0 ]; then
            print_and_log "ERROR" "systemd服务启动失败，查看日志: journalctl -u tunnel_node.service"
            return 1
        fi
        
        print_and_log "INFO" "systemd服务配置成功"
        
    elif command -v openrc &>/dev/null; then
        print_and_log "INFO" "检测到OpenRC，配置OpenRC服务..."
        
        # Create OpenRC init script
        cat <<EOL > /etc/init.d/tunnel_node
#!/sbin/openrc-run
name="Tunnel Node Service"
description="VPS Tunnel Node Service"
command="${script_path}"
pidfile="/var/run/tunnel_node.pid"
command_background=true
output_log="/var/log/tunnel_node.log"
error_log="/var/log/tunnel_node.err"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath -f -m 0644 -o root:root "\$pidfile"
    checkpath -f -m 0644 -o root:root "\$output_log"
    checkpath -f -m 0644 -o root:root "\$error_log"
}
EOL
        
        # Make it executable and add to default runlevel
        chmod +x /etc/init.d/tunnel_node
        rc-update add tunnel_node default
        rc-service tunnel_node restart
        
        if [ $? -ne 0 ]; then
            print_and_log "ERROR" "OpenRC服务启动失败"
            return 1
        fi
        
        print_and_log "INFO" "OpenRC服务配置成功"
        
    elif [ -f "/etc/init.d/functions" ]; then
        print_and_log "INFO" "检测到SysV init，配置SysV服务..."
        
        # Create SysV init script
        cat <<EOL > /etc/init.d/tunnel_node
#!/bin/sh
### BEGIN INIT INFO
# Provides:          tunnel_node
# Required-Start:    \$network \$local_fs
# Required-Stop:     \$network \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Tunnel Node Service
# Description:       VPS Tunnel Node Service
### END INIT INFO

# Source function library
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

SCRIPT="${script_path}"
RUNAS=root
PIDFILE=/var/run/tunnel_node.pid
LOGFILE=/var/log/tunnel_node.log

start() {
    if [ -f "\$PIDFILE" ] && kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo 'Service already running' >&2
        return 1
    fi
    echo 'Starting service…' >&2
    
    # Start the script in background
    su -c "\$SCRIPT >> \$LOGFILE 2>&1 & echo \$! > \$PIDFILE" \$RUNAS
    
    # Check if it's running
    if [ -f "\$PIDFILE" ] && kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo 'Service started' >&2
        return 0
    else
        echo 'Service failed to start' >&2
        return 1
    fi
}

stop() {
    if [ ! -f "\$PIDFILE" ] || ! kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo 'Service not running' >&2
        return 1
    fi
    echo 'Stopping service…' >&2
    kill -15 \$(cat "\$PIDFILE") && rm -f "\$PIDFILE"
    echo 'Service stopped' >&2
    return 0
}

status() {
    if [ -f "\$PIDFILE" ] && kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo 'Service is running' >&2
        return 0
    else
        echo 'Service is not running' >&2
        return 1
    fi
}

case "\$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage: \$0 {start|stop|status|restart}"
        exit 1
        ;;
esac
exit 0
EOL
        
        # Make it executable and configure to start on boot
        chmod +x /etc/init.d/tunnel_node
        
        # Use the appropriate command to enable the service based on distribution
        if command -v chkconfig &>/dev/null; then
            chkconfig --add tunnel_node
            chkconfig tunnel_node on
        elif command -v update-rc.d &>/dev/null; then
            update-rc.d tunnel_node defaults
        else
            print_and_log "WARNING" "无法确定如何启用SysV服务，请手动配置"
        fi
        
        # Start the service
        /etc/init.d/tunnel_node start
        
        if [ $? -ne 0 ]; then
            print_and_log "ERROR" "SysV服务启动失败"
            return 1
        fi
        
        print_and_log "INFO" "SysV服务配置成功"
        
    elif grep -q "alpine" /etc/os-release 2>/dev/null; then
        print_and_log "INFO" "检测到Alpine Linux，使用适合Alpine的配置..."
        
        # For Alpine Linux, add to /etc/local.d/
        cat <<EOL > /etc/local.d/tunnel_node.start
#!/bin/sh
${script_path} >> /var/log/tunnel_node.log 2>&1 &
EOL
        
        chmod +x /etc/local.d/tunnel_node.start
        
        # Start the script now
        /etc/local.d/tunnel_node.start
        
        print_and_log "INFO" "Alpine启动配置成功"
        
    else
        print_and_log "WARNING" "未检测到标准初始化系统，尝试使用rc.local..."
        
        # Try to use rc.local
        if [ -f "/etc/rc.local" ]; then
            # Check if the script is already in rc.local
            if ! grep -q "$script_path" /etc/rc.local; then
                # Make sure we insert before exit 0 if it exists
                if grep -q "exit 0" /etc/rc.local; then
                    sed -i "s|^exit 0|$script_path >> /var/log/tunnel_node.log 2>\&1 \&\nexit 0|" /etc/rc.local
                else
                    echo "$script_path >> /var/log/tunnel_node.log 2>&1 &" >> /etc/rc.local
                fi
                
                # Make sure rc.local is executable
                chmod +x /etc/rc.local
            fi
        else
            # Create rc.local if it doesn't exist
            cat <<EOL > /etc/rc.local
#!/bin/sh
$script_path >> /var/log/tunnel_node.log 2>&1 &
exit 0
EOL
            chmod +x /etc/rc.local
        fi
        
        # Start the script now
        $script_path >> /var/log/tunnel_node.log 2>&1 &
        
        print_and_log "INFO" "rc.local配置成功"
    fi
    
    return 0
}

# Start the service temporarily (without system startup)
start_temporary() {
    local script_path="${FLIE_PATH}start.sh"
    print_and_log "INFO" "正在临时启动服务..."
    
    # Kill any existing processes
    kill_existing_processes
    
    # Start the script in background
    nohup "$script_path" > "${FLIE_PATH}run.log" 2>&1 &
    
    if [ $? -ne 0 ]; then
        print_and_log "ERROR" "临时启动服务失败"
        return 1
    fi
    
    print_and_log "INFO" "服务已在后台启动"
    return 0
}

# Wait for service to initialize and display node information
wait_for_service() {
    print_and_log "INFO" "等待服务初始化..."
    
    # Wait for log file to be created (max 60 seconds)
    local max_wait=60
    local counter=0
    local log_file=""
    
    while [ $counter -lt $max_wait ]; do
        if [ -f "${FLIE_PATH}list.log" ] && [ -s "${FLIE_PATH}list.log" ]; then
            log_file="${FLIE_PATH}list.log"
            break
        elif [ -f "/tmp/list.log" ] && [ -s "/tmp/list.log" ]; then
            log_file="/tmp/list.log"
            break
        fi
        
        sleep 1
        ((counter++))
        
        # Show progress every 5 seconds
        if [ $((counter % 5)) -eq 0 ]; then
            print_and_log "INFO" "正在等待服务启动... $counter 秒"
        fi
    done
    
    if [ -z "$log_file" ]; then
        print_and_log "ERROR" "服务未能在 $max_wait 秒内初始化"
        print_and_log "INFO" "检查 ${FLIE_PATH}run.log 或 /tmp/app.log 以获取详细错误信息"
        return 1
    fi
    
    # Check if the services are actually running
    local is_running=false
    
    for process in "$web_file" "$ne_file" "$cff_file" "app"; do
        if pgrep -f "$process" > /dev/null 2>&1 || ps aux | grep "$process" | grep -v grep > /dev/null 2>&1; then
            is_running=true
            break
        fi
    done
    
    if [ "$is_running" = true ]; then
        print_and_log "INFO" "服务已成功启动"
        
        echo -e "${CYAN}************节点信息******************${PLAIN}"
        echo "                         "
        # Display node information, replacing {PASS} with vless
        sed 's/{PASS}/vless/g' "$log_file" | cat
        echo "                         "
        echo -e "${CYAN}***************************************************${PLAIN}"
        
        return 0
    else
        print_and_log "ERROR" "服务似乎已初始化但进程未在运行"
        print_and_log "INFO" "检查 ${FLIE_PATH}run.log 以获取详细错误信息"
        return 1
    fi
}

# Kill existing processes
kill_existing_processes() {
    print_and_log "INFO" "清理现有进程..."
    
    # List of processes to check and kill
    local processes=("$web_file" "$ne_file" "$cff_file" "start.sh" "app")
    
    for process in "${processes[@]}"; do
        # Try to find and kill processes with pgrep
        if command -v pgrep > /dev/null 2>&1; then
            local pids=$(pgrep -f "$process" 2>/dev/null)
            if [ -n "$pids" ]; then
                print_and_log "INFO" "终止匹配 $process 的进程: $pids"
                for pid in $pids; do
                    kill -15 "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null
                fi
            fi
        fi
        
        # Also try ps and grep approach as backup
        if command -v ps > /dev/null 2>&1; then
            local ps_pids=$(ps aux | grep "$process" | grep -v grep | awk '{print $2}' 2>/dev/null)
            if [ -n "$ps_pids" ]; then
                print_and_log "INFO" "终止通过ps找到的 $process 进程: $ps_pids"
                for pid in $ps_pids; do
                    kill -15 "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null
                fi
            fi
        fi
    done
    
    # Give processes a moment to terminate
    sleep 2
    
    return 0
}

# Uninstall the service
uninstall_service() {
    print_and_log "INFO" "开始卸载服务..."
    local script_path="${FLIE_PATH}start.sh" # Define script_path for this function

    # 1. Stop and remove system services
    if has_systemd && systemctl list-unit-files | grep -q "tunnel_node.service"; then # Use the correct service name
        print_and_log "INFO" "停止并删除systemd服务..."
        systemctl stop tunnel_node.service
        systemctl disable tunnel_node.service
        rm -f /etc/systemd/system/tunnel_node.service
        rm -f /lib/systemd/system/tunnel_node.service # Also check common alternative path
        systemctl daemon-reload
        print_and_log "INFO" "Systemd服务已移除"
    fi
    
    if [ -f "/etc/init.d/tunnel_node" ]; then # Use the correct service name
        print_and_log "INFO" "停止并删除OpenRC/SysV服务..."
        if command -v rc-update &>/dev/null; then # OpenRC
             rc-service tunnel_node stop
             rc-update del tunnel_node default
        elif command -v update-rc.d &>/dev/null; then # SysV (Debian/Ubuntu)
            /etc/init.d/tunnel_node stop
            update-rc.d -f tunnel_node remove
        elif command -v chkconfig &>/dev/null; then # SysV (RHEL/CentOS)
             /etc/init.d/tunnel_node stop
             chkconfig --del tunnel_node
        else
            # Fallback for stopping if specific command not found
            killall -q tunnel_node # Attempt to kill by name
        fi
        rm -f "/etc/init.d/tunnel_node"
        print_and_log "INFO" "OpenRC/SysV服务已移除"
    fi

    # Remove Supervisor configuration if it exists
    if [ -f "/etc/supervisor/conf.d/tunnel_node.conf" ]; then # Adjusted name if used by your setup
        print_and_log "INFO" "删除Supervisor配置..."
        rm -f "/etc/supervisor/conf.d/tunnel_node.conf"
        if command -v supervisorctl &>/dev/null; then
            supervisorctl reread
            supervisorctl update
        fi
        print_and_log "INFO" "Supervisor配置已移除"
    fi
    
    # Remove Alpine Linux local.d script
    if [ -f "/etc/local.d/tunnel_node.start" ]; then
        print_and_log "INFO" "删除Alpine local.d启动脚本..."
        rm -f "/etc/local.d/tunnel_node.start"
        print_and_log "INFO" "Alpine local.d启动脚本已移除"
    fi

    # Remove from /etc/inittab (less common these days)
    if [ -f "/etc/inittab" ]; then
        if grep -q "$script_path" /etc/inittab; then
            print_and_log "INFO" "从/etc/inittab中删除启动条目..."
            sed -i "\#${script_path}#d" /etc/inittab
            print_and_log "INFO" "/etc/inittab中的启动条目已移除"
        fi
    fi

    # Remove from rc.local
    if [ -f "/etc/rc.local" ]; then
        if grep -q "$script_path" /etc/rc.local; then
            print_and_log "INFO" "从/etc/rc.local中删除启动条目..."
            # Escape path for sed
            local escaped_script_path=$(echo "$script_path" | sed 's/\//\\\//g')
            sed -i "/${escaped_script_path}/d" /etc/rc.local
            print_and_log "INFO" "/etc/rc.local中的启动条目已移除"
        fi
    fi

    # 2. Kill any running processes associated with the script
    kill_existing_processes

    # 3. Remove script files and directories
    if [ -f "$script_path" ]; then
        print_and_log "INFO" "删除启动脚本: $script_path"
        rm -f "$script_path"
    fi
    
    # Optionally remove the FLIE_PATH directory if it's empty and owned by the script
    # Be cautious with this, ensure it doesn't delete user data
    # For now, we'll just remove the log files created by the script
    print_and_log "INFO" "删除日志文件..."
    rm -f "${FLIE_PATH}list.log"
    rm -f "${FLIE_PATH}run.log"
    rm -f "/tmp/list.log"
    rm -f "/tmp/app.log"
    rm -f "$LOG_FILE" # The main log file of this script
    
    # If FLIE_PATH was /tmp/worlds/ and is empty, it's safer to remove
    if [ "$FLIE_PATH" == "/tmp/worlds/" ] && [ -d "$FLIE_PATH" ] && [ -z "$(ls -A "$FLIE_PATH")" ]; then
        print_and_log "INFO" "删除临时工作目录: $FLIE_PATH"
        rmdir "$FLIE_PATH"
    elif [ -d "$FLIE_PATH" ] && [ "$FLIE_PATH" != "$PWD/" ] && [ "$FLIE_PATH" != "./worlds/" ]; then
         # If it's not the current directory or a relative worlds, and not /tmp/worlds
         # user should decide whether to remove it. For now, leave it.
         print_and_log "WARNING" "工作目录 ${FLIE_PATH} 可能包含其他文件，未自动删除。"
    fi
    
    print_and_log "INFO" "卸载完成。"
    return 0
}


# Install BBR and WARP (Placeholder - adapt from install2.sh)
install_bbr_warp() {
    print_and_log "INFO" "开始安装BBR和WARP..."
    if command -v curl &>/dev/null; then
        bash <(curl -sL https://git.io/kernel.sh)
    elif command -v wget &>/dev/null; then
       bash <(wget -qO- https://git.io/kernel.sh)
    else
        print_and_log "ERROR" "找不到curl或wget，无法安装BBR/WARP。"
        return 1
    fi
    print_and_log "INFO" "BBR/WARP安装脚本已执行。"
    return 0
}

# Main installation function for X-R-A-Y
install_xray_service() {
    print_and_log "INFO" "开始安装X-R-A-Y服务..."
    
    if ! init_config_vars; then
        print_and_log "ERROR" "配置初始化失败，安装中止。"
        return 1
    fi
    
    if ! get_user_config; then
        print_and_log "ERROR" "用户配置收集失败，安装中止。"
        return 1
    fi
    
    # Kill existing processes before creating new script
    kill_existing_processes
    
    if ! create_startup_script; then
        print_and_log "ERROR" "启动脚本创建失败，安装中止。"
        return 1
    fi
    
    echo -e "${CYAN}>>>>>>>>请选择操作类型:${PLAIN}"
    echo -e "${GREEN}       1. 配置开机启动并运行 (推荐)${PLAIN}"
    echo -e "${GREEN}       2. 仅临时运行 (不配置开机启动)${PLAIN}"
    echo -e "${GREEN}       0. 取消安装${PLAIN}"
    read -p "请输入选项 [0-2]: " start_choice

    case "$start_choice" in
        1)
            if ! configure_system_startup; then
                print_and_log "ERROR" "系统启动配置失败。"
                print_and_log "INFO" "你可以尝试临时启动或检查日志进行调试。"
                # Optionally offer to start temporarily here
            else
                print_and_log "INFO" "系统启动配置成功。"
            fi
            ;;
        2)
            if ! start_temporary; then
                print_and_log "ERROR" "临时启动失败。"
            else
                print_and_log "INFO" "服务已临时启动。"
            fi
            ;;
        0)
            print_and_log "INFO" "安装已取消。"
            # Clean up created start.sh if any
            rm -f "${FLIE_PATH}start.sh"
            return 0
            ;;
        *)
            print_and_log "ERROR" "无效的选项，安装中止。"
            rm -f "${FLIE_PATH}start.sh"
            return 1
            ;;
    esac
    
    # Wait for the service to come up and display info
    wait_for_service
    
    print_and_log "INFO" "X-R-A-Y服务安装流程结束。"
    return 0
}


# Main menu
main_menu() {
    clear
    echo -e "${CYAN}============================================================${PLAIN}"
    echo -e "${PURPLE}           VPS 一键脚本 (Improved Tunnel Version ${VERSION})      ${PLAIN}"
    echo -e "${CYAN}============================================================${PLAIN}"
    get_system_info # Display system info at the top
    echo -e "${CYAN}------------------------------------------------------------${PLAIN}"
    echo -e " ${GREEN}1.${PLAIN} 安装 ${YELLOW}X-R-A-Y 服务${PLAIN}"
    echo -e " ${GREEN}2.${PLAIN} 安装 ${YELLOW}BBR 和 WARP${PLAIN}"
    echo -e " ${GREEN}3.${PLAIN} 卸载 ${YELLOW}X-R-A-Y 服务${PLAIN}"
    echo -e " ${GREEN}0.${PLAIN} ${RED}退出脚本${PLAIN}"
    echo -e "${CYAN}============================================================${PLAIN}"
    read -p " 请输入你的选择 [0-3]: " choice

    case "$choice" in
        1)
            check_root # Some functions might require root
            check_and_install_dependencies
            install_xray_service
            ;;
        2)
            check_root
            check_and_install_dependencies
            install_bbr_warp
            ;;
        3)
            check_root
            uninstall_service
            ;;
        0)
            print_and_log "INFO" "脚本已退出。"
            exit 0
            ;;
        *)
            print_and_log "ERROR" "无效的选择，请输入0-3之间的数字。"
            sleep 3
            ;;
    esac
    
    echo -e "\n${CYAN}按任意键返回主菜单...${PLAIN}"
    read -n 1 -s
    main_menu
}

# --- Script Execution Starts Here ---

# Initial check for root, though not all functions might need it initially
# check_root

# Ensure log file can be written
touch "$LOG_FILE" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法写入日志文件 $LOG_FILE. 请检查权限.${PLAIN}"
    # Try to use a user-writable location as a fallback
    LOG_FILE_ALT="${HOME}/vps_script.log"
    touch "$LOG_FILE_ALT" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 也无法写入备用日志文件 $LOG_FILE_ALT. 日志功能将受限.${PLAIN}"
    else
        LOG_FILE="$LOG_FILE_ALT"
        echo -e "${YELLOW}警告: 使用备用日志文件: $LOG_FILE ${PLAIN}"
    fi
fi

print_and_log "INFO" "脚本启动 - 版本 $VERSION"

# Loop for the main menu
while true; do
    main_menu
doned
