#!/bin/bash

# Python versions to be installed in /opt/$VERSION_NO
# CPYTHON_VERSIONS="2.6.9 2.7.11 3.3.6 3.4.4 3.5.1"
CPYTHON_VERSIONS="2.7.11 3.5.1"

# openssl version to build, with expected sha256 hash of .tar.gz
# archive
OPENSSL_ROOT=openssl-1.0.2g
OPENSSL_HASH=b784b1b3907ce39abf4098702dade6365522a253ad1552e267a9a0e89594aa33

# Dependencies for compiling Python that we want to remove from
# the final image after compiling Python
PYTHON_COMPILE_DEPS="zlib-devel bzip2-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel"

# Libraries that are allowed as part of the manylinux1 profile
MANYLINUX1_DEPS="glibc-devel libstdc++-devel glib2-devel libX11-devel libXext-devel libXrender-devel  mesa-libGL-devel libICE-devel libSM-devel ncurses-devel"

MY_DIR=$(dirname "${BASH_SOURCE[0]}")
echo $MY_DIR

# Get build utilities
# TODO: ship this in the packer build directly
curl -sL https://raw.githubusercontent.com/pypa/manylinux/master/docker/build_scripts/build_utils.sh > $MY_DIR/build_utils.sh
curl -sL https://raw.githubusercontent.com/pypa/manylinux/master/docker/build_scripts/manylinux1-check.py > $MY_DIR/manylinux1-check.py
curl -sL https://raw.githubusercontent.com/pypa/manylinux/master/docker/build_scripts/python-tag-abi-tag.py > $MY_DIR/python-tag-abi-tag.py

source $MY_DIR/build_utils.sh

# Compile the latest Python releases.
# (In order to have a proper SSL module, Python is compiled
# against a recent openssl [see env vars above], which is linked
# statically. We delete openssl afterwards.)
build_openssl $OPENSSL_ROOT $OPENSSL_HASH
mkdir -p /opt/python
build_cpythons $CPYTHON_VERSIONS
rm -rf /usr/local/ssl

# Install patchelf and auditwheel (latest with unreleased bug fixes)
curl -sL https://nipy.bic.berkeley.edu/manylinux/patchelf-0.9njs2.tar.gz > $MY_DIR/patchelf-0.9njs2.tar.gz
check_sha256sum $MY_DIR/patchelf-0.9njs2.tar.gz $PATCHELF_HASH
tar -xzf $MY_DIR/patchelf-0.9njs2.tar.gz
(cd $MY_DIR/patchelf-0.9njs2 && ./configure && make && make install)
rm -rf $MY_DIR/patchelf-0.9njs2.tar.gz patchelf-0.9njs2

PY35_BIN=/opt/python/cp35-cp35m/bin
$PY35_BIN/pip install auditwheel
ln -s $PY35_BIN/auditwheel /usr/local/bin/auditwheel

# Clean up development headers and other unnecessary stuff for
# final image
yum -y erase wireless-tools gtk2 libX11 hicolor-icon-theme \
    avahi freetype bitstream-vera-fonts \
    ${PYTHON_COMPILE_DEPS}  > /dev/null 2>&1
yum -y install ${MANYLINUX1_DEPS}
yum -y clean all > /dev/null 2>&1
yum list installed
# we don't need libpython*.a, and they're many megabytes
find /opt/_internal -name '*.a' -print0 | xargs -0 rm -f
# Strip what we can -- and ignore errors, because this just attempts to strip
# *everything*, including non-ELF files:
find /opt/_internal -type f -print0 \
    | xargs -0 -n1 strip --strip-unneeded 2>/dev/null || true
# We do not need the Python test suites, or indeed the precompiled .pyc and
# .pyo files. Partially cribbed from:
#    https://github.com/docker-library/python/blob/master/3.4/slim/Dockerfile
find /opt/_internal \
     \( -type d -a -name test -o -name tests \) \
  -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
  -print0 | xargs -0 rm -f

for PYTHON in /opt/python/*/bin/python; do
    $PYTHON $MY_DIR/manylinux1-check.py
done
