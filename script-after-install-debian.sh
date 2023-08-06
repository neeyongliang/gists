#!/bin/bash
# Program:
#   Run this shell script after Install Debian/Ubuntu.
# History:
#   2017/06/04 yongliang First release
#   2023/08/06 yongliang Merge debian and ubuntu

echo "###################### Installing ###########################"

while getopts 'Qqpu:' OPT; do
    case $OPT in
    u)
        noroot="$OPTARG";;
    Q)
        INSTALL_QT5="y";;
    q)
        INSTALL_QEMU="y";;
    p)
        INSTALL_PY3="y";;
    ?)
        echo "Usage: $(basename $0) [-Qqp] -u USER"
        echo "Q: try install Qt5\nq: try install qemu\np: try install pyton3"
        ;;
    esac
done

if [ "$noroot" == "" ]; then
    echo "Must give a username"
    exit 2
fi

echo "Create directory..."
cd "$HOME" || exit 1
mkdir -p Github Software Workspace
cur_arch=$(uname -m)

if grep -q -i "ubuntu" "/etc/issue"; then
    distro="Ubuntu"
else
    distro="Debian"
fi

if [ "$cur_arch" == "x86_64" ]; then
    echo "Install chrome..."
    if [ ! -f google-chrome-stable_current_amd64.deb ]; then
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    fi
    sudo dpkg -i google-chrome-stable_current_amd64.deb
    sudo apt --fix-broken install
fi

# echo "Install sublime..."
# wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
# echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

sudo apt update -y
sudo apt install apt-transport-https curl wget

echo "Install vscode..."
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
echo "deb https://packages.microsoft.com/repos/vscode stable main" > vscode-manual.list
sudo mv vscode-manual.list /etc/apt/sources.list.d/

echo " Now, Update & Grade ..."
sudo apt update -y
sudo apt upgrade -y

echo "Install packages..."
# Delete this because contained by package self
sudo apt install -y zsh git meld devhelp dconf-editor exuberant-ctags \
    screenfetch htop gitk unrar vim tree cmake lnav shellcheck \
    devscripts fakeroot python3-pip code fonts-firacode aptitude \
    fcitx fcitx-frontend-all fcitx-googlepinyin
sudo rm /etc/apt/sources.list.d/vscode-manual.list

echo "###################### Fonts ##########################"
if [ "$distro" == "Ubuntu" ]; then
    sudo apt install -y fonts-cascadia-code
fi

if [ "$LANG" == "zh_CN.UTF-8" ]; then
    echo "Install cjk fonts..."
    sudo apt install -y fonts-noto-cjk fonts-noto-cjk-extra
fi

echo "###################### Scripts #######################"
sudo -u "$noroot" git -C "$HOME"/Github clone https://github.com/neeyongliang/dotfiles.git
if [ -f "script-install-ohmyzsh.sh" ]; then
    sudo -u "$noroot" ./script-install-ohmyzsh.sh &
fi

if [ "$INSTALL_QEMU" == "y" ]; then
    echo "Install qemu..."
    sudo apt install -y qemu qemu-user-static
fi

if [ "$INSTALL_QT5" == "y" ]; then
    echo "Install qt5..."
    sudo apt install -y qtcreator qt5-doc-html qt5-assistant qt5-doc \
        qttools5-dev-tools qt5-default
fi

if [ "$INSTALL_PY3" == "y" ]; then
    echo "Install pip3..."
    sudo apt install -y python3-pip python3-dev python3-setuptools python3-doc
    sudo -u "$noroot" pip3 install thefuck flake8
fi
