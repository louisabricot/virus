#!/bin/sh

# https://wiki.qemu.org/Documentation/Platforms/RISCV

# Downloading the missing qemu package 
mkdir $HOME/.local/qemu
dpkg download qemu-system-misc $HOME/.local/qemu
export PATH="$PATH:$HOME/.local/qemu/usr/bin"

# Downloading the Fedora VM for qemu risc-v
cd /goinfre/$USER
wget https://dl.fedoraproject.org/pub/alt/risc-v/repo/virt-builder-images/images/Fedora-Minimal-Rawhide-20200108.n.0-fw_payload-uboot-qemu-virt-smode.elf
wget https://dl.fedoraproject.org/pub/alt/risc-v/repo/virt-builder-images/images/Fedora-Minimal-Rawhide-20200108.n.0-sda.raw.xz
unxz Fedora-Minimal-Rawhide-*-sda.raw.xz

qemu-system-riscv64 \
   -nographic \
   -machine virt \
   -smp 4 \
   -m 2G \
   -kernel /goinfre/$USER/Fedora-Minimal-Rawhide-*-fw_payload-uboot-qemu-virt-smode.elf \
   -bios none \
   -object rng-random,filename=/dev/urandom,id=rng0 \
   -device virtio-rng-device,rng=rng0 \
   -device virtio-blk-device,drive=hd0 \
   -drive file=/goinfre/$USER/Fedora-Minimal-Rawhide-20200108.n.0-sda.raw,format=raw,id=hd0 \
   -device virtio-net-device,netdev=usernet \
   -netdev user,id=usernet,hostfwd=tcp::10000-:22
