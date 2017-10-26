# The old compiler does not want to be compiled with GCC newer than 5.
# So, we use Ubuntu 16.04.  A newer version may be successful if the
# project updates the compiler or we configure the image to use an
# older compiler as the default host compiler. 

FROM ubuntu:16.04

ENV U openwrt
#ENV REPO_URL https://github.com/gnubee-git/gnubee-openwrt.git
ENV REPO_URL https://wg.woollysoft.com/GnuBee/gnubee-openwrt.git

ADD scripts scripts

RUN echo "Acquire::http::Proxy-Auto-Detect \"/scripts/locate-apt-proxy.sh\";" \
    > /etc/apt/apt.conf.d/10cacher \
 && apt-get update \
 && apt-get install -y git-core subversion build-essential gcc-multilib \
                       libncurses5-dev zlib1g-dev gawk flex gettext wget \
		       unzip python sudo \
 && apt-get clean \
 && useradd -m $U \
 && echo '$U ALL=NOPASSWD: ALL' > /etc/sudoers.d/$U

RUN sudo -iu $U GIT_SSL_NO_VERIFY=true git clone $REPO_URL openwrt

WORKDIR /home/$U/openwrt

ADD dl dl

RUN sudo -u $U cp ./GB-Deb.config ./.config \
 && sudo -u $U ./scripts/feeds update -a \
 && sudo -u $U ./scripts/feeds install -a \
 && sudo -u $U make defconfig

#CMD sudo -u $U make defconfig \
# && sudo -u $U make -j1 V=s download \
# && sudo -u $U ionice -c 3 nice -n 19 make -j2 V=s > buildlog
