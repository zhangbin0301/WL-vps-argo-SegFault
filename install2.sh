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
VERSION="1.0.3" # Updated version

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
    
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        DISTRO="${ID}-${VERSION_ID}"
    else
        DISTRO="Unknown"
    fi
    
    # These will be displayed in the main menu
}

# Check and install dependencies
check_and_install_dependencies() {
    print_and_log "INFO" "正在检查依赖项..."
    dependencies=("curl" "wget" "pgrep" "pidof" "grep" "sed" "awk")
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_and_log "INFO" "需要安装的依赖项: ${missing_deps[*]}"
        if ! check_root; then
            print_and_log "ERROR" "安装依赖项需要root权限。请以root用户运行脚本。"
            return 1
        fi
        
        if command -v apt-get &>/dev/null; then
            print_and_log "INFO" "使用apt-get安装依赖项"
            apt-get update -qq
            apt-get install -y "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        elif command -v yum &>/dev/null; then
            print_and_log "INFO" "使用yum安装依赖项"
            yum install -y "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        elif command -v dnf &>/dev/null; then # CORRECTED LINE
            print_and_log "INFO" "使用dnf安装依赖项"
            dnf install -y "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        elif command -v apk &>/dev/null; then
            print_and_log "INFO" "使用apk安装依赖项"
            apk add --no-cache "${missing_deps[@]}" >> "$LOG_FILE" 2>&1
        else
            print_and_log "ERROR" "无法确定包管理器，请手动安装以下依赖项: ${missing_deps[*]}"
            return 1
        fi
        
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
    export ne_file=${ne_file:-'nenether.js'}
    export cff_file=${cff_file:-'cfnfph.js'}
    export web_file=${web_file:-'webssp.js'}
    
    if [[ "$PWD" == */ ]]; then
        FLIE_PATH="${FLIE_PATH:-${PWD}worlds/}"
    else
        FLIE_PATH="${FLIE_PATH:-${PWD}/worlds/}"
    fi
    
    # Ensure FLIE_PATH is an absolute path for service files
    if [[ "$FLIE_PATH" != /* ]]; then
        FLIE_PATH="$PWD/$FLIE_PATH"
    fi
    
    if [ ! -d "${FLIE_PATH}" ]; then
        print_and_log "INFO" "创建目录: ${FLIE_PATH}"
        if ! mkdir -p -m 755 "${FLIE_PATH}"; then
            print_and_log "ERROR" "创建目录失败，权限不足: ${FLIE_PATH}"
            print_and_log "INFO" "尝试在/tmp目录下创建备用目录"
            FLIE_PATH="/tmp/worlds/"
            if ! mkdir -p -m 755 "${FLIE_PATH}"; then
                print_and_log "ERROR" "创建备用目录失败: ${FLIE_PATH}. 请检查权限。"
                return 1
            fi
        fi
    fi
    
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
    
    echo -e -n "${GREEN}请输入节点类型 (可选: vls, vms, rel, hy2, tuic, 3x 默认: vls):${PLAIN}"
    read TMP_ARGO
    export TMP_ARGO=${TMP_ARGO:-'vls'}
    log_message "CONFIG" "节点类型: $TMP_ARGO"
    
    if [[ "$TMP_ARGO" == "rel" || "$TMP_ARGO" == "hy2" || "$TMP_ARGO" == "hys" || "$TMP_ARGO" == "tuic" || "$TMP_ARGO" == "3x" ]]; then
        echo -e -n "${GREEN}请输入节点端口 (默认443):${PLAIN}"
        read SERVER_PORT
        export SERVER_PORT=${SERVER_PORT:-"443"}
        log_message "CONFIG" "节点端口: $SERVER_PORT"
    fi
    
    echo -e -n "${GREEN}请输入节点上传地址 (例如: http://yourserver.com/upload_path): ${PLAIN}"
    read SUB_URL
    log_message "CONFIG" "节点上传地址: $SUB_URL"
    
    echo -e -n "${GREEN}请输入节点名称 (默认: vps): ${PLAIN}"
    read SUB_NAME
    export SUB_NAME=${SUB_NAME:-"vps"}
    log_message "CONFIG" "节点名称: $SUB_NAME"
    
    echo -e -n "${GREEN}请输入 NEZHA_SERVER (不需要，留空即可): ${PLAIN}"
    read NEZHA_SERVER
    log_message "CONFIG" "NEZHA_SERVER: $NEZHA_SERVER"
    
    echo -e -n "${GREEN}请输入NEZHA_KEY (不需要，留空即可): ${PLAIN}"
    read NEZHA_KEY
    log_message "CONFIG" "NEZHA_KEY: $NEZHA_KEY"
    
    echo -e -n "${GREEN}请输入 NEZHA_PORT (默认443): ${PLAIN}"
    read NEZHA_PORT
    export NEZHA_PORT=${NEZHA_PORT:-"443"}
    log_message "CONFIG" "NEZHA_PORT: $NEZHA_PORT"
    
    echo -e -n "${GREEN}是否启用哪吒tls (1 启用, 0 关闭，默认启用): ${PLAIN}"
    read NEZHA_TLS
    export NEZHA_TLS=${NEZHA_TLS:-"1"}
    log_message "CONFIG" "NEZHA_TLS: $NEZHA_TLS"
    
    if [[ "$TMP_ARGO" == "vls" || "$TMP_ARGO" == "vms" || "$TMP_ARGO" == "xhttp" || "$TMP_ARGO" == "spl" || "$TMP_ARGO" == "3x" ]]; then
        echo -e -n "${GREEN}请输入固定隧道TOKEN(不填，则使用临时隧道): ${PLAIN}"
        read TOK
        log_message "CONFIG" "隧道TOKEN: $TOK"
        
        echo -e -n "${GREEN}请输入固定隧道域名 (临时隧道不用填): ${PLAIN}"
        read ARGO_DOMAIN
        log_message "CONFIG" "隧道域名: $ARGO_DOMAIN"
        
        echo -e -n "${GREEN}请输入cf优选IP或域名(默认 ip.sb): ${PLAIN}"
        read CF_IP
    fi
    export CF_IP=${CF_IP:-"ip.sb"}
    log_message "CONFIG" "CF_IP: $CF_IP"
    
    SERVER_IP=$(curl -s4m8 ip.sb || curl -s6m8 ip.sb || hostname -I | awk '{print $1}')
    export SERVER_IP=${SERVER_IP:-"Unknown"}
    log_message "CONFIG" "服务器IP: $SERVER_IP"
    
    return 0
}

# Create startup script
create_startup_script() {
    local script_path="${FLIE_PATH}start.sh"
    print_and_log "INFO" "创建启动脚本: $script_path"
    
    # Ensure variables are escaped for the script heredoc
    local TOK_escaped=$(printf '%s\n' "$TOK" | sed "s/'/'\\\\''/g")
    local ARGO_DOMAIN_escaped=$(printf '%s\n' "$ARGO_DOMAIN" | sed "s/'/'\\\\''/g")
    local NEZHA_SERVER_escaped=$(printf '%s\n' "$NEZHA_SERVER" | sed "s/'/'\\\\''/g")
    local NEZHA_KEY_escaped=$(printf '%s\n' "$NEZHA_KEY" | sed "s/'/'\\\\''/g")
    local NEZHA_PORT_escaped=$(printf '%s\n' "$NEZHA_PORT" | sed "s/'/'\\\\''/g")
    local NEZHA_TLS_escaped=$(printf '%s\n' "$NEZHA_TLS" | sed "s/'/'\\\\''/g")
    local TMP_ARGO_escaped=$(printf '%s\n' "$TMP_ARGO" | sed "s/'/'\\\\''/g")
    local SERVER_PORT_escaped=$(printf '%s\n' "$SERVER_PORT" | sed "s/'/'\\\\''/g")
    local SNI_escaped=$(printf '%s\n' "${SNI:-'www.apple.com'}" | sed "s/'/'\\\\''/g")
    local FLIE_PATH_escaped=$(printf '%s\n' "$FLIE_PATH" | sed "s/'/'\\\\''/g")
    local CF_IP_escaped=$(printf '%s\n' "$CF_IP" | sed "s/'/'\\\\''/g")
    local SUB_NAME_escaped=$(printf '%s\n' "$SUB_NAME" | sed "s/'/'\\\\''/g")
    local SERVER_IP_escaped=$(printf '%s\n' "$SERVER_IP" | sed "s/'/'\\\\''/g")
    local SUB_URL_escaped=$(printf '%s\n' "$SUB_URL" | sed "s/'/'\\\\''/g")
    local ne_file_escaped=$(printf '%s\n' "$ne_file" | sed "s/'/'\\\\''/g")
    local cff_file_escaped=$(printf '%s\n' "$cff_file" | sed "s/'/'\\\\''/g")
    local web_file_escaped=$(printf '%s\n' "$web_file" | sed "s/'/'\\\\''/g")

    cat <<EOL > "$script_path"
#!/bin/bash
## ===========================================设置参数（删除或加入#即可切换是否使用）==========================================

# 设置固定隧道参数（默认使用临时隧道，去掉前面的注释#即可使用固定隧道）
export TOK='$TOK_escaped'
export ARGO_DOMAIN='$ARGO_DOMAIN_escaped'

# 设置哪吒监控参数（NEZHA_TLS='1'启用tls，设置为其他关闭tls）
export NEZHA_SERVER='$NEZHA_SERVER_escaped'
export NEZHA_KEY='$NEZHA_KEY_escaped'
export NEZHA_PORT='$NEZHA_PORT_escaped'
export NEZHA_TLS='$NEZHA_TLS_escaped'

# 设置节点协议与reality参数（vls,vms,rel）
export TMP_ARGO='${TMP_ARGO_escaped:-'vls'}'  # 设置节点使用的协议
export SERVER_PORT="${SERVER_PORT_escaped:-\${PORT:-443}}" # ip不能被墙，端口不能占用，不能开启防火墙
export SNI='${SNI_escaped:-'www.apple.com'}' # tls网站

# 设置app参数（默认x-ra-y参数，如更改了下载地址，则需要修改UUID和VPATH）
export FLIE_PATH='$FLIE_PATH_escaped'
export CF_IP='$CF_IP_escaped'
export SUB_NAME='$SUB_NAME_escaped'
export SERVER_IP='$SERVER_IP_escaped'
## ===========================================设置x-ra-y下载地址（建议使用默认）==========================================

export SUB_URL='$SUB_URL_escaped'
## ===================================
export ne_file='$ne_file_escaped'
export cff_file='$cff_file_escaped'
export web_file='$web_file_escaped'

# 创建日志文件目录（如果不存在）
mkdir -p "\$(dirname "\${FLIE_PATH}app.log")"

# 检测下载工具并设置下载命令
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -sL"
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget -qO-"
else
    echo "错误: 找不到curl或wget，请安装其中一个。" >> "\${FLIE_PATH}app.log"
    sleep 30
    exit 1
fi

# 根据架构选择正确的二进制文件
arch=\$(uname -m)
if [[ \$arch == "x86_64" ]]; then
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-amd > /tmp/app
elif [[ \$arch == "aarch64" || \$arch == "arm64" ]]; then
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-arm > /tmp/app
else
    echo "不支持的架构: \$arch" >> "\${FLIE_PATH}app.log"
    exit 1
fi

chmod 777 /tmp/app && /tmp/app >> "\${FLIE_PATH}app.log" 2>&1
EOL
    
    chmod +x "$script_path"
    if [ $? -ne 0 ]; then
        print_and_log "ERROR" "创建或设置启动脚本权限失败: $script_path"
        return 1
    fi
    
    print_and_log "INFO" "启动脚本创建成功: $script_path"
    return 0
}

# Configure system startup for the script
configure_system_startup() {
    local script_path="${FLIE_PATH}start.sh"
    print_and_log "INFO" "正在配置系统启动..."
    
    if ! check_root; then
        print_and_log "ERROR" "配置开机启动需要root权限"
        return 1
    fi
    
    # Ensure script path is absolute for service files
    if [[ "$script_path" != /* ]]; then
        script_path="$PWD/$script_path"
    fi

    local service_name="tunnel_node"
    local current_user=$(whoami)
    local run_log="${FLIE_PATH}run.log" # Define run_log here for broader scope
    
    if has_systemd; then
        print_and_log "INFO" "检测到systemd，配置systemd服务 ($service_name.service)..."
        cat <<EOL > /etc/systemd/system/${service_name}.service
[Unit]
Description=Tunnel Node Service by script
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${current_user}
ExecStart=${script_path}
WorkingDirectory=$(dirname "${script_path}")
Restart=always
RestartSec=10
StartLimitInterval=0
StandardOutput=append:${run_log}
StandardError=append:${run_log}

[Install]
WantedBy=multi-user.target
EOL
        systemctl daemon-reload
        systemctl enable ${service_name}.service
        systemctl restart ${service_name}.service
        if [ $? -ne 0 ]; then
            print_and_log "ERROR" "systemd服务 ($service_name.service) 启动失败。检查日志: journalctl -u ${service_name}.service 和 ${run_log}"
            return 1
        fi
        print_and_log "INFO" "systemd服务 ($service_name.service) 配置并启动成功。"
        
    elif command -v openrc &>/dev/null; then
        print_and_log "INFO" "检测到OpenRC，配置OpenRC服务 ($service_name)..."
        cat <<EOL > /etc/init.d/${service_name}
#!/sbin/openrc-run
name="Tunnel Node Service by script"
description="VPS Tunnel Node Service by script"
command="${script_path}"
command_user="${current_user}"
pidfile="/var/run/${service_name}.pid"
command_background=true
output_log="${run_log}"
error_log="${run_log}"

depend() {
    need net
    after firewall
}

start_pre() {
    checkpath -d -m 0755 -o \${command_user} "\$(dirname "\${output_log}")"
    checkpath -f -m 0644 -o \${command_user} "\${output_log}"
    checkpath -f -m 0644 -o \${command_user} "\${error_log}"
    checkpath -d -m 0755 -o \${command_user} "\$(dirname "\${pidfile}")"
}
EOL
        chmod +x /etc/init.d/${service_name}
        rc-update add ${service_name} default
        rc-service ${service_name} restart
        if [ $? -ne 0 ]; then
            print_and_log "ERROR" "OpenRC服务 ($service_name) 启动失败。检查日志: ${run_log}"
            return 1
        fi
        print_and_log "INFO" "OpenRC服务 ($service_name) 配置并启动成功。"

    elif [ -f "/etc/init.d/functions" ]; then
        print_and_log "INFO" "检测到SysV init，配置SysV服务 ($service_name)..."
        cat <<EOL > /etc/init.d/${service_name}
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ${service_name}
# Required-Start:    \$network \$local_fs
# Required-Stop:     \$network \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Tunnel Node Service by script
# Description:       VPS Tunnel Node Service by script
### END INIT INFO

# Source function library
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

SCRIPT="${script_path}"
RUNAS="${current_user}"
PIDFILE="/var/run/${service_name}.pid"
LOGFILE="${run_log}"
WORKDIR="\$(dirname "\${SCRIPT}")"

start() {
    if [ -f "\$PIDFILE" ] && kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo 'Service already running' >&2
        return 1
    fi
    echo 'Starting service...' >&2
    cd "\$WORKDIR" || exit 1
    su -s /bin/bash -c "nohup \$SCRIPT >> \$LOGFILE 2>&1 & echo \$! > \$PIDFILE" \$RUNAS
    # Basic check, might need refinement
    sleep 2
    if [ -f "\$PIDFILE" ] && kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo 'Service started' >&2; return 0
    else
        echo 'Service failed to start' >&2; return 1
    fi
}

stop() {
    if [ ! -f "\$PIDFILE" ] || ! kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo 'Service not running' >&2
        return 1
    fi
    echo 'Stopping service...' >&2
    kill -15 \$(cat "\$PIDFILE") && rm -f "\$PIDFILE"
    # Add kill -9 logic for stubborn processes if needed
    echo 'Service stopped' >&2
}

status() {
    if [ -f "\$PIDFILE" ] && kill -0 \$(cat "\$PIDFILE") 2>/dev/null; then
        echo "Service ($service_name) is running."
    else
        echo "Service ($service_name) is not running."
    fi
}

case "\$1" in
    start) start ;;
    stop) stop ;;
    status) status ;;
    restart) stop; sleep 1; start ;;
    *) echo "Usage: \$0 {start|stop|status|restart}"; exit 1 ;;
esac
exit 0
EOL
        chmod +x /etc/init.d/${service_name}
        if command -v update-rc.d &>/dev/null; then
            update-rc.d ${service_name} defaults
        elif command -v chkconfig &>/dev/null; then
            chkconfig --add ${service_name}
            chkconfig ${service_name} on
        else
            print_and_log "WARNING" "无法自动启用SysV服务，请手动配置。"
        fi
        /etc/init.d/${service_name} restart
        if [ $? -ne 0 ]; then
            print_and_log "ERROR" "SysV服务 ($service_name) 启动失败。检查日志: ${run_log}"
            return 1
        fi
        print_and_log "INFO" "SysV服务 ($service_name) 配置并启动成功。"

    elif grep -qi "alpine" /etc/os-release 2>/dev/null; then
        print_and_log "INFO" "检测到Alpine Linux，配置local.d启动 ($service_name.start)..."
        local alpine_script_path="/etc/local.d/${service_name}.start"
        cat <<EOL > "${alpine_script_path}"
#!/bin/sh
# Run as ${current_user} in the background, redirecting output
su -s /bin/sh -c 'cd \$(dirname "${script_path}") && nohup ${script_path} >> ${run_log} 2>&1 &' ${current_user}
EOL
        chmod +x "${alpine_script_path}"
        # Alpine's local.d scripts are typically started by the local service
        # We can try to start it directly for immediate effect
        if rc-service local status >/dev/null 2>&1 ; then
             rc-service local restart || print_and_log "WARNING" "无法重启 local 服务, 请手动启动或重启系统。"
        else
            sh "${alpine_script_path}" || print_and_log "ERROR" "Alpine脚本 (${alpine_script_path}) 启动失败。"
        fi
        print_and_log "INFO" "Alpine启动配置成功: ${alpine_script_path}。服务将随 'local' 服务启动。"

    else # Fallback to rc.local or similar
        print_and_log "WARNING" "未检测到标准初始化系统，尝试使用rc.local (兼容性较低)..."
        local rc_local_path="/etc/rc.local"
        local rc_entry="su -s /bin/bash -c 'cd \$(dirname \"${script_path}\") && nohup ${script_path} >> ${run_log} 2>&1 &' ${current_user}"

        if [ -f "${rc_local_path}" ]; then
            # Ensure rc.local is executable
            if [ ! -x "${rc_local_path}" ]; then
                chmod +x "${rc_local_path}"
            fi
            # Add entry if not present
            if ! grep -Fq "${script_path}" "${rc_local_path}"; then
                 # Remove 'exit 0' if it's the last line
                if grep -q "^exit 0" "${rc_local_path}"; then
                    sed -i '/^exit 0/d' "${rc_local_path}"
                fi
                echo "${rc_entry}" >> "${rc_local_path}"
                # Add 'exit 0' back if it was removed or wasn't there
                if ! tail -n1 "${rc_local_path}" | grep -q "exit 0"; then
                    echo "exit 0" >> "${rc_local_path}"
                fi
                print_and_log "INFO" "启动条目已添加到 ${rc_local_path}"
            else
                print_and_log "INFO" "启动条目已存在于 ${rc_local_path}"
            fi
        else # Create rc.local
            print_and_log "INFO" "创建 ${rc_local_path} 并添加启动条目"
            echo "#!/bin/sh -e" > "${rc_local_path}"
            echo "${rc_entry}" >> "${rc_local_path}"
            echo "exit 0" >> "${rc_local_path}"
            chmod +x "${rc_local_path}"
        fi
        # Attempt to run the script directly for immediate effect
        eval "${rc_entry}"
        print_and_log "INFO" "rc.local配置尝试完成。可能需要重启系统以确保生效。"
    fi
    
    return 0
}

# Start the service temporarily (without system startup)
start_temporary() {
    local script_path="${FLIE_PATH}start.sh"
    local run_log="${FLIE_PATH}run.log"
    print_and_log "INFO" "正在临时启动服务..."
    
    kill_existing_processes # Ensure no old instances are running
    
    # Create run log directory if it doesn't exist
    mkdir -p "$(dirname "$run_log")"

    nohup "$script_path" >> "$run_log" 2>&1 &
    
    if [ $? -ne 0 ]; then
        print_and_log "ERROR" "临时启动服务失败。检查日志: ${run_log}"
        return 1
    fi
    
    print_and_log "INFO" "服务已在后台启动。日志: ${run_log}"
    return 0
}

# Wait for service to initialize and display node information
wait_for_service() {
    print_and_log "INFO" "等待服务初始化 (最多60秒)..."
    local max_wait=60
    local counter=0
    local log_file=""
    
    while [ $counter -lt $max_wait ]; do
        if [ -f "${FLIE_PATH}list.log" ] && [ -s "${FLIE_PATH}list.log" ]; then
            log_file="${FLIE_PATH}list.log"
            break
        elif [ -f "/tmp/list.log" ] && [ -s "/tmp/list.log" ]; then # Fallback, though start.sh should use FLIE_PATH
            log_file="/tmp/list.log"
            break
        fi
        
        sleep 1
        ((counter++))
        
        if [ $((counter % 10)) -eq 0 ]; then
            echo -e "${YELLOW}等待服务启动... ${counter}s passed. (日志: ${FLIE_PATH}app.log, ${FLIE_PATH}run.log)${PLAIN}"
        fi
    done
    
    if [ -z "$log_file" ]; then
        print_and_log "ERROR" "服务未能在 $max_wait 秒内生成节点信息文件。"
        print_and_log "INFO" "请检查启动脚本日志: ${FLIE_PATH}app.log (应用自身日志) 和 ${FLIE_PATH}run.log (nohup/service日志)"
        return 1
    fi
    
    local is_running=false
    # Check common process names, adjust if necessary
    for process_keyword in "$web_file" "$ne_file" "$cff_file" "app" "main-amd" "main-arm"; do
        if pgrep -fl "$process_keyword" | grep -v -e "grep" -e "improved_install_script.sh" -e "start.sh" > /dev/null 2>&1; then
            print_and_log "INFO" "检测到进程运行: $(pgrep -fl "$process_keyword" | grep -v -e "grep" -e "improved_install_script.sh" -e "start.sh")"
            is_running=true
            break
        fi
    done
    
    if [ "$is_running" = true ]; then
        print_and_log "INFO" "服务已成功启动并检测到相关进程。"
        echo -e "${CYAN}************节点信息******************${PLAIN}"
        echo ""
        sed 's/{PASS}/vless/g' "$log_file" | cat
        echo ""
        echo -e "${CYAN}***************************************************${PLAIN}"
        return 0
    else
        print_and_log "ERROR" "节点信息文件已生成，但未检测到预期服务进程。"
        print_and_log "INFO" "请检查启动脚本日志: ${FLIE_PATH}app.log 和 ${FLIE_PATH}run.log"
        # Display node info anyway, as it might be partially working or processes named differently
        if [ -s "$log_file" ]; then
            echo -e "${CYAN}************节点信息 (可能不完整或服务未完全运行)******************${PLAIN}"
            sed 's/{PASS}/vless/g' "$log_file" | cat
            echo -e "${CYAN}***************************************************${PLAIN}"
        fi
        return 1
    fi
}

# Kill existing processes related to the script
kill_existing_processes() {
    print_and_log "INFO" "尝试清理与此脚本相关的现有进程..."
    
    # Process names/keywords used by start.sh and its components
    local processes_keywords=("$web_file" "$ne_file" "$cff_file" "start.sh" "/tmp/app" "main-amd" "main-arm")
    
    for keyword in "${processes_keywords[@]}"; do
        # Use pgrep to find PIDs. -f checks against full command line.
        # Exclude self (grep) and this installer script.
        local pids_to_kill=$(pgrep -fl "$keyword" | grep -v -e "grep" -e "improved_install_script.sh" | awk '{print $1}' | tr '\n' ' ')
        
        if [ -n "$pids_to_kill" ]; then
            print_and_log "INFO" "找到匹配 '$keyword' 的进程: $pids_to_kill. 尝试终止..."
            for pid in $pids_to_kill; do
                if kill -15 "$pid" >/dev/null 2>&1; then
                    print_and_log "INFO" "  SIGTERM sent to PID $pid."
                else
                    print_and_log "WARNING" "  Failed to send SIGTERM to PID $pid, or process already gone."
                fi
            done
            sleep 1 # Give a moment for graceful termination
            # Check again and force kill if necessary
            local still_running_pids=$(pgrep -fl "$keyword" | grep -v -e "grep" -e "improved_install_script.sh" | awk '{print $1}' | tr '\n' ' ')
             if [ -n "$still_running_pids" ]; then
                print_and_log "INFO" "  Still running after SIGTERM: $still_running_pids. Sending SIGKILL..."
                for pid_force in $still_running_pids; do
                    if kill -9 "$pid_force" >/dev/null 2>&1; then
                         print_and_log "INFO" "    SIGKILL sent to PID $pid_force."
                    else
                        print_and_log "WARNING" "    Failed to send SIGKILL to PID $pid_force, or process already gone."
                    fi
                done
            fi
        else
            print_and_log "INFO" "未找到匹配 '$keyword' 的正在运行的进程。"
        fi
    done
    
    print_and_log "INFO" "进程清理尝试完成。"
    return 0
}

# Uninstall the service and remove related files
uninstall_service() {
    print_and_log "INFO" "开始卸载服务和相关文件..."
    if ! check_root; then
        print_and_log "ERROR" "卸载服务需要root权限。"
        # Allow non-root to proceed with file cleanup if FLIE_PATH is user-writable
        if [ ! -w "$(dirname "$FLIE_PATH")" ]; then
             return 1
        fi
        print_and_log "WARNING" "将尝试清理用户可写目录下的文件。"
    fi

    local service_name="tunnel_node" # Service name used in configure_system_startup
    local script_path_to_remove="${FLIE_PATH}start.sh" # Main script to remove

    # 1. Stop and remove system services (requires root)
    if [ "$(id -u)" -eq 0 ]; then
        print_and_log "INFO" "停止并移除系统服务 (如果存在)..."
        if has_systemd; then
            if systemctl list-unit-files | grep -q "^${service_name}.service"; then
                print_and_log "INFO" "  处理 systemd 服务: $service_name"
                systemctl stop ${service_name}.service >/dev/null 2>&1
                systemctl disable ${service_name}.service >/dev/null 2>&1
                rm -f /etc/systemd/system/${service_name}.service
                rm -f /usr/lib/systemd/system/${service_name}.service # Also check here
                systemctl daemon-reload >/dev/null 2>&1
                print_and_log "INFO" "  Systemd 服务 ($service_name) 已停止、禁用并移除。"
            fi
        fi
        
        if [ -f "/etc/init.d/${service_name}" ]; then
            print_and_log "INFO" "  处理 SysV/OpenRC 服务: /etc/init.d/$service_name"
            # For OpenRC
            if command -v rc-update &>/dev/null; then
                rc-update del ${service_name} default >/dev/null 2>&1
            fi
            # For SysV
            if command -v update-rc.d &>/dev/null; then
                update-rc.d -f ${service_name} remove >/dev/null 2>&1
            elif command -v chkconfig &>/dev/null; then
                chkconfig --del ${service_name} >/dev/null 2>&1
            fi
            # Common stop and remove
            /etc/init.d/${service_name} stop >/dev/null 2>&1
            rm -f "/etc/init.d/${service_name}"
            print_and_log "INFO" "  SysV/OpenRC 服务 ($service_name) 已移除。"
        fi

        # Alpine specific
        local alpine_script="/etc/local.d/${service_name}.start"
        if [ -f "$alpine_script" ]; then
            print_and_log "INFO" "  移除 Alpine local.d 脚本: $alpine_script"
            rm -f "$alpine_script"
            # Consider stopping if 'local' service is manageable, though typically it runs scripts once
            print_and_log "INFO" "  Alpine local.d 脚本已移除。"
        fi

        # rc.local entry
        local rc_local_path="/etc/rc.local"
        if [ -f "$rc_local_path" ] && grep -Fq "$script_path_to_remove" "$rc_local_path"; then
            print_and_log "INFO" "  从 $rc_local_path 移除条目..."
            # Use a temporary file for sed to avoid issues with in-place editing on some systems
            sed "\#${script_path_to_remove}#d" "$rc_local_path" > "${rc_local_path}.tmp" && \
            mv "${rc_local_path}.tmp" "$rc_local_path"
            chmod +x "$rc_local_path" # Ensure it remains executable
            print_and_log "INFO" "  已从 $rc_local_path 移除条目。"
        fi
    else
        print_and_log "WARNING" "非root用户，跳过系统服务移除步骤。"
    fi

    # 2. Kill any running processes (best effort)
    kill_existing_processes

    # 3. Remove script files and directories
    print_and_log "INFO" "移除相关文件和目录..."
    if [ -f "$script_path_to_remove" ]; then
        print_and_log "INFO" "  移除启动脚本: $script_path_to_remove"
        rm -f "$script_path_to_remove"
    fi
    
    # Remove the entire FLIE_PATH directory if it seems safe (e.g., it's 'worlds' or in /tmp)
    # Be cautious with `rm -rf`
    if [[ "$FLIE_PATH" == *"worlds/"* || "$FLIE_PATH" == *"/tmp/"* ]]; then
        if [ -d "$FLIE_PATH" ]; then
            print_and_log "INFO" "  移除工作目录: $FLIE_PATH"
            rm -rf "$FLIE_PATH"
            if [ $? -eq 0 ]; then
                 print_and_log "INFO" "  工作目录已成功移除。"
            else
                 print_and_log "ERROR" "  移除工作目录失败: $FLIE_PATH"
            fi
        fi
    else
        print_and_log "WARNING" "工作目录 ($FLIE_PATH) 未自动删除，请手动检查。"
    fi

    # Clean /tmp/app if it exists
    if [ -f "/tmp/app" ]; then
        print_and_log "INFO" "  移除 /tmp/app"
        rm -f "/tmp/app"
    fi
    
    # Clean temporary log files if they exist outside FLIE_PATH
    if [ -f "/tmp/list.log" ]; then
        rm -f "/tmp/list.log"
    fi

    print_and_log "INFO" "卸载过程完成。"
    return 0
}

# Install BBR (external script)
install_bbr() {
    print_and_log "INFO" "开始安装BBR..."
    if ! check_root; then
        print_and_log "ERROR" "安装BBR需要root权限。"
        return 1
    fi
    
    local bbr_script_url="https://git.io/kernel.sh" # From install2.sh
    
    if command -v curl &>/dev/null; then
        bash <(curl -sL "$bbr_script_url")
    elif command -v wget &>/dev/null; then
        bash <(wget -qO- "$bbr_script_url")
    else
        print_and_log "ERROR" "安装BBR失败: curl和wget都未找到。"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        print_and_log "INFO" "BBR安装脚本执行完毕。请根据脚本提示操作，可能需要重启。"
    else
        print_and_log "ERROR" "BBR安装脚本执行失败。"
    fi
    return 0
}


# Function to handle X-R-A-Y installation process
process_install_xray() {
    if ! init_config_vars; then return 1; fi
    if ! get_user_config; then return 1; fi
    if ! create_startup_script; then return 1; fi

    echo -e "${CYAN}>>>>>>>>请选择启动方式:${PLAIN}"
    echo ""
    echo -e "${GREEN}       1. 设置开机启动 (推荐, 需要root)${PLAIN}"
    echo -e "${GREEN}       2. 临时启动 (无需root, 重启后失效)${PLAIN}"
    echo ""
    echo -e "${GREEN}       0. 返回主菜单${PLAIN}"
    read -p "请输入选项 [0-2]: " launch_choice

    case "$launch_choice" in
        1)
            print_and_log "INFO" "选择: 设置开机启动"
            if ! configure_system_startup; then
                print_and_log "ERROR" "开机启动配置失败。"
                return 1
            fi
            wait_for_service
            ;;
        2)
            print_and_log "INFO" "选择: 临时启动"
            if ! start_temporary; then
                print_and_log "ERROR" "临时启动失败。"
                return 1
            fi
            wait_for_service
            ;;
        0)
            print_and_log "INFO" "返回主菜单..."
            return 0
            ;;
        *)
            print_and_log "ERROR" "无效选项: $launch_choice"
            return 1
            ;;
    esac
}


# Main menu
main_menu() {
    get_system_info # Populate VIRT, OS_TYPE etc.
    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e "${PURPLE} VPS 一键脚本 (Tunnel Version) -改进版 v${VERSION}${PLAIN}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e " ${GREEN}系统信息:${PLAIN} $OS_TYPE $ARCH ($KERNEL) - $DISTRO"
    echo -e " ${GREEN}虚拟化:${PLAIN} $VIRT"
    echo -e " ${GREEN}当前用户:${PLAIN} $(whoami)"
    echo -e " ${GREEN}脚本日志:${PLAIN} $LOG_FILE"
    echo -e " ${GREEN}工作目录:${PLAIN} $FLIE_PATH (如果已初始化)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e " ${GREEN}1.${PLAIN} 安装/重新配置 ${YELLOW}X-R-A-Y 服务${PLAIN}"
    echo -e " ${GREEN}2.${PLAIN} 安装 ${YELLOW}BBR和WARP (外部脚本)${PLAIN}"
    echo -e " ${GREEN}3.${PLAIN} 卸载 ${YELLOW}X-R-A-Y 服务${PLAIN}"
    echo -e " ${GREEN}4.${PLAIN} 查看服务状态/日志 (如果已配置)${PLAIN}"
    echo -e " ${GREEN}5.${PLAIN} 手动清理所有相关进程${PLAIN}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    read -p " 请输入您的选择 [0-5]: " choice

    case "$choice" in
        1)
            print_and_log "INFO" "选择: 安装/重新配置 X-R-A-Y 服务"
            check_and_install_dependencies || return 1 # Exit if deps fail critical check
            process_install_xray
            ;;
        2)
            print_and_log "INFO" "选择: 安装 BBR和WARP"
            check_and_install_dependencies || return 1
            install_bbr
            ;;
        3)
            print_and_log "INFO" "选择: 卸载 X-R-A-Y 服务"
            # No need for full dep check here, but core utils like rm, sed, pgrep are assumed by uninstall
            uninstall_service
            ;;
        4)
            print_and_log "INFO" "选择: 查看服务状态/日志"
            local service_name="tunnel_node"
            local run_log="${FLIE_PATH}run.log"
            local app_log="${FLIE_PATH}app.log"
            local list_log="${FLIE_PATH}list.log"

            if [ "$(id -u)" -eq 0 ] && has_systemd && systemctl list-unit-files | grep -q "^${service_name}.service"; then
                systemctl status ${service_name}.service
                echo -e "${YELLOW}查看详细日志: journalctl -u ${service_name}.service -n 50 --no-pager ${PLAIN}"
            elif [ "$(id -u)" -eq 0 ] && [ -f "/etc/init.d/${service_name}" ]; then
                 /etc/init.d/${service_name} status
            fi
            echo -e "${YELLOW}应用进程检查 (关键字: app, $web_file, $ne_file, $cff_file):${PLAIN}"
            pgrep -afl "app\|$web_file\|$ne_file\|$cff_file" | grep -v -e "grep" -e "improved_install_script.sh" || echo "  未找到相关应用进程."
            
            if [ -f "$run_log" ]; then
                echo -e "${YELLOW}查看服务运行日志 (最后20行): tail -n 20 $run_log ${PLAIN}"
            else
                echo -e "${YELLOW}服务运行日志 ($run_log) 未找到.${PLAIN}"
            fi
             if [ -f "$app_log" ]; then
                echo -e "${YELLOW}查看应用内部日志 (最后20行): tail -n 20 $app_log ${PLAIN}"
            else
                echo -e "${YELLOW}应用内部日志 ($app_log) 未找到.${PLAIN}"
            fi
            if [ -f "$list_log" ]; then
                echo -e "${YELLOW}查看节点信息文件: cat $list_log ${PLAIN}"
            else
                echo -e "${YELLOW}节点信息文件 ($list_log) 未找到.${PLAIN}"
            fi
            ;;
        5)
            print_and_log "INFO" "选择: 手动清理所有相关进程"
            kill_existing_processes
            ;;
        0)
            print_and_log "INFO" "退出脚本。"
            exit 0
            ;;
        *)
            print_and_log "ERROR" "无效选项，请输入0-5之间的数字。"
            ;;
    esac
    echo ""
    read -p "按 Enter键 返回主菜单..."
    main_menu # Loop back to menu
}

# --- Script Entry Point ---
# Initialize FLIE_PATH early for menu display
if [[ "$PWD" == */ ]]; then FLIE_PATH="${FLIE_PATH:-${PWD}worlds/}"; else FLIE_PATH="${FLIE_PATH:-${PWD}/worlds/}"; fi
if [[ "$FLIE_PATH" != /* ]]; then FLIE_PATH="$PWD/$FLIE_PATH"; fi

main_menu
