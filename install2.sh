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
    . /etc/os-release
    ARCH=$(uname -m)
    VIRT=$(systemd-detect-virt)
}

install_package() {
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y "$1"
    elif command -v yum &> /dev/null; then
        yum install -y "$1"
    elif command -v apk &> /dev/null; then
        apk add "$1"
    else
        echo "未知的包管理器"
        return 1
    fi
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
      if mkdir -p -m 755 "${FLIE_PATH}"; then
        echo ""
      else 
        echo -e "${RED}权限不足，无法创建文件${PLAIN}"
      fi
    fi
    
    if [ -f "/tmp/list.log" ]; then
      rm -rf /tmp/list.log
    fi
    
    if [ -f "${FLIE_PATH}list.log" ]; then
      rm -rf ${FLIE_PATH}list.log
    fi

    install_config
    install_start
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
export TMP_ARGO='$TMP_ARGO'
export SERVER_PORT='$SERVER_PORT'
export SNI='www.apple.com'
export FLIE_PATH='$FLIE_PATH'
export CF_IP='$CF_IP'
export SUB_NAME='$SUB_NAME'
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

check_and_install_dependencies() {
    dependencies=("curl" "pgrep" "wget" "systemctl" "libcurl4")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -e "${YELLOW}$dep 命令未安装，将尝试安装...${PLAIN}"
            install_package "$dep"
            echo -e "${GREEN}$dep 命令已安装。${PLAIN}"
        fi
    done
    echo -e "${GREEN}所有依赖已经安装${PLAIN}"
    return 0
}

configure_startup() {
    check_and_install_dependencies
    if [ -s "${FLIE_PATH}start.sh" ]; then
        rm_naray
    fi
    install_config
    install_start

    if command -v systemctl &> /dev/null; then
        # 使用 systemd
        cat <<EOL > /etc/systemd/system/my_script.service
[Unit]
Description=My Startup Script

[Service]
ExecStart=${FLIE_PATH}start.sh
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOL
        systemctl enable my_script.service
        systemctl start my_script.service
    else
        # 使用 rc.local
        echo "${FLIE_PATH}start.sh" >> /etc/rc.local
        chmod +x /etc/rc.local
        nohup ${FLIE_PATH}start.sh 2>/dev/null 2>&1 &
    fi

    echo -e "${YELLOW}等待脚本启动...${PLAIN}"
    sleep 15
    check_process_and_log
}

check_process() {
    if command -v pgrep > /dev/null; then
        pgrep -f "$1" > /dev/null
    else
        ps aux | grep "$1" | grep -v grep > /dev/null
    fi
}

check_process_and_log() {
    keyword="$web_file"
    max_attempts=5
    counter=0

    while [ $counter -lt $max_attempts ]; do
        if check_process "$keyword" && [ -s /tmp/list.log ]; then
            echo -e "${CYAN}***************************************************${PLAIN}"
            echo "                          "
            echo -e "${GREEN}       脚本启动成功${PLAIN}"
            echo "                          "
            break
        else
            sleep 10
            ((counter++))
        fi
    done

    echo "                         "
    echo -e "${CYAN}************节点信息****************${PLAIN}"
    echo "                         "
    if [ -s "${FLIE_PATH}list.log" ]; then
        sed 's/{PASS}/vless/g' ${FLIE_PATH}list.log | cat
    elif [ -s "/tmp/list.log" ]; then
        sed 's/{PASS}/vless/g' /tmp/list.log | cat
    fi
    echo "                         "
    echo -e "${CYAN}***************************************************${PLAIN}"
}

start_menu2(){
    echo -e "${CYAN}>>>>>>>>请选择操作：${PLAIN}"
    echo "       "
    echo -e "${GREEN}       1. 开机启动(需要root)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       2. 临时启动(无需root)${PLAIN}"
    echo "       "
    echo -e "${GREEN}       0. 退出${PLAIN}"
    read choice

    case $choice in
        2)
            echo -e "${YELLOW}临时启动...${PLAIN}"
            install_config
            install_start
            nohup ${FLIE_PATH}start.sh 2>/dev/null 2>&1 &
            check_process_and_log
            ;;
        1)
            echo -e "${YELLOW}      添加到开机启动...${PLAIN}"
            configure_startup
            echo -e "${GREEN}      已添加到开机启动${PLAIN}"
            ;;
        0)
            exit 1
            ;;
        *)
            clear
            echo -e "${RED}错误:请输入正确数字 [0-2]${PLAIN}"
            sleep 5s
            start_menu2
            ;;
    esac
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
    service_name="my_script.service"
    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet $service_name; then
            echo -e "${YELLOW}服务 $service_name 仍处于活动状态。正在停止...${PLAIN}"
            systemctl stop $service_name
            echo -e "${GREEN}服务已停止。${PLAIN}"
        fi
        if systemctl is-enabled --quiet $service_name; then
            echo -e "${YELLOW}正在禁用 $service_name...${PLAIN}"
            systemctl disable $service_name
            echo -e "${GREEN}服务 $service_name 已禁用。${PLAIN}"
        fi
        if [ -f "/etc/systemd/system/$service_name" ]; then
            echo -e "${YELLOW}正在删除服务文件 /etc/systemd/system/$service_name...${PLAIN}"
            rm "/etc/systemd/system/$service_name"
            echo -e "${GREEN}服务文件已删除。${PLAIN}"
        elif [ -f "/lib/systemd/system/$service_name" ]; then
            echo -e "${YELLOW}正在删除服务文件 /lib/systemd/system/$service_name...${PLAIN}"
            rm "/lib/systemd/system/$service_name"
            echo -e "${GREEN}服务文件已删除。${PLAIN}"
        fi
        echo -e "${YELLOW}正在重新加载 systemd...${PLAIN}"
        systemctl daemon-reload
        echo -e "${GREEN}Systemd 已重新加载。${PLAIN}"
    else
        sed -i '\|${FLIE_PATH}start.sh|d' /etc/rc.local
    fi

    processes=("$web_file" "$ne_file" "$cff_file" "app" "app.js")
    for process in "${processes[@]}"
    do
        pkill -f "$process"
    done
}

start_menu1(){
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e "                          ${PURPLE}VPS 一键脚本隧道版${PLAIN}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}系统信息:${PLAIN} $PRETTY_NAME ($ARCH)"
echo -e " ${GREEN}虚拟化:${PLAIN} $VIRT"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
echo -e " ${GREEN}1.${PLAIN} 安装 ${YELLOW}X-R-A-Y${PLAIN}"
echo -e " ${GREEN}2.${PLAIN} 安装 ${YELLOW}BBR 加速${PLAIN}"
echo -e " ${GREEN}3.${PLAIN} 卸载 ${YELLOW}X-R-A-Y${PLAIN}"
echo -e " ${GREEN}0.${PLAIN} 退出脚本"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
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