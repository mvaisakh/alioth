#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
# Copyright (c) 2019, The Linux Foundation. All rights reserved.

# Script to generate a defconfig variant based on the input

usage() {
	echo "Usage: $0 <board_platform> <device_defconfig>"
	echo "Example: $0 kona alioth_defconfig"
	exit 1
}

if [ -z "$1" ]; then
	echo "Error: Failed to pass input argument"
	usage
fi

if [ -z "$2" ]; then
	echo "Error: Failed to pass input argument"
	usage
fi

SCRIPTS_ROOT=$(readlink -f $(dirname $0)/)

DEVICE_NAME=`echo $2 | sed -r "s/(_defconfig)$//"`

BOARD_NAME="$1"

# We should be in the kernel root after the envsetup
source ${SCRIPTS_ROOT}/envsetup.sh $BOARD_NAME $DEVICE_NAME

COMMON_FRAG=""
case $BOARD_NAME in
	kona)
		COMMON_FRAG="${CONFIGS_DIR}/xiaomi/sm8250-common.config"
		;;
	lito)
		COMMON_FRAG="${CONFIGS_DIR}/xiaomi/sm7250-common.config"
		;;
	*)
		COMMON_FRAG=""
		;;
esac

if [ ! -f "${DEVICE_FRAG}" ]; then
	echo "Error: Invalid input"
	usage
fi

REQUIRED_DEFCONFIG="${2}_defconfig"

FINAL_DEFCONFIG_BLEND=""

FINAL_DEFCONFIG_BLEND+=" $COMMON_FRAG "

FINAL_DEFCONFIG_BLEND+=" $DEVICE_FRAG "

FINAL_DEFCONFIG_BLEND+=${BASE_DEFCONFIG}

# Reverse the order of the configs for the override to work properly
FINAL_DEFCONFIG_BLEND=`echo "${FINAL_DEFCONFIG_BLEND}" | awk '{ for (i=NF; i>1; i--) printf("%s ",$i); print $1; }'`

echo "defconfig blend for $REQUIRED_DEFCONFIG: $FINAL_DEFCONFIG_BLEND"

${KERN_SRC}/scripts/kconfig/merge_config.sh $FINAL_DEFCONFIG_BLEND
make savedefconfig
mv defconfig $CONFIGS_DIR/$REQUIRED_DEFCONFIG

# Cleanup the kernel source
make mrproper
