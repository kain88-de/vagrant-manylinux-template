#!/bin/bash

function check_var {
    if [ -z "$1" ]; then
        echo "required variable not defined"
        exit 1
    fi
}

function check_md5sum {
    local fname=$1
    check_var ${fname}
    local md5=$2
    check_var ${md5}

    echo "${md5}  ${fname}" > ${fname}.md5
    md5sum -c ${fname}.md5
    rm ${fname}.md5
}

function check_sha256sum {
    local fname=$1
    check_var ${fname}
    local sha256=$2
    check_var ${sha256}

    echo "${sha256}  ${fname}" > ${fname}.sha256
    sha256sum -c ${fname}.sha256
    rm ${fname}.sha256
}

MINICONDA2_HASH=42dac45eee5e58f05f37399adda45e85
MINICONDA3_HASH=b1b15a3436bb7de1da3ccc6e08c7a5df
EPEL_RPM_HASH=0dcc89f9bf67a2a515bad64569b7a9615edc5e018f676a578d5fd0f17d3c81d4
DEVTOOLS_HASH=a8ebeb4bed624700f727179e6ef771dafe47651131a00a78b342251415646acc

# Libraries that are allowed as part of the manylinux1 profile
MANYLINUX1_DEPS="glibc-devel libstdc++-devel glib2-devel libX11-devel libXext-devel libXrender-devel  mesa-libGL-devel libICE-devel libSM-devel ncurses-devel"

###########################
# Install Developer Tools #
###########################

# EPEL support
curl -sLO https://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
check_sha256sum epel-release-5-4.noarch.rpm $EPEL_RPM_HASH

# Dev toolset (for LLVM and other projects requiring C++11 support)
curl -sLO http://people.centos.org/tru/devtools-2/devtools-2.repo
check_sha256sum devtools-2.repo $DEVTOOLS_HASH
mv devtools-2.repo /etc/yum.repos.d/devtools-2.repo
sudo rpm -Uvh --replacepkgs epel-release-5*.rpm
rm -f epel-release-5*.rpm

# Development tools and libraries
sudo yum -y install bzip2 make git patch unzip bison yasm diffutils \
    autoconf automake which file gcc gcc-c++ gcc-gfortran \
    kernel-devel-`uname -r` \
    devtoolset-2-binutils devtoolset-2-gcc \
    devtoolset-2-gcc-c++ devtoolset-2-gcc-gfortran \
    ${MANYLINUX1_DEPS}

sudo yum -y erase wireless-tools gtk2 libX11 hicolor-icon-theme \
    avahi freetype bitstream-vera-fonts > /dev/null 2>&1

sudo yum -y clean all > /dev/null 2>&1

###############################
# Install miniconda Python2/3 #
###############################

curl -sLO https://repo.continuum.io/miniconda/Miniconda2-4.0.5-Linux-x86_64.sh
curl -sLO https://repo.continuum.io/miniconda/Miniconda3-4.0.5-Linux-x86_64.sh

check_md5sum Miniconda2-4.0.5-Linux-x86_64.sh $MINICONDA2_HASH
check_md5sum Miniconda3-4.0.5-Linux-x86_64.sh $MINICONDA3_HASH

# install conda 2
chmod +x Miniconda2-4.0.5-Linux-x86_64.sh
./Miniconda2-4.0.5-Linux-x86_64.sh -b -f
/home/vagrant/miniconda2/bin/conda install --yes conda-build

# install conda 3
chmod +x Miniconda3-4.0.5-Linux-x86_64.sh
./Miniconda3-4.0.5-Linux-x86_64.sh -b -f
/home/vagrant/miniconda3/bin/conda install --yes conda-build
