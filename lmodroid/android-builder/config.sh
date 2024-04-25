#!/bin/bash

if [[ -z $DEVICE ]] && [[ ! -z $JOB_BASE_NAME ]]; then
    DEVICE=`echo $JOB_BASE_NAME | cut -f 1 -d "-"`
fi

if [[ -z $ROM_VERSION ]] && [[ ! -z $JOB_BASE_NAME ]]; then
    ROM_VERSION=`echo $JOB_BASE_NAME | cut -f 2 -d "-"`
fi

if [[ -z $BUILD_TYPE ]] && [[ ! -z $JOB_BASE_NAME ]]; then
    BUILD_TYPE=`echo $JOB_BASE_NAME | cut -f 3 -d "-"`
fi

if [[ -z $BUILD_DIR ]]; then
    BUILD_DIR=${JENKINS_HOME}/lmodroid
fi

if [[ -z $CCACHE_DIR ]]; then
    export CCACHE_DIR=${JENKINS_HOME}/.ccache
fi

export ROOTDIR=$BUILD_DIR/$ROM_VERSION
export LMODROID_BUILDTYPE=RELEASE

export USE_CCACHE=1
export PATH=${JENKINS_HOME}/bin:$PATH
export LANG=C
export LC_ALL=C
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
