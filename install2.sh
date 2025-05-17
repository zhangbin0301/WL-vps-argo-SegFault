#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

echo -e "${CYAN}=======VPS 一键脚本(Tunnel Version)============${PLAIN}"
echo "                      "
echo "                      "

# Get system information
get_system_info() {
    ARCH=$(uname -m)
    VIRT=$(systemd-detect-virt 2>/dev/null || echo "Unknown")
}

install_naray(){
    export ne_file=${ne_file:-'nenether.js'}
    export cff_file=${cff_file:-'cfnfph.js'}
    export web_file=${web_file:-'webssp.js'}
    
    # Set other parameters
    if [[ $PWD == */ ]]; then
      FLIE_PATH="${FLIE_PATH:-${PWD}worlds/}"
    else
      FLIE_PATH="${FLIE_PATH:-${PWD}/worlds/}"
    fi
    
    if [ ! -d "${FLIE_PATH}" ]; then
      if mkdir -p -m 755 "${FLIE_PATH}"; then
        echo ""
      else 
        echo -e "${RED}Insufficient permissions, unable to create file${PLAIN}"
      fi
    fi
    
    if [ -f "/tmp/list.log" ]; then
    rm -rf /tmp/list.log
    fi
    if [ -f "${FLIE_PATH}list.log" ]; then
    rm -rf ${FLIE_PATH}list.log
    fi

    install_config(){
        echo -e -n "${GREEN}请输入节点类型 (可选: vls, vms, rel, hy2, tuic,3x 默认: vls):${PLAIN}"
        read TMP_ARGO
        export TMP_ARGO=${TMP_ARGO:-'vls'}  

        if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hy2" ] || [ "${TMP_ARGO}" = "hys" ] || [ "${TMP_ARGO}" = "tuic" ] || [ "${TMP_ARGO}" = "3x" ]; then
        echo -e -n "${GREEN}请输入节点端口 (默认443):${PLAIN}"
        read SERVER_PORT
        SERVER_POT=${SERVER_PORT:-"443"} # Note: Typo SERVER_POT, should be SERVER_PORT if used later
        fi
        echo -e -n "${GREEN}请输入节点上传地址: ${PLAIN}"
        read SUB_URL
        echo -e -n "${GREEN}请输入节点名称 (默认: vps): ${PLAIN}"
        read SUB_NAME
        SUB_NAME=${SUB_NAME:-"vps"}

        echo -e -n "${GREEN}请输入 NEZHA_SERVER (不需要，留空即可): ${PLAIN}"
        read NEZHA_SERVER

        echo -e -n "${GREEN}请输入NEZHA_KEY (不需要，留空即可): ${PLAIN}"
        read NEZHA_KEY

        echo -e -n "${GREEN}请输入 NEZHA_PORT (默认443): ${PLAIN}"
        read NEZHA_PORT
        NEZHA_PORT=${NEZHA_PORT:-"443"}

        echo -e -n "${GREEN}是否启用哪吒tls (1 启用, 0 关闭，默认启用): ${PLAIN}"
        read NEZHA_TLS
        NEZHA_TLS=${NEZHA_TLS:-"1"}
        if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ] || [ "${TMP_ARGO}" = "xhttp" ] || [ "${TMP_ARGO}" = "spl" ] || [ "${TMP_ARGO}" = "3x" ]; then
        echo -e -n "${GREEN}请输入固定隧道TOKEN(不填，则使用临时隧道): ${PLAIN}"
        read TOK
        echo -e -n "${GREEN}请输入固定隧道域名 (临时隧道不用填): ${PLAIN}"
        read ARGO_DOMAIN
        echo -e -n "${GREEN}请输入cf优选IP或域名(默认 ip.sb): ${PLAIN}"
        read CF_IP
        fi
        CF_IP=${CF_IP:-"ip.sb"}
    }

    install_config2(){
        processes=("$web_file" "$ne_file" "$cff_file" "start.sh" "app")
for process in "${processes[@]}"
do
    pids=$(pgrep -f "$process")
    if [ -n "$pids" ]; then
        echo -e "${YELLOW}Stopping processes matching $process...${PLAIN}"
        for pid in $pids; do
            kill "$pid" &>/dev/null
        done
    fi
done
        echo -e -n "${GREEN}请输入节点类型 (可选: vls, vms, rel, hys, 默认: vls):${PLAIN}"
        read TMP_ARGO
        export TMP_ARGO=${TMP_ARGO:-'vls'}

        if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hy2" ] || [ "${TMP_ARGO}" = "hys" ] || [ "${TMP_ARGO}" = "tuic" ] || [ "${TMP_ARGO}" = "3x" ]; then
        echo -e -n "${GREEN}请输入端口 (default 443, note that nat chicken port should not exceed the range):${PLAIN}"
        read SERVER_PORT
        SERVER_POT=${SERVER_PORT:-"443"} # Note: Typo SERVER_POT, should be SERVER_PORT if used later
        fi

        echo -e -n "${GREEN}请输入节点名称 (default: vps): ${PLAIN}"
        read SUB_NAME
        SUB_NAME=${SUB_NAME:-"vps"}

        echo -e -n "${GREEN}Please enter NEZHA_SERVER (leave blank if not needed): ${PLAIN}"
        read NEZHA_SERVER

        echo -e -n "${GREEN}Please enter NEZHA_KEY (leave blank if not needed): ${PLAIN}"
        read NEZHA_KEY

        echo -e -n "${GREEN}Please enter NEZHA_PORT (default: 443): ${PLAIN}"
        read NEZHA_PORT
        NEZHA_PORT=${NEZHA_PORT:-"443"}

        echo -e -n "${GREEN}是否启用 NEZHA TLS? (default: enabled, set 0 to disable): ${PLAIN}"
        read NEZHA_TLS
        NEZHA_TLS=${NEZHA_TLS:-"1"}
        if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ] || [ "${TMP_ARGO}" = "xhttp" ] || [ "${TMP_ARGO}" = "spl" ] || [ "${TMP_ARGO}" = "3x" ]; then
        echo -e -n "${GREEN}请输入固定隧道token (不输入则使用临时隧道): ${PLAIN}"
        read TOK
        echo -e -n "${GREEN}请输入固定隧道域名 (临时隧道不用填): ${PLAIN}"
        read ARGO_DOMAIN
        fi
        FLIE_PATH="${FLIE_PATH:-/tmp/worlds/}" # Defaulting FLIE_PATH here if not set
        CF_IP=${CF_IP:-"ip.sb"}
    }

    install_start(){
      cat <<EOL > ${FLIE_PATH}start.sh
#!/bin/bash
## ===========================================Set parameters (delete or add # in front of those not needed)=============================================

# Set ARGO parameters (default uses temporary tunnel, remove # in front to set)
export TOK='$TOK'
export ARGO_DOMAIN='$ARGO_DOMAIN'

# Set NEZHA parameters (NEZHA_TLS='1' to enable TLS, set others to disable TLS)
export NEZHA_SERVER='$NEZHA_SERVER'
export NEZHA_KEY='$NEZHA_KEY'
export NEZHA_PORT='$NEZHA_PORT'
export NEZHA_TLS='$NEZHA_TLS' 

# Set node protocol and reality parameters (vls,vms,rel)
export TMP_ARGO=${TMP_ARGO:-'vls'}  # Set the protocol used by the node
export SERVER_PORT="${SERVER_PORT:-${PORT:-443}}" # IP address cannot be blocked, port cannot be occupied, so cannot open games simultaneously
export SNI=${SNI:-'www.apple.com'} # TLS website

# Set app parameters (default x-ra-y parameters, if you changed the download address, you need to modify UUID and VPATH)
export FLIE_PATH='$FLIE_PATH'
export CF_IP='$CF_IP'
export SUB_NAME='$SUB_NAME'
export SERVER_IP='$SERVER_IP'
## ===========================================Set x-ra-y download address (recommended to use default)===============================

export SUB_URL='$SUB_URL'
## ===================================
export ne_file='$ne_file'
export cff_file='$cff_file'
export web_file='$web_file'
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -sL"
# Check if wget is available
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget -qO-"
else
    echo "Error: Neither curl nor wget found. Please install one of them."
    sleep 30
    exit 1
fi
arch=\$(uname -m)
if [[ \$arch == "x86_64" ]]; then
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-amd > /tmp/app
else
    \$DOWNLOAD_CMD https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-arm > /tmp/app
fi

chmod 777 /tmp/app && /tmp/app
EOL

      # Give start.sh execution permissions
      chmod +x ${FLIE_PATH}start.sh
    }

    # Function: Check and install dependencies
    check_and_install_dependencies() {
        # List of dependencies
        dependencies=("curl" "pgrep" "pidof") # pidof might not be strictly necessary if pgrep is used

        # Check and install dependencies
        for dep in "${dependencies[@]}"; do
            if ! command -v "$dep" &>/dev/null; then
                echo -e "${YELLOW}$dep command not installed, attempting to install...${PLAIN}"
                if command -v apt-get &>/dev/null; then
                     apt-get update &&  apt-get install -y "$dep"
                elif command -v yum &>/dev/null; then
                     yum install -y "$dep"
                elif command -v apk &>/dev/null; then
                     apk add --no-cache "$dep"
                else
                    echo -e "${RED}Unable to install $dep. Please install it manually.${PLAIN}"
                    echo -e "${YELLOW}Continuing with the script...${PLAIN}"
                    continue # Continue even if a dependency fails to install
                fi
                if command -v "$dep" &>/dev/null; then
                    echo -e "${GREEN}$dep command has been installed.${PLAIN}"
                else
                    echo -e "${RED}Failed to install $dep. Continuing with the script...${PLAIN}"
                fi
            fi
        done

        echo -e "${GREEN}Dependency check completed${PLAIN}"
    }

    # Function: Configure startup (MODIFIED VERSION)
    configure_startup() {
        # Check and install dependencies
        check_and_install_dependencies
        if [ -s "${FLIE_PATH}start.sh" ]; then
           rm_naray # This will attempt to remove existing service before setting up a new one
        fi
        install_config # Get user configuration
        install_start  # Create the start.sh script
SCRIPT_PATH="${FLIE_PATH}start.sh" # Define SCRIPT_PATH

if [ -x "$(command -v systemctl)" ]; then
    echo "Systemd detected. Configuring systemd service..."

    # Create systemd service file
    cat <<EOL > /etc/systemd/system/my_script.service
[Unit]
Description=My Startup Script
After=network.target

[Service]
Type=forking # Assuming start.sh daemonizes or use 'simple' if it runs in foreground
ExecStart=${SCRIPT_PATH}
Restart=always
User=$(whoami) # Consider if this needs to be root or a specific user
#Environment="FLIE_PATH=${FLIE_PATH}" # Pass environment variables if start.sh needs them explicitly and doesn't source them

[Install]
WantedBy=multi-user.target
EOL

    systemctl daemon-reload
    # Attempt to enable and start the service with systemd
    if systemctl enable my_script.service && systemctl start my_script.service; then
        echo -e "${GREEN}Service has been added to systemd startup and started successfully.${PLAIN}"
    else
        echo -e "${YELLOW}Failed to enable or start service with systemd (this is common if systemd is not the init system or not fully operational).${PLAIN}"
        echo -e "${YELLOW}Attempting to directly start ${SCRIPT_PATH} in the background...${PLAIN}"
        nohup ${SCRIPT_PATH} &>/dev/null &
        # Check if the script is running (basic check)
        sleep 2 # Give it a moment to start
        if pgrep -f "$(basename ${SCRIPT_PATH})" > /dev/null || pgrep -f "${web_file}" > /dev/null ; then # Check start.sh or web_file
            echo -e "${GREEN}Attempted direct start of ${SCRIPT_PATH}. Script or its components appear to be running. Check logs or processes to confirm.${PLAIN}"
        else
            echo -e "${RED}Attempted direct start of ${SCRIPT_PATH}, but it may not be running or visible immediately. Please check manually.${PLAIN}"
        fi
    fi

elif [ -x "$(command -v openrc)" ]; then
    echo "OpenRC detected. Configuring startup script..."
   cat <<EOF > /etc/init.d/myservice
#!/sbin/openrc-run
command="${SCRIPT_PATH}"
pidfile="/var/run/myservice.pid" # Adjusted pidfile location
command_background=true

depend() {
    need net
}

start() {
    ebegin "Starting MyService"
    start-stop-daemon --start --exec \$command --make-pidfile --pidfile \$pidfile --background
    eend \$?
}

stop() {
    ebegin "Stopping MyService"
    start-stop-daemon --stop --pidfile \$pidfile
    eend \$?
}
EOF
chmod +x /etc/init.d/myservice
rc-update add myservice default
if rc-service myservice start; then
    echo -e "${GREEN}Startup script configured and started via OpenRC.${PLAIN}"
else
    echo -e "${YELLOW}Failed to start service with OpenRC. Attempting direct start of ${SCRIPT_PATH}...${PLAIN}"
    nohup ${SCRIPT_PATH} &>/dev/null &
    echo "Attempted direct start of ${SCRIPT_PATH} in background."
fi

elif [ -f "/etc/init.d/functions" ]; then # SysV init
    echo "SysV init detected. Configuring SysV init script..."

    cat <<EOF > /etc/init.d/my_start_script
#!/bin/sh
### BEGIN INIT INFO
# Provides:          my_start_script
# Required-Start:    \$remote_fs \$syslog \$network
# Required-Stop:     \$remote_fs \$syslog \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start my custom script at boot
# Description:       Enable service provided by my_start_script.
### END INIT INFO

SCRIPT_PATH="$SCRIPT_PATH"
LOCK_FILE="/var/lock/subsys/my_start_script" # Standard lock file location for SysV

start() {
    echo "Starting my custom startup script"
    nohup \$SCRIPT_PATH &>/dev/null &
    touch \$LOCK_FILE
}

stop() {
    echo "Stopping my custom startup script"
    # A more robust stop mechanism might be needed, e.g., finding PID
    pids=\$(pgrep -f "\$(basename \$SCRIPT_PATH)")
    [ -n "\$pids" ] && kill \$pids
    rm -f \$LOCK_FILE
}

case "\$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart}"
        exit 1
        ;;
esac
exit 0
EOF

    chmod +x /etc/init.d/my_start_script
    if command -v update-rc.d &>/dev/null; then
        update-rc.d my_start_script defaults
    elif command -v chkconfig &>/dev/null; then
        chkconfig --add my_start_script
        chkconfig my_start_script on
    fi
    echo "Startup script configured via SysV init."
    echo "Attempting to start it now..."
    /etc/init.d/my_start_script start

elif [ -d "/etc/supervisor/conf.d" ]; then
    echo "Supervisor detected. Configuring supervisor..."

    cat <<EOF > /etc/supervisor/conf.d/my_start_script.conf
[program:my_start_script]
command=${SCRIPT_PATH}
autostart=true
autorestart=true
stderr_logfile=/var/log/my_start_script.err.log
stdout_logfile=/var/log/my_start_script.out.log
user=$(whoami)
# Ensure FLIE_PATH is available if start.sh needs it
# environment=FLIE_PATH="${FLIE_PATH}"
EOF

    supervisorctl reread
    supervisorctl update
    if supervisorctl start my_start_script; then
      echo -e "${GREEN}Startup script configured and started via Supervisor.${PLAIN}"
    else
      echo -e "${RED}Failed to start script with Supervisor. Check supervisor logs.${PLAIN}"
    fi


elif grep -q -i "alpine" /etc/os-release 2>/dev/null; then # More robust Alpine check
    echo "Alpine Linux detected. Configuring /etc/inittab for startup script (requires OpenRC or local.d setup for modern Alpine)..."
    # Modern Alpine uses OpenRC, /etc/inittab is for very old systems or specific configurations.
    # A better approach for Alpine might be an OpenRC script or using /etc/local.d
    
    # Attempting /etc/local.d as a more modern Alpine approach
    if [ -d "/etc/local.d" ]; then
        cat <<EOF > /etc/local.d/my_script.start
#!/bin/sh
nohup ${SCRIPT_PATH} &>/dev/null &
EOF
        chmod +x /etc/local.d/my_script.start
        echo "Startup script added to /etc/local.d/my_script.start."
        echo "Attempting to start it now..."
        nohup ${SCRIPT_PATH} &>/dev/null &
    elif ! grep -q "$SCRIPT_PATH" /etc/inittab; then # Fallback to inittab if local.d doesn't exist
        echo "::respawn:${SCRIPT_PATH}" >> /etc/inittab # Use respawn for auto-restart
        echo "Startup script added to /etc/inittab. A reboot is usually required."
        # Starting it directly for current session
        nohup ${SCRIPT_PATH} &>/dev/null &
    else
        echo "Startup script already configured or /etc/local.d used."
        nohup ${SCRIPT_PATH} &>/dev/null &
    fi
    chmod +x $SCRIPT_PATH
    echo "Setup complete. For inittab changes, reboot system to test startup script if not using local.d."

else
    echo "No specific init system detected or systemd failed. Attempting to use /etc/rc.local or direct start..."

    if [ -f "/etc/rc.local" ]; then
        # Ensure rc.local is executable
        if [ ! -x "/etc/rc.local" ]; then
            chmod +x /etc/rc.local
        fi
        # Add script if not already present
        if ! grep -qF "$SCRIPT_PATH" /etc/rc.local; then # Use -F for fixed string grep
            # Add before 'exit 0' if it exists
            if grep -q '^exit 0' /etc/rc.local; then
                sed -i -e '$i'"nohup $SCRIPT_PATH &>/dev/null &\n" /etc/rc.local
            else
                echo "nohup $SCRIPT_PATH &>/dev/null &" >> /etc/rc.local
            fi
            echo "Startup script added to /etc/rc.local."
        else
            echo "Startup script already exists in /etc/rc.local."
        fi
    else
        echo "#!/bin/sh -e" > /etc/rc.local
        echo "nohup $SCRIPT_PATH &>/dev/null &" >> /etc/rc.local
        echo "exit 0" >> /etc/rc.local
        chmod +x /etc/rc.local
        echo "Created /etc/rc.local and added startup script."
    fi
    chmod +x $SCRIPT_PATH
    echo "Attempting direct start of ${SCRIPT_PATH} in background."
    nohup ${SCRIPT_PATH} &>/dev/null &
fi

        echo -e "${YELLOW}Waiting for the script to start (up to ~50 seconds)... If the wait time is too long, the judgment may be inaccurate. You can observe NEZHA to judge by yourself or try restarting.${PLAIN}"
        echo "等待节点信息......"
        
        max_attempts=5
        attempt_delay=10 # seconds
        counter=0
        log_found=false
        process_found=false

        # Wait for log file or process
        while [ $counter -lt $max_attempts ]; do
            if [ -s "${FLIE_PATH}list.log" ] || [ -s "/tmp/list.log" ]; then
                log_found=true
            fi
            if command -v pgrep >/dev/null && (pgrep -f "$(basename ${SCRIPT_PATH})" >/dev/null || pgrep -f "$web_file" >/dev/null); then
                process_found=true
            elif ps aux | grep -E "$(basename ${SCRIPT_PATH})|${web_file}" | grep -v grep > /dev/null; then
                process_found=true
            fi

            if ${log_found} && ${process_found}; then
                echo -e "${GREEN}Script started successfully (log and process detected).${PLAIN}"
                break
            elif ${log_found} && [ $counter -eq 0 ]; then # Log appeared quickly, give process a bit more time
                 echo -e "${YELLOW}Log file found, waiting for process to stabilize...${PLAIN}"
            elif ${process_found} && [ $counter -eq 0 ]; then # Process appeared quickly, give log file a bit more time
                 echo -e "${YELLOW}Process found, waiting for log file...${PLAIN}"
            fi
            
            sleep $attempt_delay
            ((counter++))
        done

        if ${log_found} && ${process_found} ; then
            echo -e "${CYAN}***************************************************${PLAIN}"
            echo "                          "
            echo -e "${GREEN}       Script started successfully${PLAIN}"
            echo "                          "
        elif ${log_found}; then
             echo -e "${YELLOW}Script log found, but main process (${web_file} or start.sh) not definitively detected by pgrep/ps. Please verify manually.${PLAIN}"
        elif ${process_found}; then
             echo -e "${YELLOW}Script process detected, but log file not found or empty. Please verify manually.${PLAIN}"
        else
            echo -e "${RED}Script may not have started successfully after $((max_attempts * attempt_delay)) seconds. Check logs in ${FLIE_PATH} or /tmp and process status.${PLAIN}"
        fi

        echo "                         "
        echo -e "${CYAN}************Node Information****************${PLAIN}"
        echo "                         "
        if [ -s "${FLIE_PATH}list.log" ]; then
          sed 's/{PASS}/vless/g' "${FLIE_PATH}list.log" | cat
        elif [ -s "/tmp/list.log" ]; then
            sed 's/{PASS}/vless/g' "/tmp/list.log" | cat
        else
            echo -e "${YELLOW}Node information log not found at ${FLIE_PATH}list.log or /tmp/list.log.${PLAIN}"
        fi
        echo "                         "
        echo -e "${CYAN}***************************************************${PLAIN}"
    }


    # Output menu for user to choose whether to start directly or add to startup and then start
    start_menu2(){
    echo -e "${CYAN}>>>>>>>>Please select an operation:${PLAIN}"
    echo "       "
    echo -e "${GREEN}       1. 开机启动 (需要root)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       2. 临时启动 (无需root)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       0. 退出${PLAIN}"
    read choice

    case $choice in
        2)
            # Temporary start
            echo -e "${YELLOW}Starting temporarily...${PLAIN}"
            install_config2
            install_start
            nohup ${FLIE_PATH}start.sh &>/dev/null & # Silenced nohup
    echo -e "${YELLOW}Waiting for start (up to ~50 seconds)... If wait time too long, you can reboot or check logs/processes.${PLAIN}"
    
    max_attempts=5
    attempt_delay=10 # seconds
    counter=0
    log_found=false
    process_found=false

    while [ $counter -lt $max_attempts ]; do
        if [ -s "${FLIE_PATH}list.log" ] || [ -s "/tmp/list.log" ]; then
            log_found=true
        fi
        # Check for start.sh or web_file
        if command -v pgrep >/dev/null && (pgrep -f "$(basename ${FLIE_PATH}start.sh)" >/dev/null || pgrep -f "$web_file" >/dev/null); then
            process_found=true
        elif ps aux | grep -E "$(basename ${FLIE_PATH}start.sh)|${web_file}" | grep -v grep > /dev/null; then
            process_found=true
        fi

        if ${log_found} && ${process_found}; break; fi
        sleep $attempt_delay
        ((counter++))
    done

    if ${log_found} && ${process_found} ; then
        echo -e "${CYAN}***************************************************${PLAIN}"
        echo "                          "
        echo -e "${GREEN}        Script started successfully${PLAIN}"
        echo "                          "
    else
        echo -e "${RED}Script may not have started successfully. Check logs in ${FLIE_PATH} or /tmp, and process status.${PLAIN}"
        if ${log_found}; then echo -e "${YELLOW}Log file was found.${PLAIN}"; fi
        if ${process_found}; then echo -e "${YELLOW}Process was detected.${PLAIN}"; fi
    fi
    
    echo "                         "
    echo -e "${CYAN}************Node Information******************${PLAIN}"
    echo "                         "
    if [ -s "${FLIE_PATH}list.log" ]; then
      sed 's/{PASS}/vless/g' "${FLIE_PATH}list.log" | cat
    elif [ -s "/tmp/list.log" ]; then
      sed 's/{PASS}/vless/g' "/tmp/list.log" | cat
    else
       echo -e "${YELLOW}Node information log not found.${PLAIN}"
    fi
    echo "                         "
    echo -e "${CYAN}***************************************************${PLAIN}"
            ;;
        1)
            # Add to startup and then start
            echo -e "${YELLOW}      Adding to startup...${PLAIN}"
            configure_startup # This is the modified function
            # configure_startup itself now handles printing success/failure.
            # echo -e "${GREEN}      Added to startup and attempted start.${PLAIN}" # Message handled within configure_startup
            ;;
          0)
            exit 0 # Changed from exit 1 to exit 0 for clean exit
            ;;
          *)
          clear
          echo -e "${RED}Error: Please enter the correct number [0-2]${PLAIN}"
          sleep 3s # Reduced sleep time
          start_menu2
          ;;
    esac
    }
    start_menu2
}

install_bbr(){
    # Ensure script is run as root for BBR installation
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}BBR installation requires root privileges. Please run as root.${PLAIN}"
        return 1
    fi
    if command -v curl &>/dev/null; then
        bash <(curl -sL https://git.io/kernel.sh)
    elif command -v wget &>/dev/null; then
       bash <(wget -qO- https://git.io/kernel.sh)
    else
        echo -e "${RED}Error: Neither curl nor wget found. Please install one of them.${PLAIN}"
        sleep 5 # Reduced sleep time
    fi
}

reinstall_naray(){
    echo -e "${YELLOW}Reinstalling X-R-A-Y service...${PLAIN}"
    # Stop existing service if it's managed by systemd (best effort)
    if command -v systemctl &>/dev/null && systemctl is-active my_script.service &>/dev/null; then
        echo -e "${YELLOW}Stopping existing systemd service...${PLAIN}"
        systemctl stop my_script.service &>/dev/null
    fi
    
    # Kill related processes (already part of rm_naray, but can be done here too for safety)
    processes=("$web_file" "$ne_file" "$cff_file" "start.sh" "app" "$(basename ${FLIE_PATH:-/tmp/worlds/}start.sh)")
    for process_name in "${processes[@]}"; do
        if [ -n "$process_name" ]; then # Ensure process_name is not empty
            pids=$(pgrep -f "$process_name")
            if [ -n "$pids" ]; then
                echo -e "${YELLOW}Stopping processes matching $process_name...${PLAIN}"
                for pid in $pids; do
                    kill "$pid" &>/dev/null
                done
            fi
        fi
    done
    # Call rm_naray to clean up old installations comprehensively
    rm_naray
    # Then proceed with new installation
    install_naray
    echo -e "${GREEN}Reinstallation process initiated.${PLAIN}"
}

rm_naray(){
    SCRIPT_PATH_TO_CHECK="${FLIE_PATH}start.sh" # Default path
    # If FLIE_PATH is not set (e.g. script run directly for uninstall), try a common default
    if [ -z "$FLIE_PATH" ] && [ -f "/tmp/worlds/start.sh" ]; then
      SCRIPT_PATH_TO_CHECK="/tmp/worlds/start.sh"
      FLIE_PATH="/tmp/worlds/" # Temporarily set for this function's logic
    elif [ -z "$FLIE_PATH" ] && [ -f "./worlds/start.sh" ]; then
      SCRIPT_PATH_TO_CHECK="./worlds/start.sh"
      FLIE_PATH="./worlds/"
    fi


    echo -e "${YELLOW}Attempting to uninstall X-R-A-Y service and related files...${PLAIN}"

    # Check for systemd
    if command -v systemctl &>/dev/null; then
        service_name="my_script.service"
        # Check if service exists before trying to stop/disable
        if systemctl list-unit-files | grep -qw "$service_name"; then
            if systemctl is-active --quiet $service_name; then
                echo -e "${YELLOW}Service $service_name is active. Stopping...${PLAIN}"
                systemctl stop $service_name &>/dev/null
            fi
            if systemctl is-enabled --quiet $service_name; then
                echo -e "${YELLOW}Disabling $service_name...${PLAIN}"
                systemctl disable $service_name &>/dev/null
            fi
            echo -e "${YELLOW}Removing service file if it exists...${PLAIN}"
            rm -f "/etc/systemd/system/$service_name"
            rm -f "/lib/systemd/system/$service_name" # Also check /lib
            systemctl daemon-reload &>/dev/null
            systemctl reset-failed &>/dev/null
            echo -e "${GREEN}Systemd service $service_name actions completed (if it existed).${PLAIN}"
        else
            echo -e "${PLAIN}Systemd service $service_name not found installed.${PLAIN}"
        fi
    fi

    # Check for OpenRC
    if [ -f "/etc/init.d/myservice" ]; then
        echo -e "${YELLOW}Removing OpenRC service...${PLAIN}"
        rc-service myservice stop &>/dev/null
        rc-update del myservice default &>/dev/null
        rm -f "/etc/init.d/myservice"
        echo -e "${GREEN}OpenRC service removed.${PLAIN}"
    fi

    # Check for SysV init
    if [ -f "/etc/init.d/my_start_script" ]; then
        echo -e "${YELLOW}Removing SysV init script...${PLAIN}"
        /etc/init.d/my_start_script stop &>/dev/null
        if command -v update-rc.d &>/dev/null; then
            update-rc.d -f my_start_script remove &>/dev/null
        elif command -v chkconfig &>/dev/null; then
            chkconfig --del my_start_script &>/dev/null
        fi
        rm -f "/etc/init.d/my_start_script"
        echo -e "${GREEN}SysV init script removed.${PLAIN}"
    fi

    # Check for Supervisor
    if [ -f "/etc/supervisor/conf.d/my_start_script.conf" ]; then
        echo -e "${YELLOW}Removing Supervisor configuration...${PLAIN}"
        supervisorctl stop my_start_script &>/dev/null
        rm -f "/etc/supervisor/conf.d/my_start_script.conf"
        supervisorctl reread &>/dev/null
        supervisorctl update &>/dev/null
        echo -e "${GREEN}Supervisor configuration removed.${PLAIN}"
    fi
    
    # Check for Alpine Linux local.d entry
    if [ -f "/etc/local.d/my_script.start" ]; then
        echo -e "${YELLOW}Removing startup entry from /etc/local.d/my_script.start...${PLAIN}"
        rm -f "/etc/local.d/my_script.start"
        echo -e "${GREEN}Startup entry removed from /etc/local.d.${PLAIN}"
    fi
    
    # Check for Alpine Linux inittab entry (less common now)
    if [ -f "/etc/inittab" ] && grep -qF "$SCRIPT_PATH_TO_CHECK" /etc/inittab; then # Use -F for fixed string
        echo -e "${YELLOW}Removing startup entry from /etc/inittab...${PLAIN}"
        sed -i "\#$SCRIPT_PATH_TO_CHECK#d" /etc/inittab # Use # as sed delimiter
        echo -e "${GREEN}Startup entry removed from /etc/inittab.${PLAIN}"
    fi
    
    # Check for rc.local entry
    if [ -f "/etc/rc.local" ] && grep -qF "$SCRIPT_PATH_TO_CHECK" /etc/rc.local; then # Use -F
        echo -e "${YELLOW}Removing startup entry from /etc/rc.local...${PLAIN}"
        sed -i "\#$SCRIPT_PATH_TO_CHECK#d" /etc/rc.local # Use # as sed delimiter
        echo -e "${GREEN}Startup entry removed from /etc/rc.local.${PLAIN}"
    fi

    # Stop running processes (more comprehensive list)
    # Ensure web_file, ne_file, cff_file are defined or provide defaults if rm_naray is called standalone
    local current_web_file=${web_file:-'webssp.js'}
    local current_ne_file=${ne_file:-'nenether.js'}
    local current_cff_file=${cff_file:-'cfnfph.js'}
    local current_start_script_name=$(basename "$SCRIPT_PATH_TO_CHECK")

    processes=("$current_web_file" "$current_ne_file" "$current_cff_file" "$current_start_script_name" "app" "main-amd" "main-arm")
    for process_name in "${processes[@]}"; do
        if [ -n "$process_name" ]; then
             pids=$(pgrep -f "$process_name")
             if [ -n "$pids" ]; then
                 echo -e "${YELLOW}Stopping processes matching $process_name (PIDs: $pids)...${PLAIN}"
                 for pid_val in $pids; do # Renamed pid to pid_val to avoid conflict if any script uses pid
                     kill "$pid_val" &>/dev/null
                 done
                 sleep 0.5 # Give a moment for processes to terminate
                 pids_after=$(pgrep -f "$process_name")
                 if [ -n "$pids_after" ]; then
                    echo -e "${YELLOW}Forcefully stopping remaining processes matching $process_name (PIDs: $pids_after)...${PLAIN}"
                    for pid_val in $pids_after; do
                        kill -9 "$pid_val" &>/dev/null
                    done
                 fi
             fi
        fi
    done
    
    # Remove script file and its directory if FLIE_PATH is defined
    if [ -n "$FLIE_PATH" ]; then
        if [ -f "${FLIE_PATH}start.sh" ]; then
            echo -e "${YELLOW}Removing startup script ${FLIE_PATH}start.sh...${PLAIN}"
            rm -f "${FLIE_PATH}start.sh"
            echo -e "${GREEN}Startup script removed.${PLAIN}"
        fi
        if [ -d "$FLIE_PATH" ]; then
             # Optionally remove the worlds directory if it's empty or if you're sure
             # For now, let's just remove known log files within it
             rm -f "${FLIE_PATH}list.log"
             # If you want to remove the directory:
             # if [ "$(ls -A $FLIE_PATH)" ]; then
             #    echo -e "${YELLOW}Directory ${FLIE_PATH} is not empty. Not removing.${PLAIN}"
             # else
             #    echo -e "${YELLOW}Removing directory ${FLIE_PATH}...${PLAIN}"
             #    rm -rf "$FLIE_PATH"
             #    echo -e "${GREEN}Directory ${FLIE_PATH} removed.${PLAIN}"
             # fi
        fi
    fi
    # Remove other temporary files
    rm -f /tmp/app /tmp/list.log

    echo -e "${GREEN}Uninstallation completed.${PLAIN}"
}
start_menu1(){
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e "${PURPLE}VPS 一键脚本 (Tunnel Version)${PLAIN}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}System Info:${PLAIN} $(uname -s) $(uname -m) ($(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || echo Unknown OS))" # More detailed OS
echo -e " ${GREEN}Virtualization:${PLAIN} $VIRT"
echo -e " ${GREEN}Date:${PLAIN} $(date)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}1.${PLAIN} 安装/重装 ${YELLOW}X-R-A-Y 服务${PLAIN}" # Clarified install/reinstall
echo -e " ${GREEN}2.${PLAIN} 安装 ${YELLOW}BBR加速/WARP${PLAIN}"
echo -e " ${GREEN}3.${PLAIN} 卸载 ${YELLOW}X-R-A-Y 服务${PLAIN}"
echo -e " ${GREEN}0.${PLAIN} 退出脚本"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
read -p " Please enter your choice [0-3]: " choice
case "$choice" in
    1)
    # Check if FLIE_PATH/start.sh exists to decide between fresh install or reinstall logic
    # For simplicity, current install_naray internally calls rm_naray if start.sh exists, acting as reinstall.
    # If you want separate logic, you'd add it here.
    # For now, option 1 leads to install_naray which handles both.
    # If you want a dedicated reinstall that first asks user or checks, use reinstall_naray here.
    # Let's assume option 1 is install/reinstall, so calling install_naray is fine.
    # To make it explicitly a reinstall if already installed:
    if [ -f "${FLIE_PATH}start.sh" ] || [ -f "/tmp/worlds/start.sh" ] || systemctl list-unit-files | grep -qw "my_script.service" ; then
        reinstall_naray
    else
        install_naray
    fi
    ;;
    2)
    install_bbr
    ;;
    3)
    rm_naray
    ;;
    0)
    exit 0
    ;;
    *)
    clear
    echo -e "${RED}Please enter the correct number [0-3]${PLAIN}"
    sleep 3s
    start_menu1
    ;;
esac
}

# --- Main Script Execution ---

# Get system information at the start of the script
get_system_info # Call it once at the beginning

# Start the main menu
start_menu1
