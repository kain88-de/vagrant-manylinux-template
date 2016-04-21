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

MINICONDA2_HASH=42dac45eee5e58f05f37399adda45e85
MINICONDA3_HASH=b1b15a3436bb7de1da3ccc6e08c7a5df

# go back to normal user
# su vagrant

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
