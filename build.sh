#!/bin/sh

UPSHOSTNAME=${1:?}
UPSNAME=${2:-cp1500avr}
UPSDESC=${3:-CyberPower 1500VA AVR}
UPSDRIVER=${4:-usbhid-ups}
UPSUSER=${5:-upsuser}
UPSPASSWD=${6:-}

OPENWRT_BUILDER=../openwrt-imagebuilder-21.02.1-sunxi-cortexa7.Linux-x86_64
PROFILE=linksprite_pcduino3-nano
NUT="nut nut-common nut-server nut-upsmon nut-upsc nut-upscmd nut-upslog nut-upsrw nut-upssched nut-web-cgi nut-avahi-service"
NUT_DRIVERS="nut-driver-usbhid-ups nut-driver-powerpanel"
HTTPD="uhttpd uhttpd-mod-lua uhttpd-mod-ubus"
PACKAGES="$NUT $NUT_DRIVERS $HTTPD"
FILES=$PWD/staging
BIN_DIR=$PWD/images
DISABLED_SERVICES="dnsmasq firewall odhcpd"

[ -d images ] || mkdir images
[ -d staging ] || mkdir staging
rm -rf staging/* && cp -R files/* staging/
if [ -z "$UPSPASSWD" ]; then
        UPSPASSWD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1)
fi
for file in staging/etc/config/nut_*; do
        sed -i "s/%UPSHOSTNAME%/$UPSHOSTNAME/" $file
        sed -i "s/%UPSNAME%/$UPSNAME/" $file
        sed -i "s/%UPSDRIVER%/$UPSDRIVER/" $file
        sed -i "s/%UPSUSER%/$UPSUSER/" $file
        sed -i "s/%UPSPASSWD%/$UPSPASSWD/" $file
done
sed -i "s/%UPSDESC%/$UPSDESC/" staging/etc/config/nut_cgi
for file in staging/etc/uci-defaults/*; do
        sed -i "s/%UPSHOSTNAME%/$UPSHOSTNAME/" $file
done

pushd .
cd $OPENWRT_BUILDER && make clean image PROFILE=$PROFILE FILES=$FILES BIN_DIR=$BIN_DIR PACKAGES="$PACKAGES" DISABLED_SERVICES="$DISABLED_SERVICES"
popd
