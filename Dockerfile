# The old compiler does not want to be compiled with GCC newer than 5.
# So, we use Ubuntu 16.04.  A newer version may be successful if the
# project updates the compiler or we configure the image to use an
# older compiler as the default host compiler. 

FROM ubuntu:16.04

RUN apt-get update \
 && apt-get install -y git-core subversion build-essential gcc-multilib \
                       libncurses5-dev zlib1g-dev gawk flex gettext wget \
		       unzip python sudo \
 && apt-get clean \
 && useradd -m openwrt \
 && echo 'openwrt ALL=NOPASSWD: ALL' > /etc/sudoers.d/openwrt

RUN sudo -iu openwrt \
    git clone https://github.com/gnubee-git/gnubee-openwrt.git openwrt
WORKDIR /openwrt

RUN sudo -iu openwrt cp openwrt/GB-Deb.config openwrt/.config \
 && sudo -iu openwrt openwrt/scripts/feeds update -a \
 && sudo -iu openwrt openwrt/scripts/feeds install -a \
 && sudo -iu openwrt make -C openwrt defconfig

CMD sudo -iu openwrt make make defconfig \
 && sudo -iu openwrt make make -j1 V=s download \
 && sudo -iu openwrt ionice -c 3 nice -n 19 make -j2 V=s > buildlog
