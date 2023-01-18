#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
# Copyright (c) 2019, The Linux Foundation. All rights reserved.

SCRIPT_DIR=$(readlink -f $(dirname $0)/)
cd ${SCRIPT_DIR}
cd ../../
KERN_SRC=`pwd`

: ${ARCH:=arm64}
: ${CROSS_COMPILE:=aarch64-linux-gnu-}
: ${REAL_CC:=clang}
: ${KERN_OUT:=}

CONFIGS_DIR=${KERN_SRC}/arch/${ARCH}/configs/vendor

BOARD_NAME=$1
DEVICE_NAME=$2

BASE_DEFCONFIG=${KERN_SRC}/arch/${ARCH}/configs/vendor/${BOARD_NAME}-perf_defconfig

# Fragements that are available for the platform
DEVICE_FRAG=${CONFIGS_DIR}/xiaomi/${DEVICE_NAME}.config

export ARCH CROSS_COMPILE REAL_CC KERN_SRC KERN_OUT CONFIGS_DIR BASE_DEFCONFIG \
	DEVICE_FRAG
