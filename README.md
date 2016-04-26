This repository contains packer templates to build images compatible to build
[manylinux](https://github.com/pypa/manylinux) python wheels and conda packages.

So far there are 3 different image-template. A minimal centos5 image, n image to
exclusively build conda package, it only offers the basic dependencies not
provided by conda itself, the last image ships everything to build many-linux
wheels, it contains all build dependencies and all allowed versions of python in
`/opt/python`.

Creating Images
===============

The images are build using [packer](https://www.packer.io/). To build the images
yourself you have to install the newest version of packer and run the following
command.

```bash
packer build centos-<version>.json
```

It can happen that the build stalls on random occassions (it can't find the
kickstart file or read some settings in it). In that case just restart the
build. I assume that this is a bug in the current packer version.

Virtual Box Images
==================

Currently this only contains images targeting libvirt (qemu). I plan to add
virtualbox templates in the future. Until then
[vagrant-mutate](https://github.com/sciurus/vagrant-mutate) can be used to
convert the images to the virtualbox provider.
