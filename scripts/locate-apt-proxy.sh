#!/bin/sh
#
# Determine the name of a local proxy for apt.  This script allows us
# to dynamically set the proxy for apt-get.  When we have a local
# proxy server, it will be used.
#
# apt-get will pass a URI to be accessed to this script.  We don't
# care about discriminating the URI, at the moment, so we only check
# for the presence of the proxy.
#
# The result of this script is either the URI for the proxy, DIRECT if
# no proxy should be used, or an empty string if apt should use the
# default proxy.
#
# Configuring apt
# ===============
#
# Something like the following will configure apt to use this script
# to select the proxy.  Make sure to adjust the path of the script.
#
#  echo "Acquire::http::Proxy-Auto-Detect \"locate-apt-proxy.sh\";" \
#    > /etc/apt/apt.conf.d/10auto-proxy
#
# To debug whether or not the connection is working, add this line as well.
#
#   Debug::Acquire::http yes;
#

# Proxy to verify
u=apt-cacher:3142

# ---

h=$(echo $u | sed -e s/:.*//)
p=$(echo $u | sed -e s/.*://)

w=1

# We could use DIRECT as our fallback, but we're better off letting
# the ambient apt configuration take charge of the proxy should there
# be something known by the sysadmin.
#FALLBACK="DIRECT"
FALLBACK=""

NETCAT=netcat
PING=ping

# Try netcat
if type $NETCAT > /dev/null 2>&1 ; then
    if $NETCAT -w $w -z $h $p > /dev/null 2>&1 ; then
	echo "http://$u/"
	exit 0
    fi
# Try ping
elif type $PING > /dev/null 2>&1 ; then
    if $PING -q -c 1 $h > /dev/null 2>&1 ; then
	echo "http://$u/"
	exit 0
    fi
# Try bash
elif type bash > /dev/null 2>&1 ; then
    if (bash -c "echo > /dev/tcp/$h/$p") > /dev/null 2>&1 ; then
	echo "http://$u/"
	exit 0
    fi
fi

echo $FALLBACK

exit 0
