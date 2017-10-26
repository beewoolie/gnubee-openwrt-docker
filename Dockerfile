# The old MIPS compiler does not want to be compiled with GCC newer
# than version 5.  So, we use Ubuntu 16.04 which defaults to GCC-5.4.
# A newer version of Ubuntu or Debian may be successful if the openwrt
# updates the MIPS compiler or we configure the image to use an older
# compiler as the default for the host compiler.

FROM ubuntu:16.04

ARG repo_url=https://github.com/gnubee-git/gnubee-openwrt.git

ENV U openwrt

ADD scripts scripts

RUN echo "Acquire::http::Proxy-Auto-Detect \"/scripts/locate-apt-proxy.sh\";" \
    > /etc/apt/apt.conf.d/10cacher \
 && true \
 && apt-get update \
 && apt-get install -y git-core subversion build-essential gcc-multilib \
                       libncurses5-dev zlib1g-dev gawk flex gettext wget \
		       unzip python sudo \
 && apt-get clean \
 && useradd -m $U \
 && echo '$U ALL=NOPASSWD: ALL' > /etc/sudoers.d/$U

RUN sudo -iu $U GIT_SSL_NO_VERIFY=true git clone $repo_url openwrt

WORKDIR /home/$U/openwrt

# If there is a dl/ directory, it is a cache of downloaded packages.
# We copy these files into the container to prime the build.  It has
# several benefits.  It protect us from issues downloading packages
# where the servers are unreliable.  It reduces traffic to those
# servers.  And, it speeds our build dramatically since this is
# usually the slowest step.  BTW, we copy the README in case the dl/
# doesn't exist.

COPY README.org dl/* dl/

# Prepare the build directory.

RUN chmod a+w ./dl \
 && sudo -iu $U cp openwrt/GB-Deb.config openwrt/.config \
 && sudo -iu $U openwrt/scripts/feeds update -a \
 && sudo -iu $U openwrt/scripts/feeds install -a \
 && sudo -iu $U make -C openwrt defconfig

# Download packages not available in the cache and build the firmware
# image.  The openwrt package recommends that the build be guarded by
# 'ionice -c 3 nice -n 19'.  We don't bother since we're using a
# container.  If there are problems with either step, add V=s to show
# more detail from the build.

RUN sudo -iu $U make -C openwrt -j1 download \
 && sudo -iu $U make -C openwrt -j4
