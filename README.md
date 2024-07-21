# vps-Argo一键脚本

声明：本仓库仅为自用备份，不适合别人使用，非开源项目，请勿擅自使用与传播，否则责任自负。

vps纯隧道专用版

支持临时启动模式，适合测试用，重启后不会自动启动

支持开机启动模式，适合长期稳定使用，重启后会自动启动

支持vmess,vless,reality三种
```
bash <(curl -sL https://raw.githubusercontent.com/dsadsadsss/vps-argo/main/install.sh)

```
或者
```
bash <(wget -qO- https://raw.githubusercontent.com/dsadsadsss/vps-argo/main/install.sh)
```
带参数选择reality的一键自动选择启动脚本，全程不要动，自动填写，一分钟馁部署好
```
(echo 1 && echo 1 && sleep 15 && echo && echo 30251 && echo vps-e11 && echo xxx.eu.org && echo KighppFtOuhlhnndf) | bash <(wget -qO- https://raw.githubusercontent.com/dsadsadsss/vps-argo/main/install.sh)
```
解释:选择步骤:选择1，选择1，等待15秒，选择默认rel,填reality端口，填节点名称，填哪吒服务器，填哪吒key，完毕，需要其他协议，你可以自行修改

# 免声明:

本仓库仅为自用备份，非开源项目，因为需要外链必须公开，但是任何人不得私自下载, 如果下载了，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权。 

如果你使用本仓库文件，造成的任何责任与本人无关, 本人不对使用者任何不当行为负责。
