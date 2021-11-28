#!/bin/bash

# Description: this is a script for install elk stack on Linux
# Usage      : you can pass wanted version at first parameter
# Author     : wikinee
# Changelog  : 2021.09.11 first release

echo "this script only install package, you MUST configurate software by youself"

if [ -z "$1" ]
then
    VER="7.13.1"
fi

# for Debian, Ubuntu, Kylin
if [ -f "/usr/bin/apt" ]
then
    sudo apt install -y wget vim apt-transport-https
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list

    # install nginx (optional)
    # sudo apt install nginx -y
    sudo apt update
    sudo apt install -y elasticsearch=$VER kibana=$VER logstash=1:$VER-1
    exit 0
fi

function createRepoFile() {
cat > elastic-7.x.repo <<-EOF
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF
};

# for CentOS, Redhat, Fedora
if [ -f "/usr/bin/rpm" ]
then
    sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    createRepoFile
    sudo mv elastic-7.x.repo /etc/yum.repos.d/
    sudo yum install --enablerepo=elasticsearch elasticsearch logstash kibana
    exit 0
fi

# for OpenSuse
if [ -f "/usr/bin/zypper" ]
then
    createRepoFile
    sudo mv elastic-7.x.repo /etc/zypp/repos.d/
    sudo zypper modifyrepo --enable elasticsearch && \
    sudo zypper install elasticsearch logstash kibana; \
    sudo zypper modifyrepo --disable elasticsearch
fi
