#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

echo -e "${CYAN}=======VPS One-Click Script (Tunnel Version)============${PLAIN}"
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
        echo -e -n "${GREEN}Please enter the protocol used by the node (options: vls, vms, rel, hys, default: vls):${PLAIN}"
        read TMP_ARGO
        export TMP_ARGO=${TMP_ARGO:-'vls'}  

        if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hys" ]; then
        echo -e -n "${GREEN}Please enter the node port (default 443, note that nat chicken port should not exceed the range):${PLAIN}"
        read SERVER_PORT
        SERVER_POT=${SERVER_PORT:-"443"}
        fi

        echo -e -n "${GREEN}Please enter the node upload address: ${PLAIN}"
        read SUB_URL

        echo -e -n "${GREEN}Please enter the node name (default: vps): ${PLAIN}"
        read SUB_NAME
        SUB_NAME=${SUB_NAME:-"vps"}

        echo -e -n "${GREEN}Please enter NEZHA_SERVER (leave blank if not needed): ${PLAIN}"
        read NEZHA_SERVER

        echo -e -n "${GREEN}Please enter NEZHA_KEY (leave blank if not needed): ${PLAIN}"
        read NEZHA_KEY

        echo -e -n "${GREEN}Please enter NEZHA_PORT (default: 443): ${PLAIN}"
        read NEZHA_PORT
        NEZHA_PORT=${NEZHA_PORT:-"443"}

        echo -e -n "${GREEN}Enable NEZHA TLS? (1 to enable, 0 to disable, default: 1): ${PLAIN}"
        read NEZHA_TLS
        NEZHA_TLS=${NEZHA_TLS:-"1"}
        if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ]; then
        echo -e -n "${GREEN}Please enter fixed tunnel token or JSON (leave blank for temporary tunnel): ${PLAIN}"
        read TOK
        echo -e -n "${GREEN}Please enter tunnel domain (required for fixed tunnel, not for temporary): ${PLAIN}"
        read ARGO_DOMAIN
        echo -e -n "${GREEN}Please enter CF optimized IP (default: ip.sb): ${PLAIN}"
        read CF_IP
        fi
        CF_IP=${CF_IP:-"ip.sb"}
    }

    install_config2(){
        processes=("$web_file" "$ne_file" "$cff_file" "app" "app.js")
        for process in "${processes[@]}"
        do
            pid=$(pgrep -f "$process")

            if [ -n "$pid" ]; then
                kill "$pid" &>/dev/null
            fi
        done
        echo -e -n "${GREEN}Please enter the protocol used by the node (options: vls, vms, rel, hys, default: vls):${PLAIN}"
        read TMP_ARGO
        export TMP_ARGO=${TMP_ARGO:-'vls'}

        if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hys" ]; then
        echo -e -n "${GREEN}Please enter the node port (default 443, note that nat chicken port should not exceed the range):${PLAIN}"
        read SERVER_PORT
        SERVER_POT=${SERVER_PORT:-"443"}
        fi

        echo -e -n "${GREEN}Please enter the node name (default: vps): ${PLAIN}"
        read SUB_NAME
        SUB_NAME=${SUB_NAME:-"vps"}

        echo -e -n "${GREEN}Please enter NEZHA_SERVER (leave blank if not needed): ${PLAIN}"
        read NEZHA_SERVER

        echo -e -n "${GREEN}Please enter NEZHA_KEY (leave blank if not needed): ${PLAIN}"
        read NEZHA_KEY

        echo -e -n "${GREEN}Please enter NEZHA_PORT (default: 443): ${PLAIN}"
        read NEZHA_PORT
        NEZHA_PORT=${NEZHA_PORT:-"443"}

        echo -e -n "${GREEN}Enable NEZHA TLS? (default: enabled, set 0 to disable): ${PLAIN}"
        read NEZHA_TLS
        NEZHA_TLS=${NEZHA_TLS:-"1"}
        if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ]; then
        echo -e -n "${GREEN}Please enter fixed tunnel token or JSON (leave blank for temporary tunnel): ${PLAIN}"
        read TOK
        echo -e -n "${GREEN}Please enter tunnel domain (required for fixed tunnel, not for temporary): ${PLAIN}"
        read ARGO_DOMAIN
        fi
        FLIE_PATH="${FLIE_PATH:-/tmp/worlds/}"
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
        dependencies=("curl" "pgrep" "pidof")

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
                    continue
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

    # Function: Configure startup
    configure_startup() {
        # Check and install dependencies
        check_and_install_dependencies
        if [ -s "${FLIE_PATH}start.sh" ]; then
           rm_naray
        fi
        install_config
        install_start

        # Create systemd service file
        cat <<EOL > /tmp/my_script.service
[Unit]
Description=My Startup Script

[Service]
ExecStart=${FLIE_PATH}start.sh
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOL

        # Move service file to system directory and enable
if command -v systemctl &>/dev/null; then
    mv /tmp/my_script.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable my_script.service
    systemctl start my_script.service
    echo -e "${GREEN}Service has been added to systemd startup.${PLAIN}"
else
   echo "#!/bin/bash" > /etc/rc.local
   echo "${FLIE_PATH}start.sh" >> /etc/rc.local
    chmod +x /etc/rc.local
    echo -e "${GREEN}Script has been added to rc.local for startup.${PLAIN}"
    nohup ${FLIE_PATH}start.sh &
fi


        echo -e "${YELLOW}Waiting for the script to start... If the wait time is too long, the judgment may be inaccurate. You can observe NEZHA to judge by yourself or try restarting.${PLAIN}"
        sleep 15
        keyword="$web_file"
        max_attempts=5
        counter=0

        while [ $counter -lt $max_attempts ]; do
          if command -v pgrep > /dev/null && pgrep -f "$keyword" > /dev/null && [ -s /tmp/list.log ]; then
            echo -e "${CYAN}***************************************************${PLAIN}"
            echo "                          "
            echo -e "${GREEN}       Script started successfully${PLAIN}"
            echo "                          "
            break
          elif ps aux | grep "$keyword" | grep -v grep > /dev/null && [ -s /tmp/list.log ]; then
            echo -e "${CYAN}***************************************************${PLAIN}"
            echo "                          "
            echo -e "${GREEN}        Script started successfully${PLAIN}"
            echo "                          "
            break
          else
            sleep 10
            ((counter++))
          fi
        done

        echo "                         "
        echo -e "${CYAN}************Node Information****************${PLAIN}"
        echo "                         "
        if [ -s "${FLIE_PATH}list.log" ]; then
          sed 's/{PASS}/vless/g' ${FLIE_PATH}list.log | cat
        else
          if [ -s "/tmp/list.log" ]; then
            sed 's/{PASS}/vless/g' /tmp/list.log | cat
          fi
        fi
        echo "                         "
        echo -e "${CYAN}***************************************************${PLAIN}"
    }

    # Output menu for user to choose whether to start directly or add to startup and then start
    start_menu2(){
    echo -e "${CYAN}>>>>>>>>Please select an operation:${PLAIN}"
    echo "       "
    echo -e "${GREEN}       1. Add to startup (requires root)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       2. Temporary start (no root required)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       0. Exit${PLAIN}"
    read choice

    case $choice in
        2)
            # Temporary start
            echo -e "${YELLOW}Starting temporarily...${PLAIN}"
            install_config2
            install_start
            nohup ${FLIE_PATH}start.sh 2>/dev/null 2>&1 &
    echo -e "${YELLOW}Waiting for the script to start... If the wait time is too long, the judgment may be inaccurate. You can observe NEZHA to judge by yourself.${PLAIN}"
    sleep 15
    keyword="$web_file"
    max_attempts=5
    counter=0

    while [ $counter -lt $max_attempts ]; do
      if command -v pgrep > /dev/null && pgrep -f "$keyword" > /dev/null && [ -s /tmp/list.log ]; then
        echo -e "${CYAN}***************************************************${PLAIN}"
        echo "                          "
        echo -e "${GREEN}        Script started successfully${PLAIN}"
        echo "                          "
        break
      elif ps aux | grep "$keyword" | grep -v grep > /dev/null && [ -s /tmp/list.log ]; then
        echo -e "${CYAN}***************************************************${PLAIN}"
        echo "                          "
        echo -e "${GREEN}       Script started successfully${PLAIN}"
        echo "                          "
        
        break
      else
        sleep 10
        ((counter++))
      fi
    done

    echo "                         "
    echo -e "${CYAN}************Node Information******************${PLAIN}"
    echo "                         "
    if [ -s "${FLIE_PATH}list.log" ]; then
      sed 's/{PASS}/vless/g' ${FLIE_PATH}list.log | cat
    else
      if [ -s "/tmp/list.log" ]; then
        sed 's/{PASS}/vless/g' /tmp/list.log | cat
      fi
    fi
    echo "                         "
    echo -e "${CYAN}***************************************************${PLAIN}"
            ;;
        1)
            # Add to startup and then start
            echo -e "${YELLOW}      Adding to startup...${PLAIN}"
            configure_startup
            echo -e "${GREEN}      Added to startup${PLAIN}"
            ;;
          0)
            exit 1
            ;;
          *)
          clear
          echo -e "${RED}Error: Please enter the correct number [0-2]${PLAIN}"
          sleep 5s
          start_menu2
          ;;
    esac
    }
    start_menu2
}

install_bbr(){
    if command -v curl &>/dev/null; then
        bash <(curl -sL https://git.io/kernel.sh)
    elif command -v wget &>/dev/null; then
       bash <(wget -qO- https://git.io/kernel.sh)
    else
        echo -e "${RED}Error: Neither curl nor wget found. Please install one of them.${PLAIN}"
        sleep 30
    fi
}

reinstall_naray(){
    if command -v systemctl &>/dev/null && systemctl is-active my_script.service &>/dev/null; then
        systemctl stop my_script.service
        echo -e "${GREEN}Service has been stopped.${PLAIN}"
    fi
    processes=("$web_file" "$ne_file" "$cff_file" "app" "app.js")
    for process in "${processes[@]}"
    do
        pid=$(pgrep -f "$process")

        if [ -n "$pid" ]; then
            kill "$pid"  &>/dev/null
        fi
    done

    install_naray
}

rm_naray(){
    # Service name
    service_name="my_script.service"

    # Check if systemd is available
    if command -v systemctl &>/dev/null; then
        # Check if the service is active
        if systemctl is-active --quiet $service_name; then
            echo -e "${YELLOW}Service $service_name is still active. Stopping...${PLAIN}"
             systemctl stop $service_name
            echo -e "${GREEN}Service has been stopped.${PLAIN}"
        fi

        # Check if the service is enabled
        if systemctl is-enabled --quiet $service_name; then
            echo -e "${YELLOW}Disabling $service_name...${PLAIN}"
             systemctl disable $service_name
            echo -e "${GREEN}Service $service_name has been disabled.${PLAIN}"
        fi

        # Remove the service file
        if [ -f "/etc/systemd/system/$service_name" ]; then
            echo -e "${YELLOW}Removing service file /etc/systemd/system/$service_name...${PLAIN}"
             rm "/etc/systemd/system/$service_name"
            echo -e "${GREEN}Service file has been removed.${PLAIN}"
        elif [ -f "/lib/systemd/system/$service_name" ]; then
            echo -e "${YELLOW}Removing service file /lib/systemd/system/$service_name...${PLAIN}"
             rm "/lib/systemd/system/$service_name"
            echo -e "${GREEN}Service file has been removed.${PLAIN}"
        else
            echo -e "${YELLOW}Service file not found in /etc/systemd/system/ or /lib/systemd/system/.${PLAIN}"
        fi

        # Reload systemd
        echo -e "${YELLOW}Reloading systemd...${PLAIN}"
         systemctl daemon-reload
        echo -e "${GREEN}Systemd has been reloaded.${PLAIN}"
    else
        # If systemd is not available, remove from rc.local
        if grep -q "${FLIE_PATH}start.sh" /etc/rc.local; then
            echo -e "${YELLOW}Removing startup entry from /etc/rc.local...${PLAIN}"
             sed -i "\#${FLIE_PATH}start.sh#d" /etc/rc.local
            echo -e "${GREEN}Startup entry has been removed from /etc/rc.local.${PLAIN}"
        else
            echo -e "${YELLOW}Startup entry not found in /etc/rc.local.${PLAIN}"
        fi
    fi

    processes=("$web_file" "$ne_file" "$cff_file" "app" "app.js")
    for process in "${processes[@]}"
    do
        pid=$(pgrep -f "$process")

        if [ -n "$pid" ]; then
            kill "$pid"  &>/dev/null
        fi
    done

    echo -e "${GREEN}Uninstallation completed.${PLAIN}"
}

start_menu1(){
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e "${PURPLE}VPS One-Click Script (Tunnel Version)${PLAIN}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}System Info:${PLAIN} $(uname -s) $(uname -m)"
echo -e " ${GREEN}Virtualization:${PLAIN} $VIRT"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}1.${PLAIN} Install ${YELLOW}X-R-A-Y${PLAIN}"
echo -e " ${GREEN}2.${PLAIN} Install ${YELLOW}BBR Acceleration${PLAIN}"
echo -e " ${GREEN}3.${PLAIN} Uninstall ${YELLOW}X-R-A-Y${PLAIN}"
echo -e " ${GREEN}0.${PLAIN} Exit Script"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
read -p " Please enter your choice [0-3]: " choice
case "$choice" in
    1)
    install_naray
    ;;
    2)
    install_bbr
    ;;
    3)
    rm_naray
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    echo -e "${RED}Please enter the correct number [0-3]${PLAIN}"
    sleep 5s
    start_menu1
    ;;
esac
}

# Get system information at the start of the script
get_system_info

# Start the main menu
start_menu1