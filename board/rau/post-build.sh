#!/bin/sh
# args from BR2_ROOTFS_POST_SCRIPT_ARGS
# $2    board name

INSTALL=install

# Add a console on tty1
#grep -qE '^ttyGS0::' ${TARGET_DIR}/etc/inittab || \
#sed -i '/GENERIC_SERIAL/a\
#ttyGS0::respawn:/sbin/getty -L ttyGS0 0 vt100 # USB console' ${TARGET_DIR}/etc/inittab

grep -qE '^::sysinit:/bin/mount -t debugfs' ${TARGET_DIR}/etc/inittab || \
sed -i '/hostname/a\
::sysinit:/bin/mount -t debugfs none /sys/kernel/debug/' ${TARGET_DIR}/etc/inittab

sed -i -e '/::sysinit:\/bin\/hostname -F \/etc\/hostname/d' ${TARGET_DIR}/etc/inittab

BOARD_DIR="$(dirname $0)"
BOARD_NAME="$(basename ${BOARD_DIR})"
GENIMAGE_CFG="${BOARD_DIR}/genimage-msd.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"

#echo '/dev/mtdblock9  /opt            jffs2   defaults        0       1' >> ${TARGET_DIR}/etc/fstab

genimage                           \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BOARD_DIR}/msd"  \
	--outputpath "${TARGET_DIR}/opt/" \
	--config "${GENIMAGE_CFG}"

rm ${TARGET_DIR}/opt/boot.vfat
rm ${TARGET_DIR}/etc/init.d/S99iiod

#mkdir -p ${TARGET_DIR}/www/img
#mkdir -p ${TARGET_DIR}/etc/wpa_supplicant/
mkdir -p ${TARGET_DIR}/opt/var/log
mkdir -p ${TARGET_DIR}/boot

mkdir -p ${TARGET_DIR}/psp
mkdir -p ${TARGET_DIR}/oam


${INSTALL} -D -m 0755 ${BOARD_DIR}/profile ${TARGET_DIR}/etc/
#${INSTALL} -D -m 0755 ${BOARD_DIR}/update.sh ${TARGET_DIR}/sbin/
${INSTALL} -D -m 0755 ${BOARD_DIR}/udc_handle_suspend.sh ${TARGET_DIR}/sbin/

${INSTALL} -D -m 0755 ${BOARD_DIR}/check_slot ${TARGET_DIR}/usr/sbin/
${INSTALL} -D -m 0755 ${BOARD_DIR}/switch_slot ${TARGET_DIR}/usr/sbin/

#${INSTALL} -D -m 0755 ${BOARD_DIR}/S10mdev ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S15watchdog ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S20urandom ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S21misc ${TARGET_DIR}/etc/init.d/
#${INSTALL} -D -m 0755 ${BOARD_DIR}/S23udc ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S40network ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S41network ${TARGET_DIR}/etc/init.d/

${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S90mountgroup ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S91opt ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0755 ${BOARD_DIR}/init.d/S92oam ${TARGET_DIR}/etc/init.d/

#${INSTALL} -D -m 0755 ${BOARD_DIR}/S45msd ${TARGET_DIR}/etc/init.d/
${INSTALL} -D -m 0644 ${BOARD_DIR}/fw_env.config ${TARGET_DIR}/etc/
##${INSTALL} -D -m 0644 ${BOARD_DIR}/VERSIONS ${TARGET_DIR}/opt/
${INSTALL} -D -m 0755 ${BOARD_DIR}/device_reboot ${TARGET_DIR}/usr/sbin/
${INSTALL} -D -m 0644 ${BOARD_DIR}/motd ${TARGET_DIR}/etc/
#${INSTALL} -D -m 0755 ${BOARD_DIR}/test_ensm_pinctrl.sh ${TARGET_DIR}/usr/sbin/
${INSTALL} -D -m 0644 ${BOARD_DIR}/device_config ${TARGET_DIR}/etc/
${INSTALL} -D -m 0644 ${BOARD_DIR}/mdev.conf ${TARGET_DIR}/etc/
${INSTALL} -D -m 0755 ${BOARD_DIR}/automounter.sh ${TARGET_DIR}/lib/mdev/automounter.sh
${INSTALL} -D -m 0755 ${BOARD_DIR}/ifupdown.sh ${TARGET_DIR}/lib/mdev/ifupdown.sh
${INSTALL} -D -m 0644 ${BOARD_DIR}/input-event-daemon.conf ${TARGET_DIR}/etc/

#${INSTALL} -D -m 0644 ${BOARD_DIR}/msd/img/* ${TARGET_DIR}/www/img/
#${INSTALL} -D -m 0644 ${BOARD_DIR}/msd/index.html ${TARGET_DIR}/www/

#${INSTALL} -D -m 0755 ${BOARD_DIR}/wpa_supplicant/* ${TARGET_DIR}/etc/wpa_supplicant/

${INSTALL} -D -m 0755 ${BOARD_DIR}/hwrevision ${TARGET_DIR}/etc/hwrevision

${INSTALL} -D -m 0600 ${BOARD_DIR}/sudoers ${TARGET_DIR}/etc/sudoers

#ln -sf ../../wpa_supplicant/ifupdown.sh ${TARGET_DIR}/etc/network/if-up.d/wpasupplicant
#ln -sf ../../wpa_supplicant/ifupdown.sh ${TARGET_DIR}/etc/network/if-down.d/wpasupplicant
#ln -sf ../../wpa_supplicant/ifupdown.sh ${TARGET_DIR}/etc/network/if-pre-up.d/wpasupplicant
#ln -sf ../../wpa_supplicant/ifupdown.sh ${TARGET_DIR}/etc/network/if-post-down.d/wpasupplicant

ln -sf device_reboot ${TARGET_DIR}/usr/sbin/pluto_reboot

#rm -rf ${TARGET_DIR}/etc/init.d/S50dropbear
rm -rf ${TARGET_DIR}/etc/init.d/S50sshd

git rev-list HEAD | sort > config.git-hash
LOCALVER=`wc -l config.git-hash | awk '{print $1}'`
if [ $LOCALVER \> 1 ] ; then
    VER=`git rev-list origin/master | sort | join config.git-hash - | wc -l | awk '{print $1}'`
    if [ $VER != $LOCALVER ] ; then
        VER="$VER+$(($LOCALVER-$VER))"
    fi
    if git status | grep -q "modified:" ; then
        VER="${VER}M"
    fi
    VER="$VER $(git rev-list HEAD -n 1 | cut -c 1-7)"
    GIT_VERSION=r$VER
else
    GIT_VERSION=
    VER="x"
fi

# dtc build time info
BASH_TIME=`date '+%Y-%m-%d %H:%M:%S'`

rm -f config.git-hash

echo $GIT_VERSION $BASH_TIME > ${TARGET_DIR}/etc/sysroot_ver
