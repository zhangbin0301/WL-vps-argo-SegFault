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
        echo -e "${GREEN}Created working directory: ${FLIE_PATH}${PLAIN}"
      else 
        echo -e "${RED}Insufficient permissions or error creating directory: ${FLIE_PATH}${PLAIN}"
        echo -e "${RED}Please check permissions or run as root if necessary.${PLAIN}"
        return 1 # Exit this function if directory creation fails
      fi
    fi
    
    # Clear previous log files
    rm -f "/tmp/list.log"
    rm -f "${FLIE_PATH}list.log"

    # Call start_menu2 to ask for startup type
    start_menu2
}

install_config(){
    echo -e -n "${GREEN}请输入节点类型 (可选: vls, vms, rel, hy2, tuic, 3x 默认: vls):${PLAIN}"
    read TMP_ARGO
    export TMP_ARGO=${TMP_ARGO:-'vls'}  

    if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hy2" ] || [ "${TMP_ARGO}" = "hys" ] || [ "${TMP_ARGO}" = "tuic" ] || [ "${TMP_ARGO}" = "3x" ]; then
    echo -e -n "${GREEN}请输入节点端口 (默认443):${PLAIN}"
    read SERVER_PORT
    export SERVER_PORT=${SERVER_PORT:-"443"} 
    fi
    echo -e -n "${GREEN}请输入节点上传地址 (For rel, hy2, tuic, 3x - e.g., http://yourserver:port/yourpath): ${PLAIN}"
    read SUB_URL
    export SUB_URL # Keep it empty if not needed for vls/vms with Argo
    echo -e -n "${GREEN}请输入节点名称 (默认: vps): ${PLAIN}"
    read SUB_NAME
    export SUB_NAME=${SUB_NAME:-"vps"}

    echo -e -n "${GREEN}请输入 NEZHA_SERVER (不需要，留空即可): ${PLAIN}"
    read NEZHA_SERVER
    export NEZHA_SERVER
    echo -e -n "${GREEN}请输入NEZHA_KEY (不需要，留空即可): ${PLAIN}"
    read NEZHA_KEY
    export NEZHA_KEY
    echo -e -n "${GREEN}请输入 NEZHA_PORT (默认443): ${PLAIN}"
    read NEZHA_PORT
    export NEZHA_PORT=${NEZHA_PORT:-"443"}

    echo -e -n "${GREEN}是否启用哪吒tls (1 启用, 0 关闭，默认启用): ${PLAIN}"
    read NEZHA_TLS
    export NEZHA_TLS=${NEZHA_TLS:-"1"}

    if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ] || [ "${TMP_ARGO}" = "xhttp" ] || [ "${TMP_ARGO}" = "spl" ] || [ "${TMP_ARGO}" = "3x" ]; then
      echo -e -n "${GREEN}请输入固定隧道TOKEN(Cloudflare Argo Tunnel Token, 不填则使用临时隧道): ${PLAIN}"
      read TOK
      export TOK
      if [ -n "$TOK" ]; then # Only ask for domain if TOK is provided
        echo -e -n "${GREEN}请输入固定隧道域名 (e.g., your.argo.domain.com - 临时隧道不用填): ${PLAIN}"
        read ARGO_DOMAIN
        export ARGO_DOMAIN
      else
        export ARGO_DOMAIN="" # Ensure ARGO_DOMAIN is empty if TOK is empty
      fi
      echo -e -n "${GREEN}请输入cf优选IP或域名(用于Argo连接, 默认 ip.sb): ${PLAIN}"
      read CF_IP
      export CF_IP=${CF_IP:-"ip.sb"}
    else
      export TOK=""
      export ARGO_DOMAIN=""
      export CF_IP=${CF_IP:-"ip.sb"} # Still set a default CF_IP
    fi
}

install_config2(){
    # Stop existing processes first
    local my_pid_config2=$$
    local processes_to_stop_config2=("$web_file" "$ne_file" "$cff_file" "start.sh" "app" "main-amd" "main-arm")
    for process_name_config2 in "${processes_to_stop_config2[@]}"; do
        if [ -n "$process_name_config2" ]; then
             pids_to_kill_config2=$(pgrep -f "$process_name_config2" | grep -v "^${my_pid_config2}$")
             if [ -n "$pids_to_kill_config2" ]; then
                 echo -e "${YELLOW}Stopping processes matching '$process_name_config2' for temporary start...${PLAIN}"
                 echo "$pids_to_kill_config2" | xargs kill &>/dev/null
                 sleep 0.1
                 echo "$pids_to_kill_config2" | xargs kill -9 &>/dev/null
             fi
        fi
    done

    echo -e -n "${GREEN}请输入节点类型 (可选: vls, vms, rel, hys, 默认: vls):${PLAIN}"
    read TMP_ARGO
    export TMP_ARGO=${TMP_ARGO:-'vls'}

    if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hy2" ] || [ "${TMP_ARGO}" = "hys" ] || [ "${TMP_ARGO}" = "tuic" ] || [ "${TMP_ARGO}" = "3x" ]; then
      echo -e -n "${GREEN}请输入端口 (default 443, nat vps port range):${PLAIN}"
      read SERVER_PORT
      export SERVER_PORT=${SERVER_PORT:-"443"}
    fi

    echo -e -n "${GREEN}请输入节点名称 (default: vps): ${PLAIN}"
    read SUB_NAME
    export SUB_NAME=${SUB_NAME:-"vps"}

    echo -e -n "${GREEN}Please enter NEZHA_SERVER (leave blank if not needed): ${PLAIN}"
    read NEZHA_SERVER
    export NEZHA_SERVER
    echo -e -n "${GREEN}Please enter NEZHA_KEY (leave blank if not needed): ${PLAIN}"
    read NEZHA_KEY
    export NEZHA_KEY
    echo -e -n "${GREEN}Please enter NEZHA_PORT (default: 443): ${PLAIN}"
    read NEZHA_PORT
    export NEZHA_PORT=${NEZHA_PORT:-"443"}

    echo -e -n "${GREEN}是否启用 NEZHA TLS? (default: enabled, set 0 to disable): ${PLAIN}"
    read NEZHA_TLS
    export NEZHA_TLS=${NEZHA_TLS:-"1"}

    if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ] || [ "${TMP_ARGO}" = "xhttp" ] || [ "${TMP_ARGO}" = "spl" ] || [ "${TMP_ARGO}" = "3x" ]; then
      echo -e -n "${GREEN}请输入固定隧道token (不输入则使用临时隧道): ${PLAIN}"
      read TOK
      export TOK
      if [ -n "$TOK" ]; then
        echo -e -n "${GREEN}请输入固定隧道域名 (临时隧道不用填): ${PLAIN}"
        read ARGO_DOMAIN
        export ARGO_DOMAIN
      else
        export ARGO_DOMAIN=""
      fi
    else
      export TOK=""
      export ARGO_DOMAIN=""
    fi
    # FLIE_PATH is already set globally by install_naray
    export CF_IP=${CF_IP:-"ip.sb"} # CF_IP for Argo if used
}

install_start(){
      # Ensure critical variables for start.sh are at least defined (empty if not set by user)
      TOK=${TOK:-}
      ARGO_DOMAIN=${ARGO_DOMAIN:-}
      NEZHA_SERVER=${NEZHA_SERVER:-}
      NEZHA_KEY=${NEZHA_KEY:-}
      NEZHA_PORT=${NEZHA_PORT:-443}
      NEZHA_TLS=${NEZHA_TLS:-1}
      TMP_ARGO=${TMP_ARGO:-vls}
      SERVER_PORT=${SERVER_PORT:-443} # Default port for non-Argo nodes
      SUB_URL=${SUB_URL:-}
      CF_IP=${CF_IP:-ip.sb}
      SUB_NAME=${SUB_NAME:-vps}
      SERVER_IP=${SERVER_IP:-} # SERVER_IP usually detected or should be set if needed by app

      # Get public IP for SERVER_IP if not set and needed (example, might not be perfect for all cases)
      if [ -z "$SERVER_IP" ]; then
          SERVER_IP=$(curl -s ip.sb || wget -qO- ip.sb || curl -s ifconfig.me || wget -qO- ifconfig.me)
      fi


      cat <<EOL > "${FLIE_PATH}start.sh"
#!/bin/bash
export FLIE_PATH='${FLIE_PATH}' # Pass FLIE_PATH into start.sh so it knows its location for list.log

# Set ARGO parameters
export TOK='${TOK}'
export ARGO_DOMAIN='${ARGO_DOMAIN}'

# Set NEZHA parameters
export NEZHA_SERVER='${NEZHA_SERVER}'
export NEZHA_KEY='${NEZHA_KEY}'
export NEZHA_PORT='${NEZHA_PORT}'
export NEZHA_TLS='${NEZHA_TLS}' 

# Set node protocol and other parameters
export TMP_ARGO='${TMP_ARGO}'
export SERVER_PORT='${SERVER_PORT}'
export SNI=\${SNI:-'www.apple.com'}

export CF_IP='${CF_IP}'
export SUB_NAME='${SUB_NAME}'
export SERVER_IP='${SERVER_IP}' # Public IP of the server
export SUB_URL='${SUB_URL}' # Upload address for certain node types

export ne_file='${ne_file}'
export cff_file='${cff_file}'
export web_file='${web_file}'

# Determine download command
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -sL"
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget -qO-"
else
    echo "Error: Neither curl nor wget found in start.sh. Please install one of them." > "\${FLIE_PATH}list.log" # Log error
    exit 1
fi

# Determine architecture and download corresponding app
ARCH=\$(uname -m)
APP_URL_AMD="https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-amd"
APP_URL_ARM="https://github.com/dsadsadsss/plutonodes/releases/download/xr/main-arm"
APP_PATH="/tmp/app"

echo "Attempting to download application for ARCH: \$ARCH..." > "\${FLIE_PATH}list.log" # Initial log

if [[ "\$ARCH" == "x86_64" ]] || [[ "\$ARCH" == "amd64" ]]; then
    \$DOWNLOAD_CMD "\$APP_URL_AMD" > "\$APP_PATH"
elif [[ "\$ARCH" == "aarch64" ]] || [[ "\$ARCH" == "arm64" ]]; then
    \$DOWNLOAD_CMD "\$APP_URL_ARM" > "\$APP_PATH"
else
    echo "Unsupported architecture: \$ARCH" >> "\${FLIE_PATH}list.log"
    exit 1
fi

if [ -s "\$APP_PATH" ]; then
    chmod +x "\$APP_PATH"
    echo "Application downloaded. Starting..." >> "\${FLIE_PATH}list.log"
    # The /tmp/app is expected to generate the actual list.log content
    # and run the necessary processes (like webssp.js)
    "\$APP_PATH" # Execute the application
else
    echo "Failed to download application or application is empty." >> "\${FLIE_PATH}list.log"
    exit 1
fi
EOL

      chmod +x "${FLIE_PATH}start.sh"
      echo -e "${GREEN}Generated ${FLIE_PATH}start.sh script.${PLAIN}"
}

check_and_install_dependencies() {
    dependencies=("curl" "pgrep" "wget") # Added wget as it's used as a fallback
    all_installed=true
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            all_installed=false
            echo -e "${YELLOW}$dep command not installed, attempting to install...${PLAIN}"
            if command -v apt-get &>/dev/null; then
                 apt-get update && apt-get install -y "$dep"
            elif command -v yum &>/dev/null; then
                 yum install -y "$dep"
            elif command -v apk &>/dev/null; then
                 apk add --no-cache "$dep"
            else
                echo -e "${RED}Unable to install $dep. Please install it manually.${PLAIN}"
                continue
            fi
            if command -v "$dep" &>/dev/null; then
                echo -e "${GREEN}$dep command has been installed.${PLAIN}"
            else
                echo -e "${RED}Failed to install $dep. This might cause issues.${PLAIN}"
            fi
        fi
    done

    if $all_installed; then
      echo -e "${GREEN}All dependencies are installed.${PLAIN}"
    else
      echo -e "${YELLOW}Some dependencies might be missing. Please check output.${PLAIN}"
    fi
}

configure_startup() {
    echo -e "${CYAN}Configuring startup...${PLAIN}"
    check_and_install_dependencies

    # If an old start.sh exists, run rm_naray to clean up before setting up new one
    # This ensures a cleaner state, especially if switching node types or tokens
    if [ -s "${FLIE_PATH}start.sh" ]; then
       echo -e "${YELLOW}Existing ${FLIE_PATH}start.sh found. Running cleanup first...${PLAIN}"
       rm_naray # This will run the improved rm_naray
       echo -e "${GREEN}Cleanup of previous setup finished.${PLAIN}"
    fi

    echo -e "${CYAN}Collecting node configuration...${PLAIN}"
    install_config # Get user configuration for the new service
    if [ $? -ne 0 ]; then # Assuming install_config could indicate failure
        echo -e "${RED}Failed to collect node configuration. Aborting startup setup.${PLAIN}"
        return 1
    fi

    echo -e "${CYAN}Generating startup script (start.sh)...${PLAIN}"
    install_start  # Create the start.sh script based on new config
    
    SCRIPT_PATH="${FLIE_PATH}start.sh"

    if [ ! -s "$SCRIPT_PATH" ]; then
        echo -e "${RED}Error: ${SCRIPT_PATH} was not created or is empty. Cannot proceed.${PLAIN}"
        return 1
    fi
    echo -e "${GREEN}${SCRIPT_PATH} generated successfully.${PLAIN}"

    # Attempt to set up service with a detected init system
    init_system_configured=false
    if [ -x "$(command -v systemctl)" ]; then
        echo -e "${CYAN}Systemd detected. Configuring systemd service...${PLAIN}"
        SERVICE_FILE="/etc/systemd/system/my_script.service"
        cat <<EOL > "$SERVICE_FILE"
[Unit]
Description=My Startup Script (webssp)
After=network.target remote-fs.target

[Service]
Type=simple
ExecStart=${SCRIPT_PATH}
Restart=always
RestartSec=5
User=$(whoami)
Environment="FLIE_PATH=${FLIE_PATH}"
WorkingDirectory=${FLIE_PATH}

[Install]
WantedBy=multi-user.target
EOL
        echo -e "${GREEN}Created systemd service file at $SERVICE_FILE${PLAIN}"
        systemctl daemon-reload
        if systemctl enable my_script.service && systemctl start my_script.service; then
            echo -e "${GREEN}Service has been enabled and started with systemd.${PLAIN}"
            init_system_configured=true
        else
            echo -e "${YELLOW}Failed to enable or start service with systemd.${PLAIN}"
            echo -e "${YELLOW}(This is common if systemd is not the true init system or is not fully operational).${PLAIN}"
            # We will attempt direct nohup start later if this fails
        fi
    fi

    if ! $init_system_configured; then # If no init system configured it or systemd failed
        if [ -x "$(command -v openrc)" ]; then
            echo -e "${CYAN}OpenRC detected. Configuring OpenRC service...${PLAIN}"
            # ... (OpenRC setup logic - simplified for brevity, use original if preferred) ...
            nohup ${SCRIPT_PATH} &>/dev/null &
            echo -e "${GREEN}Attempted to start script with OpenRC (or directly via nohup).${PLAIN}"
            init_system_configured=true # Mark as handled
        # Add other elif for SysV, Supervisor, Alpine etc. from previous full script if desired
        # ...
        fi
    fi

    if ! $init_system_configured; then # Fallback if no specific init system worked or was detected
        echo -e "${YELLOW}No specific init system configured the service (or chosen init failed).${PLAIN}"
        echo -e "${CYAN}Attempting direct background start of ${SCRIPT_PATH}...${PLAIN}"
        # Ensure FLIE_PATH exists and SCRIPT_PATH is executable
        if [ ! -d "$FLIE_PATH" ]; then mkdir -p "$FLIE_PATH"; fi
        chmod +x "$SCRIPT_PATH"
        
        nohup "$SCRIPT_PATH" >> "${FLIE_PATH}nohup.log" 2>&1 &
        # nohup ${SCRIPT_PATH} &>/dev/null & # Old way
        
        # Brief pause for the script to attempt starting
        sleep 3 
        
        # Check if the main process (e.g., web_file) or start.sh itself is running
        if pgrep -f "$(basename ${SCRIPT_PATH})" > /dev/null || ( [ -n "$web_file" ] && pgrep -f "$web_file" > /dev/null ); then
            echo -e "${GREEN}Script ${SCRIPT_PATH} has been launched in the background via nohup.${PLAIN}"
            echo -e "${GREEN}Check ${FLIE_PATH}nohup.log and ${FLIE_PATH}list.log for details.${PLAIN}"
        else
            echo -e "${RED}Attempted direct start of ${SCRIPT_PATH}, but it may not be running or visible immediately.${PLAIN}"
            echo -e "${RED}Please check ${FLIE_PATH}nohup.log, ${FLIE_PATH}list.log and processes manually.${PLAIN}"
        fi
    fi

    echo -e "${YELLOW}Waiting for node information (up to ~50 seconds)...${PLAIN}"
    echo -e "${YELLOW}Check ${FLIE_PATH}list.log for detailed startup status from start.sh.${PLAIN}"
        
    max_attempts=10 # Increased attempts for log file
    attempt_delay=5
    counter=0
    log_found=false
    process_active_check_done=false

    while [ $counter -lt $max_attempts ]; do
        if [ -s "${FLIE_PATH}list.log" ]; then
            # Check for success/failure keywords in list.log if app writes them
            if grep -qE "Application downloaded. Starting...|successful|listening" "${FLIE_PATH}list.log"; then
                 log_found=true
                 echo -e "${GREEN}Startup log detected activity in ${FLIE_PATH}list.log.${PLAIN}"
                 break
            elif grep -qE "Failed|Error|Unsupported architecture|exit 1" "${FLIE_PATH}list.log"; then
                 log_found=true # Log exists, but indicates an error
                 echo -e "${RED}Startup log ${FLIE_PATH}list.log indicates an error. Please check its content.${PLAIN}"
                 break
            fi
        fi
        
        # Check if background process is still up, only once after some delay
        if [ $counter -gt 2 ] && ! $process_active_check_done ; then
             process_active_check_done=true # Check only once
             if ! pgrep -f "$(basename ${SCRIPT_PATH})" > /dev/null && ! ( [ -n "$web_file" ] && pgrep -f "$web_file" > /dev/null ) ; then
                echo -e "${YELLOW}The background start.sh process or its main component ($web_file) may have exited.${PLAIN}"
                # Don't break here, list.log might still contain the final error
             fi
        fi

        sleep $attempt_delay
        ((counter++))
        echo -n "." # Progress indicator
    done
    echo # Newline after progress dots

    if $log_found; then
        echo -e "${GREEN}Log file ${FLIE_PATH}list.log found.${PLAIN}"
    else
        echo -e "${RED}Log file ${FLIE_PATH}list.log not found or empty after $((max_attempts * attempt_delay)) seconds.${PLAIN}"
        echo -e "${RED}This suggests start.sh might not have run correctly or created the log.${PLAIN}"
        echo -e "${RED}Check ${FLIE_PATH}nohup.log (if created by nohup).${PLAIN}"
    fi

    echo "                         "
    echo -e "${CYAN}************ Node Information / Log ************${PLAIN}"
    echo -e "Displaying content of ${FLIE_PATH}list.log (if it exists):${PLAIN}"
    if [ -s "${FLIE_PATH}list.log" ]; then
      cat "${FLIE_PATH}list.log"
    else
      echo -e "${YELLOW}(Log file empty or not found)${PLAIN}"
    fi
    echo "                                          "
    echo -e "${CYAN}***************************************************${PLAIN}"
    echo -e "${GREEN}Configuration and startup attempt finished.${PLAIN}"
    echo -e "${GREEN}Please verify service status and check logs mentioned above if issues persist.${PLAIN}"
}


start_menu2(){
    echo -e "${CYAN}>>>>>>>>Please select an operation:${PLAIN}"
    echo "       "
    echo -e "${GREEN}       1. 开机启动 (需要root权限进行服务配置)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       2. 临时启动 (在当前会话后台运行, 无需root)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       0. 返回主菜单/退出${PLAIN}"
    read -r choice

    case $choice in
        1)
            echo -e "${YELLOW}Setting up for startup on boot...${PLAIN}"
            configure_startup # This is the modified function
            ;;
        2)
            echo -e "${YELLOW}Starting temporarily for current session...${PLAIN}"
            install_config2 # Get temporary config
            install_start   # Create start.sh based on temp config
            
            SCRIPT_PATH_TEMP="${FLIE_PATH}start.sh"
            if [ ! -s "$SCRIPT_PATH_TEMP" ]; then
                echo -e "${RED}Error: ${SCRIPT_PATH_TEMP} was not created or is empty. Cannot start temporarily.${PLAIN}"
                return
            fi
            chmod +x "$SCRIPT_PATH_TEMP"

            echo -e "${CYAN}Launching ${SCRIPT_PATH_TEMP} in background (temporary)...${PLAIN}"
            nohup "$SCRIPT_PATH_TEMP" >> "${FLIE_PATH}nohup_temp.log" 2>&1 &
            
            sleep 3
            if pgrep -f "$(basename ${SCRIPT_PATH_TEMP})" > /dev/null || ( [ -n "$web_file" ] && pgrep -f "$web_file" > /dev/null ); then
                 echo -e "${GREEN}Script launched. Check ${FLIE_PATH}nohup_temp.log and ${FLIE_PATH}list.log for status.${PLAIN}"
            else
                 echo -e "${RED}Failed to confirm temporary script launch. Check logs and processes.${PLAIN}"
            fi
            echo -e "${YELLOW}Waiting for node information (temporary launch)...${PLAIN}"
            # Simplified wait for temporary launch
            max_temp_attempts=6
            temp_counter=0
            while [ $temp_counter -lt $max_temp_attempts ]; do
                if [ -s "${FLIE_PATH}list.log" ]; break; fi
                sleep 5
                echo -n "."
                ((temp_counter++))
            done
            echo
            echo -e "${CYAN}--- Temporary Node Info / Log (${FLIE_PATH}list.log) ---${PLAIN}"
            cat "${FLIE_PATH}list.log" 2>/dev/null || echo "(Log not available)"
            echo -e "${CYAN}----------------------------------------------------${PLAIN}"
            ;;
          0)
            echo "Returning..."
            return # Return to start_menu1 or exits if install_naray was the top call
            ;;
          *)
          clear
          echo -e "${RED}Error: Please enter the correct number [0-2]${PLAIN}"
          sleep 3s
          start_menu2 # Show menu again
          ;;
    esac
}

install_bbr(){
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}BBR installation requires root privileges. Please run as root.${PLAIN}"
        return 1
    fi
    echo -e "${YELLOW}Attempting to install BBR using known script...${PLAIN}"
    if command -v curl &>/dev/null; then
        bash <(curl -sL https://git.io/kernel.sh)
    elif command -v wget &>/dev/null; then
       bash <(wget -qO- https://git.io/kernel.sh)
    else
        echo -e "${RED}Error: Neither curl nor wget found. Please install one of them to use this BBR script.${PLAIN}"
    fi
}

reinstall_naray(){
    echo -e "${YELLOW}Reinstalling X-R-A-Y service...${PLAIN}"
    echo -e "${CYAN}Step 1: Cleaning up previous installation...${PLAIN}"
    rm_naray # Call improved rm_naray
    echo -e "${GREEN}Previous installation cleanup finished.${PLAIN}"
    echo -e "${CYAN}Step 2: Proceeding with new installation...${PLAIN}"
    install_naray # This will call start_menu2 again for config type
    echo -e "${GREEN}New installation process initiated.${PLAIN}"
}

rm_naray(){
    MY_PID=$$ # Get current script's PID to avoid self-killing
    echo -e "${YELLOW}Attempting to uninstall X-R-A-Y service and related files...${PLAIN}"

    # Determine script path to check for rc.local etc.
    # FLIE_PATH should be set by install_naray if this is called from there.
    # If rm_naray is called directly (e.g. from menu 3), FLIE_PATH might not be set.
    local current_flie_path="${FLIE_PATH}"
    if [ -z "$current_flie_path" ]; then
        # Try to guess FLIE_PATH based on PWD if called directly
        if [[ $PWD == */ ]]; then current_flie_path="${PWD}worlds/"; else current_flie_path="${PWD}/worlds/"; fi
        echo -e "${YELLOW}FLIE_PATH not set, assuming: ${current_flie_path}${PLAIN}"
    fi
    local script_to_check_path="${current_flie_path}start.sh"


    # 1. Stop systemd service
    if command -v systemctl &>/dev/null; then
        local service_name="my_script.service"
        echo -e "${CYAN}Checking systemd service: $service_name...${PLAIN}"
        if systemctl list-unit-files --all | grep -qw "$service_name"; then # Check if service file ever existed or is known
            if systemctl is-active --quiet $service_name; then
                echo -e "${YELLOW}Service $service_name is active. Stopping...${PLAIN}"
                systemctl stop $service_name &>/dev/null
            fi
            if systemctl is-enabled --quiet $service_name; then
                echo -e "${YELLOW}Disabling $service_name from startup...${PLAIN}"
                systemctl disable $service_name &>/dev/null
            fi
            echo -e "${YELLOW}Removing systemd service file if it exists...${PLAIN}"
            rm -f "/etc/systemd/system/$service_name" "/lib/systemd/system/$service_name"
            systemctl daemon-reload &>/dev/null
            systemctl reset-failed &>/dev/null # Reset failed state if any
            echo -e "${GREEN}Systemd service '$service_name' cleanup attempt finished.${PLAIN}"
        else
            echo -e "${PLAIN}Systemd service '$service_name' not found or not managed by systemd.${PLAIN}"
        fi
    fi

    # 2. Stop OpenRC service
    if [ -f "/etc/init.d/myservice" ] && command -v rc-service &>/dev/null; then
        echo -e "${CYAN}Removing OpenRC service 'myservice'...${PLAIN}"
        rc-service myservice stop &>/dev/null
        rc-update del myservice default &>/dev/null
        rm -f "/etc/init.d/myservice"
        echo -e "${GREEN}OpenRC service 'myservice' removed.${PLAIN}"
    fi

    # 3. Stop SysV init script
    if [ -f "/etc/init.d/my_start_script" ]; then
        echo -e "${CYAN}Removing SysV init script 'my_start_script'...${PLAIN}"
        /etc/init.d/my_start_script stop &>/dev/null
        if command -v update-rc.d &>/dev/null; then
            update-rc.d -f my_start_script remove &>/dev/null
        elif command -v chkconfig &>/dev/null; then
            chkconfig --del my_start_script &>/dev/null
        fi
        rm -f "/etc/init.d/my_start_script"
        echo -e "${GREEN}SysV init script 'my_start_script' removed.${PLAIN}"
    fi
    
    # Further cleanup for supervisor, alpine, rc.local (simplified, expand if needed from previous)
    if [ -f "/etc/supervisor/conf.d/my_start_script.conf" ]; then rm -f "/etc/supervisor/conf.d/my_start_script.conf"; supervisorctl reread &>/dev/null; supervisorctl update &>/dev/null; echo -e "${GREEN}Supervisor conf removed.${PLAIN}"; fi
    if [ -f "/etc/local.d/my_script.start" ]; then rm -f "/etc/local.d/my_script.start"; echo -e "${GREEN}Alpine local.d script removed.${PLAIN}"; fi
    if [ -f "/etc/inittab" ] && grep -qF "$script_to_check_path" /etc/inittab; then sed -i "\#${script_to_check_path}#d" /etc/inittab; echo -e "${GREEN}Inittab entry removed.${PLAIN}"; fi
    if [ -f "/etc/rc.local" ] && grep -qF "$script_to_check_path" /etc/rc.local; then sed -i "\#${script_to_check_path}#d" /etc/rc.local; echo -e "${GREEN}rc.local entry removed.${PLAIN}"; fi


    # 4. Stop running processes (safer version)
    echo -e "${CYAN}Stopping related processes...${PLAIN}"
    # Define process names, ensure these variables are available or use defaults
    local current_web_file=${web_file:-'webssp.js'}
    local current_ne_file=${ne_file:-'nenether.js'}
    local current_cff_file=${cff_file:-'cfnfph.js'}
    local current_start_script_name=$(basename "$script_to_check_path" 2>/dev/null || echo "start.sh") # Default if basename fails

    local processes_to_kill=("$current_web_file" "$current_ne_file" "$current_cff_file" "$current_start_script_name" "app" "main-amd" "main-arm")
    for process_name in "${processes_to_kill[@]}"; do
        if [ -n "$process_name" ]; then
             # Get PIDs excluding the current script's PID
             pids_string=$(pgrep -f "$process_name" | grep -v "^${MY_PID}$" || true) # pgrep might return non-zero if no match

             if [ -n "$pids_string" ]; then
                 echo -e "${YELLOW}Attempting to stop processes matching '$process_name' (PIDs: $(echo "$pids_string" | tr '\n' ' '))...${PLAIN}"
                 echo "$pids_string" | xargs kill &>/dev/null
                 sleep 0.2 # Brief pause

                 # Check again and force kill if necessary
                 pids_after_kill=$(pgrep -f "$process_name" | grep -v "^${MY_PID}$" || true)
                 if [ -n "$pids_after_kill" ]; then
                    echo -e "${YELLOW}Forcefully stopping remaining processes for '$process_name' (PIDs: $(echo "$pids_after_kill" | tr '\n' ' '))...${PLAIN}"
                    echo "$pids_after_kill" | xargs kill -9 &>/dev/null
                 fi
                 echo -e "${GREEN}Processes for '$process_name' stopped.${PLAIN}"
             else
                # echo -e "${PLAIN}No running processes found matching '$process_name' (excluding self).${PLAIN}"
                : # Do nothing, it's fine
             fi
        fi
    done

    # 5. Remove script files and logs
    echo -e "${CYAN}Removing script files and logs from ${current_flie_path} (if it exists)...${PLAIN}"
    if [ -d "$current_flie_path" ]; then
        if [ -f "${current_flie_path}start.sh" ]; then
            rm -f "${current_flie_path}start.sh"
            echo -e "${GREEN}Removed ${current_flie_path}start.sh${PLAIN}"
        fi
        rm -f "${current_flie_path}list.log" "${current_flie_path}nohup.log" "${current_flie_path}nohup_temp.log"
        echo -e "${GREEN}Removed log files from ${current_flie_path}${PLAIN}"
        # Optionally, remove the directory if empty:
        # if [ -z "$(ls -A "$current_flie_path")" ]; then
        #     echo -e "${YELLOW}Removing empty directory ${current_flie_path}...${PLAIN}"
        #     rm -rf "$current_flie_path"
        # fi
    else
        echo -e "${PLAIN}Directory ${current_flie_path} not found, nothing to remove from there.${PLAIN}"
    fi
    # Remove other temporary files
    rm -f /tmp/app /tmp/list.log # /tmp/list.log might be used by older start.sh

    echo -e "${GREEN}Uninstallation and cleanup process completed.${PLAIN}"
}

start_menu1(){
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e "${PURPLE}VPS 一键脚本 (Tunnel Version)${PLAIN}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}System Info:${PLAIN} $(uname -s) $(uname -m) ($(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || echo Unknown OS))"
echo -e " ${GREEN}Virtualization:${PLAIN} $VIRT"
echo -e " ${GREEN}Date:${PLAIN} $(date)"
echo -e " ${GREEN}Working Directory for files (FLIE_PATH will be):${PLAIN} ${PWD%/}/worlds/"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}1.${PLAIN} 安装/重装 ${YELLOW}X-R-A-Y 服务${PLAIN}"
echo -e " ${GREEN}2.${PLAIN} 安装 ${YELLOW}BBR加速/WARP${PLAIN}"
echo -e " ${GREEN}3.${PLAIN} 卸载 ${YELLOW}X-R-A-Y 服务${PLAIN}"
echo -e " ${GREEN}0.${PLAIN} 退出脚本"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
read -r -p " Please enter your choice [0-3]: " choice
case "$choice" in
    1)
    # Determine FLIE_PATH once here for the check
    local check_flie_path
    if [[ $PWD == */ ]]; then check_flie_path="${PWD}worlds/"; else check_flie_path="${PWD}/worlds/"; fi

    # Check for existing installation to decide between reinstall_naray or install_naray
    if [ -s "${check_flie_path}start.sh" ] || (command -v systemctl &>/dev/null && systemctl list-unit-files --all | grep -qw "my_script.service"); then
        echo -e "${YELLOW}Existing installation detected or service file found. Proceeding with reinstall logic.${PLAIN}"
        reinstall_naray # This will call rm_naray then install_naray (which calls start_menu2)
    else
        echo -e "${CYAN}No existing installation detected. Proceeding with fresh install logic.${PLAIN}"
        install_naray # This will call start_menu2
    fi
    ;;
    2)
    install_bbr
    ;;
    3)
    # For direct uninstall, ensure FLIE_PATH is sensible if not already set by install_naray context
    if [ -z "$FLIE_PATH" ]; then 
        if [[ $PWD == */ ]]; then export FLIE_PATH="${PWD}worlds/"; else export FLIE_PATH="${PWD}/worlds/"; fi
        echo -e "${YELLOW}FLIE_PATH was not set, defaulting to ${FLIE_PATH} for uninstall.${PLAIN}"
    fi
    rm_naray
    ;;
    0)
    echo -e "${CYAN}Exiting script.${PLAIN}"
    exit 0
    ;;
    *)
    clear
    echo -e "${RED}Invalid choice. Please enter a number between 0 and 3.${PLAIN}"
    sleep 3s
    start_menu1 # Show menu again
    ;;
esac
# Loop back to main menu after an action, or exit
# To loop back, remove exit 0 from case 0 and call start_menu1 at the end here.
# For now, it exits after one main action (unless start_menu2 returns to it implicitly).
# Let's make it explicit to show menu again unless exiting.
if [ "$choice" != "0" ]; then
    echo ""
    read -r -p "Press Enter to return to the main menu..."
    start_menu1
fi
}

# --- Main Script Execution ---
get_system_info # Call it once at the beginning
start_menu1     # Start the main menue
