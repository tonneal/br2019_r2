#!/bin/bash

CONTAINER_VER="1_0"
PRODUCT_NAME="rau"
PRODUCT_MOD="sys"
FILES="sw-description update.sh rootfs.tar.gz"





# dtc build time info
BASH_TIME=`date '+%m%d%p' | sed -e 's/\(.*\)/\L\1/'`

GIT_VER=`git rev-list HEAD -n 1 | cut -c 1-7`


ORGIN_DIR=$PWD

# srcipt dir 
SWUSRC_DIR="$(dirname $0)"

# if [ ! -f "system.bit" ]; then
#   rm -rf system.bit
# fi

# rm -rf *.swu

# cp $1 system.bit



IMAGE_DIR="${TARGET_DIR}/../images"

cp ${SWUSRC_DIR}/sw-description ${IMAGE_DIR}/
cp ${SWUSRC_DIR}/update.sh ${IMAGE_DIR}/

cd ${IMAGE_DIR}

for i in $FILES;do
        echo $i;done | cpio -ov -H crc >  ${PRODUCT_NAME}_${PRODUCT_MOD}_${GIT_VER}_${BASH_TIME}.swu

rm -rf ${IMAGE_DIR}/sw-description
rm -rf ${IMAGE_DIR}/update.sh

cd ${ORGIN_DIR}
