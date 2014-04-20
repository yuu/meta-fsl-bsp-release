#!/bin/sh
#
# FSL Yocto nightly build script to build combined. This will not do a complete clean build 
# and is run nightly on the build servers running Jenkins
#
# Copyright (C) 2013-14 Freescale Semiconductor
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA


# set unset variables
if [ -z "$image" ]; then
   image='fsl-image-x11'
   echo Setting image to $image
fi

if [ -z "$WORKSPACE" ]; then
   WORKSPACE=$PWD
   echo Setting WORKSPACE to $WORKSPACE
fi

if [ -z "$branch" ]; then
   branch='imx-3.10.17-1.0.0_ga'
   echo Setting branch to $branch
fi

if [ ! -d "$WORKSPACE/temp_build_dir" ]; then
  # Create temp_build_dir if it does not exist.
  mkdir $WORKSPACE/temp_build_dir
fi

  # Clear out the images directory
  rm -rf $WORKSPACE/images_all

  # Directory to store the build binaries
  mkdir $WORKSPACE/images_all
  mkdir $WORKSPACE/images_all/imx_uboot
  mkdir $WORKSPACE/images_all/imx_sdk

  # Clear out the build space
  # Delete hidden files
  rm -rf $WORKSPACE/temp_build_dir/.??*
  # Leave the build folders in place, delete everything else. Trap the error when no files exists
  if [ -n "$(find $WORKSPACE/temp_build_dir/* -maxdepth 0 -name 'build_*' -prune -o -exec rm -rf '{}' ';')" ]; then
    echo "Cleaned the build space"
  else
    echo "No files in build space"
  fi
  cd $WORKSPACE/temp_build_dir

  repo init -u git://git.freescale.com/imx/fsl-arm-yocto-bsp.git -b $branch
  repo sync

  # copy the machine configuration files to meta-fsl-arm
  if [ -e $WORKSPACE/temp_build_dir/sources/meta-fsl-bsp-release/imx/meta-fsl-arm/conf/machine ]; then
      cp -r $WORKSPACE/temp_build_dir/sources/meta-fsl-bsp-release/imx/meta-fsl-arm/conf/machine $WORKSPACE/temp_build_dir/sources/meta-fsl-arm/conf
  fi

  # Delete the old configuration file and recreate it
  rm -rf $WORKSPACE/temp_build_dir/build_all/conf

  EULA=1 MACHINE=imx6qdlsolo . ./fsl-setup-release.sh -b build_all
  echo "INHERIT += \"rm_work\"" >> conf/local.conf

  echo "UBOOT_CONFIG = \"sd\"" >> conf/local.conf
  echo "FSL_KERNEL_DEFCONFIG = \"imx_v7_defconfig\"" >> conf/local.conf

  bitbake -c cleanall imx-lib
  bitbake -c cleanall firmware-imx
  bitbake -c cleanall gpu-viv-bin-mx6q
  bitbake -c cleanall xf86-video-imxfb-vivante
  bitbake -c cleanall xserver-xorg
  bitbake -c cleanall libfslvpuwrap
  bitbake -c cleanall fsl-alsa-plugins
  bitbake -c cleanall gst-plugins-gl
  bitbake -c cleanall u-boot-imx
  bitbake -c cleanall imx-kobs
  bitbake -c cleanall udev-extraconf
  bitbake -c cleanall mesa
  bitbake -c cleanall linux-imx
  bitbake -c cleanall gst-fsl-plugin
  bitbake -c cleanall libfslparser
  bitbake -c cleanall libfslcodec
  bitbake -c cleanall imx-test
  bitbake -c cleanall packagegroup-base
  bitbake -c cleanall packagegroup-fsl
  bitbake -c cleanall imx-uuc
  bitbake -c cleanall cryptodev
  bitbake -c cleanall cryptodev-headers
  bitbake -c cleanall openssl
  bitbake -c cleanall openssl-native

  bitbake -c deploy linux-imx -f
  bitbake -c deploy u-boot-imx -f

  # build imx6qdlsolo full image first
  bitbake $image

  if $sdk; then
     bitbake $image -c populate_sdk
      mv $WORKSPACE/temp_build_dir/build_all/tmp/deploy/sdk/* $WORKSPACE/images_all/imx_sdk
  fi

  ## make manufacturing tool image and kernel with mfg config
  echo "FSL_KERNEL_DEFCONFIG = \"imx_v7_mfg_defconfig\"" >> conf/local.conf
  bitbake -c cleansstate linux-imx
  bitbake -c deploy linux-imx
  bitbake fsl-image-manufacturing
  cd $WORKSPACE/temp_build_dir/build_all/tmp/deploy/images

  # bitbake change to machine directories
  if [ -e imx6qdlsolo ] ; then
    cd imx6qdlsolo
  fi
  mkimage -A arm -O linux -T ramdisk -a 0x12c00000 -n "initramfs" -d fsl-image-manufacturing-imx6qdlsolo.cpio.gz initramfs.cpio.gz.uboot

  mv $WORKSPACE/temp_build_dir/build_all/tmp/deploy/images/imx6qdlsolo $WORKSPACE/images_all/

  cd $WORKSPACE/temp_build_dir/build_all

  # add ixm6qsabresd even though it is part of imx6qdlsolo

  # build sd uboot for all core machines

  MACHINE=imx6qsabresd              bitbake u-boot-imx -c cleansstate
  MACHINE=imx6qsabresd              bitbake u-boot-imx -c deploy -f
  board='imx6qsabresd'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6qsabresd_sd.imx
  MACHINE=imx6qsabreauto            bitbake u-boot-imx -c cleansstate
  MACHINE=imx6qsabreauto            bitbake u-boot-imx -c deploy -f
  board='imx6qsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6qsabreauto_sd.imx
  MACHINE=imx6dlsabresd             bitbake u-boot-imx -c cleansstate
  MACHINE=imx6dlsabresd             bitbake u-boot-imx -c deploy -f
  board='imx6dlsabresd'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6dlsabresd_sd.imx
  MACHINE=imx6dlsabreauto           bitbake u-boot-imx -c cleansstate
  MACHINE=imx6dlsabreauto           bitbake u-boot-imx -c deploy -f
  board='imx6dlsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6dlsabreauto_sd.imx
  MACHINE=imx6solosabresd           bitbake u-boot-imx -c cleansstate
  MACHINE=imx6solosabresd           bitbake u-boot-imx -c deploy -f
  board='imx6solosabresd'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6solosabresd_sd.imx
  MACHINE=imx6solosabreauto         bitbake u-boot-imx -c cleansstate
  MACHINE=imx6solosabreauto         bitbake u-boot-imx -c deploy -f
  board='imx6solosabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6solosabreauto_sd.imx

  echo "UBOOT_CONFIG = \"sata\"" >> conf/local.conf
  MACHINE=imx6qsabresd              bitbake u-boot-imx -c cleansstate
  MACHINE=imx6qsabresd              bitbake u-boot-imx -c deploy
  board='imx6qsabresd'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6qsabresd_sata.imx
  MACHINE=imx6qsabreauto            bitbake u-boot-imx -c cleansstate
  MACHINE=imx6qsabreauto            bitbake u-boot-imx -c deploy
  board='imx6qsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6qsabreauto_sata.imx

  echo "UBOOT_CONFIG = \"eimnor\"" >> conf/local.conf
  MACHINE=imx6qsabreauto    bitbake u-boot-imx -c cleansstate
  MACHINE=imx6qsabreauto    bitbake u-boot-imx -c deploy
  board='imx6qsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6qsabreauto_eim-nor.imx

  MACHINE=imx6dlsabreauto   bitbake u-boot-imx -c cleansstate
  MACHINE=imx6dlsabreauto   bitbake u-boot-imx -c deploy
  board='imx6dlsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6dlsabreauto_eim-nor.imx

  MACHINE=imx6solosabreauto bitbake u-boot-imx -c cleansstate
  MACHINE=imx6solosabreauto bitbake u-boot-imx -c deploy
  board='imx6solosabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6solosabreauto_eim-nor.imx

  echo "UBOOT_CONFIG = \"spinor\"" >> conf/local.conf
  MACHINE=imx6qsabreauto       bitbake u-boot-imx -c cleansstate
  MACHINE=imx6qsabreauto       bitbake u-boot-imx -c deploy
  board='imx6qsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6qsabreauto_spi-nor.imx
  MACHINE=imx6dlsabreauto      bitbake u-boot-imx -c cleansstate
  MACHINE=imx6dlsabreauto      bitbake u-boot-imx -c deploy
  board='imx6dlsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6dlsabreauto_spi-nor.imx
  MACHINE=imx6solosabreauto    bitbake u-boot-imx -c cleansstate
  MACHINE=imx6solosabreauto    bitbake u-boot-imx -c deploy
  board='imx6solosabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6solosabreauto_spi-nor.imx

  MACHINE=imx6slevk    bitbake u-boot-imx -c cleansstate
  MACHINE=imx6slevk    bitbake u-boot-imx -c deploy
  board='imx6slevk'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6slevk_spi-nor.imx

  echo "UBOOT_CONFIG = \"nand\"" >> conf/local.conf
  MACHINE=imx6qsabreauto       bitbake u-boot-imx -c cleansstate
  MACHINE=imx6qsabreauto       bitbake u-boot-imx -c deploy
  board='imx6qsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6qsabreauto_nand.imx
  MACHINE=imx6dlsabreauto      bitbake u-boot-imx -c cleansstate
  MACHINE=imx6dlsabreauto      bitbake u-boot-imx -c deploy
  board='imx6dlsabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6dlsabreauto_nand.imx
  MACHINE=imx6solosabreauto    bitbake u-boot-imx -c cleansstate
  MACHINE=imx6solosabreauto    bitbake u-boot-imx -c deploy
  board='imx6solosabreauto'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6solosabreauto_nand.imx

  # build entire image for slevk - so many differences
  echo "FSL_KERNEL_DEFCONFIG = \"imx_v7_defconfig\"" >> conf/local.conf
  echo "UBOOT_CONFIG = \"sd\"" >> conf/local.conf
  MACHINE=imx6slevk          bitbake gpu-viv-bin-mx6q -c cleanall
  MACHINE=imx6slevk          bitbake mesa -c cleanall
  MACHINE=imx6slevk          bitbake gst-fsl-plugin -c cleansstate
  MACHINE=imx6slevk          bitbake imx-test -c cleansstate
  MACHINE=imx6slevk          bitbake linux-imx -c cleansstate
  MACHINE=imx6slevk          bitbake u-boot-imx -c cleansstate
  MACHINE=imx6slevk          bitbake packagegroup-base -c cleansstate
  MACHINE=imx6slevk          bitbake packagegroup-fsl -c cleansstate
  MACHINE=imx6slevk          bitbake -c cleansstate gst-fsl-plugin
  MACHINE=imx6slevk          bitbake -c cleansstate libfslparser
  MACHINE=imx6slevk          bitbake -c cleansstate libfslcodec
  MACHINE=imx6slevk          bitbake -c cleansstate cryptodev-headers
  MACHINE=imx6slevk          bitbake -c cleansstate openssl
  MACHINE=imx6slevk          bitbake -c cleansstate openssl-native
  MACHINE=imx6slevk          bitbake -c cleansstate cryptodev
  MACHINE=imx6slevk          bitbake linux-imx -f -c deploy

  MACHINE=imx6slevk          bitbake $image
  board='imx6slevk'
  cp tmp/deploy/images/$board/u-boot-$board.imx $WORKSPACE/images_all/imx_uboot/u-boot-imx6slevk_sd.imx

  ## make manufacturing tool image
  echo "FSL_KERNEL_DEFCONFIG = \"imx_v7_mfg_defconfig\"" >> conf/local.conf
  MACHINE=imx6slevk          bitbake -c cleansstate linux-imx
  MACHINE=imx6slevk          bitbake -c deploy linux-imx
  MACHINE=imx6slevk          bitbake fsl-image-manufacturing
  cd $WORKSPACE/temp_build_dir/build_all/tmp/deploy/images

  # tar up the sd card image and rootfs
  if [ -e imx6slevk ] ; then
    cd imx6slevk
  fi

  mkimage -A arm -O linux -T ramdisk -a 0x12c00000 -n "initramfs" -d fsl-image-manufacturing-imx6slevk.cpio.gz initramfs.cpio.gz.uboot

  cd $WORKSPACE/temp_build_dir/build_all/tmp/deploy/images
  if [ -e imx6slevk ] ; then
    cd imx6slevk
  fi

  # Copy the output binaries
  cd $WORKSPACE
  mv $WORKSPACE/temp_build_dir/build_all/tmp/deploy/images/imx6slevk $WORKSPACE/images_all/


  # remove these to avoid confusion
  rm -rf $WORKSPACE/images_all/imx6qdlsolo/uImage*.bin
  rm -rf $WORKSPACE/images_all/imx6qdlsolo/uImage
  rm -rf $WORKSPACE/images_all/imx6slevk/uImage*.bin
  rm -rf $WORKSPACE/images_all/imx6slevk/uImage
  rm -rf $WORKSPACE/images_all/imx6qdlsolo/u-boot*
  rm -rf $WORKSPACE/images_all/imx6slevk/u-boot*

  cd $WORKSPACE

  tar cfz images_all_consolidated.tar.gz images_all
  cd images_all/imx6qdlsolo
  tar cfz $image-imx6qdlsolo.sdcard.tar.gz $image-imx6qdlsolo.sdcard
  tar cfz $image-imx6qdlsolo.bz2.tar.gz    $image-imx6qdlsolo.tar.bz2
  cd ../..

  rm -rf images_all/imx_all
  mkdir images_all/imx_all
  mv images_all_consolidated.tar.gz images_all/imx_all
