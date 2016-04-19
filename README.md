This repository contains packer templates to build images compatible to build
[manylinux](https://github.com/pypa/manylinux) python wheels and conda packages.

The images are build using [packer](https://www.packer.io/). To build the images
yourself you have to install the newest version of packer and run the following
command.

```bash
packer build centos-5.11-x86_64-vagrant.json
```

Currently this only contains images targeting libvirt (qemu). I plan to add
virtualbox templates in the future. Until then
[vagrant-mutate](https://github.com/sciurus/vagrant-mutate) can be used to
convert the images to the virtualbox provider.
