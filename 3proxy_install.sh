#!/bin/bash
# Скрипт установки 3proxy на операционные системы семейства CentOS

# Этот скрипт будет работать только на CentOS и, возможно, на его
# производных дистрибутивах

if [[ "$EUID" -ne 0 ]]; then
	echo "Этот скрипт нужно запускать с правами root"
	exit 2
fi

if grep -qs "CentOS release 5" "/etc/redhat-release"; then
	echo "CentOS 5 слишком старый, установка не возможна"
	exit 4
fi
if [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	OS=centos
	GROUPNAME=nobody
	RCLOCAL='/etc/rc.d/rc.local'
else
	echo "Ваша операционная система не из семейства CentOS"
	exit 5
fi


# Пробуем получить наш IP адрес
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
if [[ "$IP" = "" ]]; then
		IP=$(wget -4qO- "http://whatismyip.akamai.com/")
fi


			
clear
echo 'Начинаем установку 3proxy вместе с SecFAll.com'
echo ""
# Установка 3proxy
echo "Несколько вопросов перед началом установки"
echo "Вы можете оставлять параметры по умолчанию и просто нажимать «Enter», если они вас устраивают."
echo "Если хотите изменить параметр, то сотрите предлагаемое значение и введите своё"
echo ""
echo "Для начала введите IP адрес, на который 3proxy будет принимать подкючения"
echo "Если автоматически определённый IP адрес правильный, просто нажмите Enter"
read -p "Определён IP адрес: " -e -i $IP IP
echo ""
echo "На какой порт будем принимать подключения (1080 рекомендуется)?"
read -p "Порт: " -e -i 1080 PORT
echo ""
echo "Какой DNS вы хотите использовать в своей VPN?"
echo "   1) Текущие системные настройки"
echo "   2) Google"
read -p "DNS [1-2]: " -e -i 2 DNS
echo ""
echo "Отлично. Сейчас обновим сервер и выполним установку 3proxy."
read -n1 -r -p "Нажмите любую кнопку для продолжения..."
yum install epel-release -y
yum update -y
yum upgrade -y
yum install wget zip unzip -y
yum -y install gcc
cd /tmp/
wget https://github.com/z3APA3A/3proxy/archive/0.8.12.tar.gz
tar -xvzf 0.8.12.tar.gz
cd 3proxy-0.8.12
make -f Makefile.Linux
mkdir -p /opt/3proxy/bin
touch /opt/3proxy/3proxy.pid
cp ./src/3proxy /opt/3proxy/bin
cp ./cfg/3proxy.cfg.sample /opt/3proxy/3proxy.cfg
#Делаем скрипт управления службой 3proxy
echo '[Unit]
Description=3proxy Proxy Server
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/3proxy/bin/3proxy /opt/3proxy/3proxy.cfg

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/3proxy.service
		
#Делаем конфиг 3proxy
echo 'daemon
pidfile /opt/3proxy/3proxy.pid' > /opt/3proxy/3proxy.cfg
# DNS для 3proxy
case $DNS in
	1) 
	# Получаем DNS из resolv.conf и используем их для 3proxy
	grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read line; do
	echo "nserver $line" >> /opt/3proxy/3proxy.cfg
	done
	;;
	2) 
	echo 'nserver 8.8.8.8' >> /opt/3proxy/3proxy.cfg
	echo 'nserver 8.8.4.4' >> /opt/3proxy/3proxy.cfg
	;;
	esac
	echo 'nscache 65536
	
timeouts 1 5 30 60 180 1800 15 60
users 17t3081104:CL:5gt9IrYEaS
log /dev/null


#Binding address' >> /opt/3proxy/3proxy.cfg
			echo "external $IP" >> /opt/3proxy/3proxy.cfg
			echo '#SOCKS5
auth strong
flush
allow *
maxconn 64' >> /opt/3proxy/3proxy.cfg
echo "socks -p$PORT" >> /opt/3proxy/3proxy.cfg
			
/usr/bin/killall 3proxy
systemctl start 3proxy
systemctl enable 3proxy
			
echo "3proxy установлен и запущен"
read -n1 -r -p "Нажмите любую кнопку для продолжения..."


