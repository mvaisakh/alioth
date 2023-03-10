#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
# Copyright (c) 2019, The Linux Foundation. All rights reserved.

# Script to edit the kconfig fragments through menuconfig

usage() {
	echo "Usage: $0 <board_name> <device_defconfig>"
	echo "Example: $0 kona alioth_defconfig"
	exit 1
}

if [ -z "$1" ]; then
	echo "Error: Failed to pass input argument"
	usage
fi

SCRIPTS_ROOT=$(readlink -f $(dirname $0)/)

DEVICE_NAME=`echo $1 | sed -r "s/(_defconfig)$//"`

DEVICE_NAME=`echo $DEVICE_NAME | sed "s/vendor\///g"`

# We should be in the kernel root after the envsetup
source ${SCRIPTS_ROOT}/envsetup.sh $BOARD_NAME $DEVICE_NAME

if [ ! -f "${DEVICE_FRAG}" ]; then
	echo "Error: Invalid input"
	usage
fi

REQUIRED_DEFCONFIG=`echo $1 | sed "s/vendor\///g"`

FINAL_DEFCONFIG_BLEND=""

FINAL_DEFCONFIG_BLEND+=" $DEVICE_FRAG"

FINAL_DEFCONFIG_BLEND+=${BASE_DEFCONFIG}

# Reverse the order of the configs for the override to work properly
# Correct order is base_defconfig GKI.config QGKI.config debug.config
FINAL_DEFCONFIG_BLEND=`echo "${FINAL_DEFCONFIG_BLEND}" | awk '{ for (i=NF; i>1; i--) printf("%s ",$i); print $1; }'`

echo "defconfig blend for $REQUIRED_DEFCONFIG: $FINAL_DEFCONFIG_BLEND"

${KERN_SRC}/scripts/kconfig/merge_config.sh $FINAL_DEFCONFIG_BLEND

make savedefconfig
mv defconfig defconfig_base
mv .config .config_base

# Strip off the complete file paths and retail only the values beginning with vendor/
MENUCONFIG_BLEND=""
MENUCONFIG_BLEND+=" vendor/"`basename $config_file`" "

# Start the menuconfig
make ${MENUCONFIG_BLEND} menuconfig
make savedefconfig

# The fragment file that we are targeting to edit
FRAG_CONFIG=`echo ${MENUCONFIG_BLEND} | awk 'NF>1{print $NF}' | sed 's/vendor\///'`
FRAG_CONFIG=$CONFIGS_DIR/$FRAG_CONFIG

# CONFIGs to be added
# 'defconfig' file should have been generated.
# Diff this with the 'defconfig_base' from the previous step and extract only the lines that were added
# Finally, remove the "+" from the beginning of the lines and append it to the FRAG_DEFCONFIG
diff -u defconfig_base defconfig | grep "^+CONFIG_" | sed 's/^.//' >> ${FRAG_CONFIG}

# CONFIGs to be removed
configs_to_remove=`diff -u defconfig_base defconfig | grep "^-CONFIG_" | sed 's/^.//'`
for config_del in $configs_to_remove; do
	sed -i "/$config_del/d" ${FRAG_CONFIG}
done

# CONFIGs that are set in base defconfig (or lower fragment), but wanted it to be disabled in FRAG_CONFIG
diff -u .config_base .config | grep "^+# CONFIG_" | sed 's/^.//' >> ${FRAG_CONFIG}

# Cleanup the config files generated during the process
rm -f .config_base .config defconfig defconfig_base
