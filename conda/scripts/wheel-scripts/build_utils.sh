#!/bin/bash
# Helper utilities for build

PYTHON_DOWNLOAD_URL=https://www.python.org/ftp/python
OPENSSL_DOWNLOAD_URL=http://www.openssl.org/source
GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py


function check_var {
    if [ -z "$1" ]; then
        echo "required variable not defined"
        exit 1
    fi
}


function lex_pyver {
    # Echoes Python version string padded with zeros
    # Thus:
    # 3.2.1 -> 003002001
    # 3     -> 003000000
    echo $1 | awk -F "." '{printf "%03d%03d%03d", $1, $2, $3}'
}


function do_cpython_build {
    local py_ver=$1
    check_var $py_ver
    local ucs_setting=$2
    check_var $ucs_setting
    tar -xzf Python-$py_ver.tgz
    pushd Python-$py_ver
    if [ "$ucs_setting" = "none" ]; then
        unicode_flags=""
        dir_suffix=""
    else
        local unicode_flags="--enable-unicode=$ucs_setting"
        local dir_suffix="-$ucs_setting"
    fi
    local prefix="/opt/_internal/cpython-${py_ver}${dir_suffix}"
    sudo mkdir -p ${prefix}/lib
    sudo chown vagrant:vagrant -R ${prefix}
    # -Wformat added for https://bugs.python.org/issue17547 on Python 2.6
    CFLAGS="-Wformat" ./configure --prefix=${prefix} --disable-shared $unicode_flags > /dev/null
    make -j2 > /dev/null
    make install > /dev/null
    popd
    rm -rf Python-$py_ver
    # Some python's install as bin/python3. Make them available as
    # bin/python.
    if [ -e ${prefix}/bin/python3 ]; then
        ln -s python3 ${prefix}/bin/python
    fi
    ${prefix}/bin/python get-pip.py
    ${prefix}/bin/pip install wheel
    local abi_tag=$(${prefix}/bin/python ${MY_DIR}/python-tag-abi-tag.py)
    ln -s ${prefix} /opt/python/${abi_tag}
}


function build_cpython {
    local py_ver=$1
    check_var $py_ver
    check_var $PYTHON_DOWNLOAD_URL
    wget -q $PYTHON_DOWNLOAD_URL/$py_ver/Python-$py_ver.tgz
    if [ $(lex_pyver $py_ver) -lt $(lex_pyver 3.3) ]; then
        do_cpython_build $py_ver ucs2
        do_cpython_build $py_ver ucs4
    else
        do_cpython_build $py_ver none
    fi
    rm -f Python-$py_ver.tgz
}


function build_cpythons {
    check_var $GET_PIP_URL
    curl -sLO $GET_PIP_URL
    for py_ver in $@; do
        build_cpython $py_ver
    done
    rm get-pip.py
}


function do_openssl_build {
    ./config no-ssl2 no-shared -fPIC --prefix=/usr/local/ssl > /dev/null
    make > /dev/null
    sudo make install > /dev/null
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


function build_openssl {
    local openssl_fname=$1
    check_var ${openssl_fname}
    local openssl_sha256=$2
    check_var ${openssl_sha256}
    check_var ${OPENSSL_DOWNLOAD_URL}
    curl -sLO ${OPENSSL_DOWNLOAD_URL}/${openssl_fname}.tar.gz
    check_sha256sum ${openssl_fname}.tar.gz ${openssl_sha256}
    tar -xzf ${openssl_fname}.tar.gz
    (cd ${openssl_fname} && do_openssl_build)
    rm -rf ${openssl_fname} ${openssl_fname}.tar.gz
}
