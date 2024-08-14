#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

echo -e "${CYAN}=======vps一键脚本隧道版============${PLAIN}"
echo "                      "
echo "                      "

# 获取系统信息
get_system_info() {
    source /etc/os-release
    ARCH=$(uname -m)
    VIRT=$(systemd-detect-virt)
}

install_naray(){
    export ne_file=${ne_file:-'nenether.js'}
    export cff_file=${cff_file:-'cfnfph.js'}
    export web_file=${web_file:-'webssp.js'}
    # 设置其他参数
    if [[ $PWD == */ ]]; then
      FLIE_PATH="${FLIE_PATH:-${PWD}worlds/}"
    else
      FLIE_PATH="${FLIE_PATH:-${PWD}/worlds/}"
    fi
    if [ ! -d "${FLIE_PATH}" ]; then
      mkdir -p -m 755 "${FLIE_PATH}" 2>/dev/null
    fi
    rm -f /tmp/list.log 2>/dev/null
    rm -f ${FLIE_PATH}list.log 2>/dev/null

    # 函数：检查并安装依赖软件
    check_and_install_dependencies() {
        # 依赖软件列表
        dependencies=("curl" "wget" "pgrep" "systemctl" "libcurl4")

        # 检查并安装依赖软件
        for dep in "${dependencies[@]}"; do
            if ! command -v "$dep" &>/dev/null; then
                case "$linux_dist" in
                    "Alpine Linux")
                        apk update >/dev/null 2>&1
                        apk add "$dep" >/dev/null 2>&1
                        ;;
                    "Ubuntu" | "Debian" | "Kali Linux")
                        apt-get update >/dev/null 2>&1
                        apt-get install -y "$dep" >/dev/null 2>&1
                        ;;
                    "CentOS")
                        yum install -y "$dep" >/dev/null 2>&1
                        ;;
                esac
            fi
        done
    }

    install_config(){
        echo -e -n "${GREEN}请输入节点使用的协议，(可选vls,vms,rel,hys,默认vls):${PLAIN}"
        read TMP_ARGO
        export TMP_ARGO=${TMP_ARGO:-'vls'}  

        if [ "${TMP_ARGO}" = "rel" ] || [ "${TMP_ARGO}" = "hys" ]; then
            echo -e -n "${GREEN}请输入节点端口(默认443，注意nat鸡端口不要超过范围):${PLAIN}"
            read SERVER_PORT
            SERVER_POT=${SERVER_PORT:-"443"}
        fi

        echo -e -n "${GREEN}请输入节点上传地址: ${PLAIN}"
        read SUB_URL

        echo -e -n "${GREEN}请输入节点名称（默认值：vps）: ${PLAIN}"
        read SUB_NAME
        SUB_NAME=${SUB_NAME:-"vps"}

        echo -e -n "${GREEN}请输入 NEZHA_SERVER（不需要就不填）: ${PLAIN}"
        read NEZHA_SERVER

        echo -e -n "${GREEN}请输入 NEZHA_KEY (不需要就不填): ${PLAIN}"
        read NEZHA_KEY

        echo -e -n "${GREEN}请输入 NEZHA_PORT（默认值：443）: ${PLAIN}"
        read NEZHA_PORT
        NEZHA_PORT=${NEZHA_PORT:-"443"}

        echo -e -n "${GREEN}是否开启哪吒的tls（1开启,0关闭,默认开启）: ${PLAIN}"
        read NEZHA_TLS
        NEZHA_TLS=${NEZHA_TLS:-"1"}

        if [ "${TMP_ARGO}" = "vls" ] || [ "${TMP_ARGO}" = "vms" ]; then
            echo -e -n "${GREEN}请输入固定隧道token或者json(不填则使用临时隧道) : ${PLAIN}"
            read TOK
            echo -e -n "${GREEN}请输入隧道域名(设置固定隧道需要，临时隧道不需要) : ${PLAIN}"
            read ARGO_DOMAIN
            echo -e -n "${GREEN}请输入CF优选IP(默认ip.sb) : ${PLAIN}"
            read CF_IP
        fi
        CF_IP=${CF_IP:-"ip.sb"}
    }

    install_start(){
        cat <<EOL > ${FLIE_PATH}start.sh
#!/bin/bash
export TOK='$TOK'
export ARGO_DOMAIN='$ARGO_DOMAIN'
export NEZHA_SERVER='$NEZHA_SERVER'
export NEZHA_KEY='$NEZHA_KEY'
export NEZHA_PORT='$NEZHA_PORT'
export NEZHA_TLS='$NEZHA_TLS' 
export TMP_ARGO=${TMP_ARGO:-'vls'}
export SERVER_PORT="${SERVER_PORT:-${PORT:-443}}"
export SNI=${SNI:-'www.apple.com'}
export FLIE_PATH='$FLIE_PATH'
export CF_IP='$CF_IP'
export SUB_NAME='$SUB_NAME'
export SERVER_IP='$SERVER_IP'
export SUB_URL='$SUB_URL'
export ne_file='$ne_file'
export cff_file='$cff_file'
export web_file='$web_file'
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -sL"
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

        chmod +x ${FLIE_PATH}start.sh
    }

    # 函数：配置开机启动并立即启动
    configure_startup_and_run() {
        check_and_install_dependencies
        if [ -s "${FLIE_PATH}start.sh" ]; then
            rm_naray
        fi
        install_config
        install_start

        cat <<EOL > /etc/systemd/system/my_startup_script.service
[Unit]
Description=My Startup Script
After=network.target

[Service]
ExecStart=${FLIE_PATH}start.sh
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOL

        systemctl daemon-reload
        systemctl enable my_startup_script.service
        systemctl start my_startup_script.service

        echo -e "${YELLOW}等待脚本启动...${PLAIN}"
        sleep 15
        keyword="$web_file"
        max_attempts=5
        counter=0

        while [ $counter -lt $max_attempts ]; do
          if command -v pgrep > /dev/null && pgrep -f "$keyword" > /dev/null && [ -s /tmp/list.log ]; then
            echo -e "${GREEN}脚本启动成功${PLAIN}"
            break
          elif ps aux | grep "$keyword" | grep -v grep > /dev/null && [ -s /tmp/list.log ]; then
            echo -e "${GREEN}脚本启动成功${PLAIN}"
            break
          else
            sleep 10
            ((counter++))
          fi
        done

        echo -e "${CYAN}************节点信息****************${PLAIN}"
        if [ -s "${FLIE_PATH}list.log" ]; then
          sed 's/{PASS}/vless/g' ${FLIE_PATH}list.log | cat
        else
          if [ -s "/tmp/list.log" ]; then
            sed 's/{PASS}/vless/g' /tmp/list.log | cat
          fi
        fi
        echo -e "${CYAN}***************************************************${PLAIN}"
    }

    configure_startup_and_run
}

install_bbr(){
    if command -v curl &>/dev/null; then
        bash <(curl -sL https://git.io/kernel.sh)
    elif command -v wget &>/dev/null; then
       bash <(wget -qO- https://git.io/kernel.sh)
    else
        echo -e "${RED}错误: 未找到 curl 或 wget。请安装其中之一。${PLAIN}"
        sleep 30
    fi
}

rm_naray(){
    service_name="my_startup_script.service"
    if [ "$(systemctl is-active $service_name 2>/dev/null)" == "active" ]; then
        systemctl stop $service_name 2>/dev/null
    fi
    if [ "$(systemctl is-enabled $service_name 2>/dev/null)" == "enabled" ]; then
        systemctl disable $service_name 2>/dev/null
    fi
    rm -f "/etc/systemd/system/$service_name" 2>/dev/null
    rm -f "/lib/systemd/system/$service_name" 2>/dev/null
    systemctl daemon-reload 2>/dev/null

    processes=("$web_file" "$ne_file" "$cff_file" "app" "app.js")
    for process in "${processes[@]}"
    do
        pkill -f "$process" 2>/dev/null
    done
}

start_menu1(){
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e "${PURPLE}VPS 一键脚本隧道版${PLAIN}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}系统信息:${PLAIN} $PRETTY_NAME ($ARCH)"
echo -e " ${GREEN}虚拟化:${PLAIN} $VIRT"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}1.${PLAIN} 安装并启动 ${YELLOW}X-R-A-Y${PLAIN}"
echo -e " ${GREEN}2.${PLAIN} 安装 ${YELLOW}BBR 加速${PLAIN}"
echo -e " ${GREEN}3.${PLAIN} 卸载 ${YELLOW}X-R-A-Y${PLAIN}"
echo -e " ${GREEN}0.${PLAIN} 退出脚本"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
read -p " 请输入选择 [0-3]: " choice
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
	echo -e "${RED}请输入正确数字 [0-3]${PLAIN}"
	sleep 5s
	start_menu1
	;;
esac
}

# 在脚本开始时获取系统信息
get_system_info

# 启动主菜单
start_menu1
