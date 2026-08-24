How the images are built:

Each image is built automatically in the
[anyvm-org/rocky-builder](https://github.com/anyvm-org/rocky-builder)
repo's GitHub Actions: it downloads the official Rocky Linux
GenericCloud image, customizes it (serial console, ssh, first-boot
setup), boots it in QEMU, pre-installs the packages listed in the conf,
and exports the disk as a compressed qcow2 image. No interactive
installer is run.

Upstream media: the official Rocky Linux cloud images from
https://download.rockylinux.org/pub/rocky/ (download page:
https://rockylinux.org/download).
