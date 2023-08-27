#!/bin/bash

##########################################################
# Description: build kitty from source in Ubuntu20.04
#   kitty is a greate cross-platform terminal emulator
# Author:
#   yongliang <neeyongliang@gmail.com>
# Changelog:
#   2023.08.27 First release
##########################################################

echo "Press Ctrl+C anytime if you want interrupt..."
sleep 5

if [ ! -d Workspace ]; then
    mkdir Workspace
fi

version="0.29.2"
currArch="$(uname -m)"
distroVer="ubuntu20.04"
currArch="$(dpkg-architecture -q DEB_BUILD_ARCH_CPU)"

# set 0 if you go version uppper 1.20
goInstall=1
goVersion="1.21.0"
# set
xxhashInstall=1
xxhashVer="0.8.1-1"

cd Workspace || exit 1
if [ ! -f kitty-dep-xxhash ] && [ $xxhashInstall -eq 1 ]; then
    # build xxhash
    wget http://archive.ubuntu.com/ubuntu/pool/main/x/xxhash/xxhash_"$xxhashVer".dsc
    wget http://archive.ubuntu.com/ubuntu/pool/main/x/xxhash/xxhash_0.8.1.orig.tar.gz
    wget http://archive.ubuntu.com/ubuntu/pool/main/x/xxhash/xxhash_"$xxhashVer".debian.tar.xz
    touch kitty-dep-xxhash
fi
sudo apt-get update
sudo apt install -y git dpkg-dev debhelper vim

if [ ! -f libxxhash0_"$xxhashVer"_"$currArch".deb ]; then
    # xxhash not build last time
    rm -rf xxhash-0.8.1
    dpkg-source -x xxhash_"$xxhashVer".dsc
    cd xxhash-0.8.1/ || exit 2
    sed -i 's/\= 13/\= 12/g' debian/control
    sleep 1
    dpkg-buildpackage -b
    cd ..
    sudo dpkg -i libxxhash0_"$xxhashVer"_*.deb libxxhash-dev_"$xxhashVer"_*.deb
fi

if [ $goInstall -eq 1 ] && [ ! -f go"$goVersion".linux-"$currArch".tar.gz ]; then
    # install go
    wget https://golang.google.cn/dl/go"$goVersion".linux-"$currArch".tar.gz
    sudo tar -C /usr/local -xzf go"$goVersion".linux-"$currArch".tar.gz
fi
export PATH=$PATH:/usr/local/go/bin
go version

if [ ! -f "kitty-dep-installed" ]; then
sudo apt-get install -y libgl1-mesa-dev libxi-dev libxrandr-dev \
  libxinerama-dev ca-certificates libxcursor-dev libxcb-xkb-dev libdbus-1-dev \
  libxkbcommon-dev libharfbuzz-dev libx11-xcb-dev zsh libpng-dev liblcms2-dev \
  libfontconfig-dev libxkbcommon-x11-dev libcanberra-dev uuid-dev \
  libssl-dev python3-dev python3-pip fonts-roboto
  touch kitty-dep-installed
fi

# for Chinese mirrors
if [ "$LANG" = "zh_CN.UTF-8" ]; then
  go env -w GO111MODULE=on
  go env -w GOPROXY=https://goproxy.cn,direct
  pip3 config set global.index-url https://mirrors.ustc.edu.cn/pypi/web/simple
fi

if [ ! -f kitty-dep-sphinx ]; then
    sudo pip3 install Sphinx sphinx-copybutton sphinx-inline-tabs sphinxext-opengraph furo
    touch kitty-dep-sphinx
fi

# clone source
# set following config if occur 'The TLS connection was non-properly terminated'
# git config --global --unset https.https://github.com.proxy
# git config --global --unset http.https://github.com.proxy

if [ ! -d kitty ]; then
    git clone https://github.com/kovidgoyal/kitty.git --depth=1 --progress
fi
cd kitty || exit 3
# fix optimize, tuple cannot compare with int type
sed -i 's/optimize=(0, 1, 2)/optimize=0/g' setup.py

# for build
make linux-package
gzip -fk linux-package/share/man/man1/kitty.1 > linux-package/share/man/man1/kitty.1.gz
rm -rf kitty_"$version"_"$distroVer"_"$currArch"
mkdir kitty_"$version"_"$distroVer"_"$currArch"
cd kitty_"$version"_"$distroVer"_"$currArch" || exit 1
mkdir DEBIAN etc usr
cp -a ../linux-package/* usr/
mkdir -p etc/xdg/kitty/
echo "update_check_interval 0" > etc/xdg/kitty/kitty.conf
touch DEBIAN/postinst DEBIAN/prerm DEBIAN/control
cat <<EOF > DEBIAN/control
Package: kitty
Version: $version-$distroVer
Architecture: $(dpkg-architecture -q DEB_BUILD_ARCH_CPU)
Maintainer: yongliang <neeyongliang@gmail.com>
Depends: python3 (<< 3.9),
  python3 (>= 3.8~),
  python3.8,
  python3:any,
  libc6 (>= 2.29),
  libcanberra0 (>= 0.29),
  libdbus-1-3 (>= 1.9.14),
  libfontconfig1 (>= 2.12.6),
  libfreetype6 (>= 2.6),
  libharfbuzz0b (>= 2.2.0),
  liblcms2-2 (>= 2.2+git20110628),
  libpng16-16 (>= 1.6.2-1),
  libpython3.8 (>= 3.8~),
  librsync2 (>= 2.0.0),
  libwayland-client0 (>= 1.9.91),
  libx11-6 (>= 2:1.2.99.901),
  libx11-xcb1 (>= 2:1.6.9),
  libxkbcommon-x11-0 (>= 0.5.0),
  libxkbcommon0 (>= 0.5.0),
  openssl (>= 1.1.1),
  zlib1g (>= 1:1.1.4)
Recommends: libcanberra0
Suggests: imagemagick
Provides: x-terminal-emulator
Section: x11
Priority: optional
Homepage: https://sw.kovidgoyal.net/kitty/
Description: fast, featureful, GPU based terminal emulator
 Kitty supports modern terminal features like: graphics, unicode,
 true-color, OpenType ligatures, mouse protocol, focus tracking, and
 bracketed paste.
 .
 Kitty has a framework for "kittens", small terminal programs that can be used
 to extend its functionality.
Original-Maintainer: James McCoy <jamessan@debian.org>
EOF

chmod 775 DEBIAN/postinst DEBIAN/prerm
cat <<EOF > DEBIAN/postinst
#!/bin/sh
set -e

case "$1" in
  configure)
    update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator \
        /usr/bin/kitty 20 --slave /usr/share/man/man1/x-terminal-emulator.1.gz \
        x-terminal-emulator.1.gz /usr/share/man/man1/kitty.1.gz
    ;;
esac

# Automatically added by dh_python3:
if which py3compile >/dev/null 2>&1; then
    py3compile -p kitty /usr/lib/kitty -V 3.8
fi
if which pypy3compile >/dev/null 2>&1; then
    pypy3compile -p kitty /usr/lib/kitty -V 3.8 || true
fi

# End automatically added section

exit 0
EOF

cat <<EOF > DEBIAN/prerm
#!/bin/sh
set -e

rm -rf /usr/lib/kitty/shell-integration

case "$1" in
  remove|deconfigure)
    rm -rf /usr/lib/kitty
    update-alternatives --remove x-terminal-emulator /usr/bin/kitty
    ;;
esac

#DEBHELPER#

exit 0
EOF

mkdir -p usr/share/applications
cat <<EOF > usr/share/applications/kitty.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=kitty
GenericName=Terminal emulator
Comment=Fast, feature-rich, cross-platform, GPU based terminal
TryExec=kitty
Exec=kitty
Icon=kitty
Categories=System;TerminalEmulator;
EOF

mkdir -p usr/share/icons/hicolor/256x256/apps
cp ../logo/kitty.png usr/share/icons/hicolor/256x256/apps/

mkdir -p usr/share/python3/runtime.d
cat <<EOF > usr/share/python3/runtime.d/kitty.rtupdate
#! /bin/sh
set -e

if [ "$1" = rtupdate ]; then
    py3clean -p kitty /usr/lib/kitty
    py3compile -p kitty -V 3.8 /usr/lib/kitty
fi
EOF
chmod 775 usr/share/python3/runtime.d/kitty.rtupdate

cd ..
dpkg -b kitty_"$version"_"$distroVer"_"$currArch"

exit 0
