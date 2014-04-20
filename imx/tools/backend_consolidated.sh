#!/bin/sh
#
# FSL Yocto backend build script. This will not hook in internal layer and build only with release layer

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
if [ -z "$WORKSPACE" ]; then
   WORKSPACE=$PWD
   echo Setting WORKSPACE to $WORKSPACE
fi

if [ -z "$branch" ]; then
   branch='imx-3.10.9-1.0.0_ga'
   echo Setting branch to $branch
fi

if $clean; then
   rm -rf  $WORKSPACE/temp_build_dir
fi

if [ ! -d "$WORKSPACE/temp_build_dir" ]; then
  # Create temp_build_dir if it does not exist.
  mkdir $WORKSPACE/temp_build_dir
fi

# Clear out the images directory
rm -rf $WORKSPACE/images_all

# Directory to store the build binaries
mkdir $WORKSPACE/images_all
mkdir $WORKSPACE/images_all/dfb
mkdir $WORKSPACE/images_all/dfb/imx_sdk
mkdir $WORKSPACE/images_all/fb
mkdir $WORKSPACE/images_all/fb/imx_sdk
mkdir $WORKSPACE/images_all/wayland
mkdir $WORKSPACE/images_all/wayland/imx_sdk
mkdir $WORKSPACE/images_all/imx6_all

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

# Setup the environment based on the board
repo init -u git://git.freescale.net/imx/fsl-arm-yocto-bsp.git -b $branch
repo sync

# copy the machine configuration files to meta-fsl-arm
if [ -e $WORKSPACE/temp_build_dir/sources/meta-fsl-bsp-release/imx/meta-fsl-arm/conf/machine ]; then
   cp -r $WORKSPACE/temp_build_dir/sources/meta-fsl-bsp-release/imx/meta-fsl-arm/conf/machine $WORKSPACE/temp_build_dir/sources/meta-fsl-arm/conf
fi

# Delete the old configuration file and recreate it
rm -rf $WORKSPACE/temp_build_dir/build_dfb/conf
rm -rf $WORKSPACE/temp_build_dir/build_fb/conf
rm -rf $WORKSPACE/temp_build_dir/build_wayland/conf

if [- e "$WORKSPACE/temp_build_dir/build_dfb" ]; then
   EULA=1 MACHINE=imx6qdlsolo . ./setup-environment build_dfb
else
    echo "setup dfb builds"
#    EULA=1 MACHINE=imx6qdlsolo . ./setup-environment build_dfb
#    echo "INHERIT += \"rm_work\"" >> conf/local.conf
#    cd $WORKSPACE/temp_build_dir
    EULA=1 MACHINE=imx6qdlsolo . ./fsl-setup-release.sh -b build_dfb -e dfb
    echo "INHERIT += \"rm_work\"" >> conf/local.conf
fi

#start the dfb builds first
cd $WORKSPACE/temp_build_dir/build_dfb

bitbake -c cleanall imx-lib
bitbake -c cleanall firmware-imx
bitbake -c cleanall gpu-viv-bin-mx6q
bitbake -c cleanall libfslvpuwrap
bitbake -c cleanall fsl-alsa-plugins
bitbake -c cleanall u-boot-imx
bitbake -c cleanall linux-imx
bitbake -c cleanall gst-fsl-plugin
bitbake -c cleanall libfslparser
bitbake -c cleanall libfslcodec
bitbake -c cleanall imx-test
rm -rf tmp/deploy

# Build the image
bitbake fsl-image-dfb

if $sdk; then
  bitbake fsl-image-dfb -c populate_sdk
  mv $WORKSPACE/temp_build_dir/build_dfb/tmp/deploy/sdk/* $WORKSPACE/images_all/dfb/imx_sdk
fi


# build entire image for slevk - so many differences
MACHINE=imx6slevk          bitbake gst-fsl-plugin -c cleansstate
MACHINE=imx6slevk          bitbake gpu-viv-bin-mx6q -c cleansstate
MACHINE=imx6slevk          bitbake imx-test -c cleansstate
MACHINE=imx6slevk          bitbake linux-imx -c cleansstate
MACHINE=imx6slevk          bitbake u-boot-imx -c cleansstate
MACHINE=imx6slevk          bitbake packagegroup-base -c cleansstate
MACHINE=imx6slevk          bitbake packagegroup-fsl -c cleansstate
MACHINE=imx6slevk          bitbake fsl-image-dfb

# Copy the output binaries
mv $WORKSPACE/temp_build_dir/build_dfb/tmp/deploy/images/* $WORKSPACE/images_all/dfb

cd $WORKSPACE/temp_build_dir

if [ -e "$WORKSPACE/temp_build_dir/build_fb" ]; then
   echo "fb build already exists"
   EULA=1 MACHINE=imx6qdlsolo . ./setup-environment build_fb
else
   echo "Setup fb builds"
   cd $WORKSPACE/temp_build_dir
#   EULA=1 MACHINE=imx6qdlsolo . ./setup-environment build_fb
#   echo "INHERIT += \"rm_work\"" >> conf/local.conf
#   cd $WORKSPACE/temp_build_dir
   EULA=1 MACHINE=imx6qdlsolo . ./fsl-setup-release.sh -b build_fb -e fb
   echo "INHERIT += \"rm_work\"" >> conf/local.conf
fi

#start the fb builds second
cd $WORKSPACE/temp_build_dir/build_fb
bitbake -c cleansstate gpu-viv-bin-mx6q
rm -rf tmp/deploy

# FIXME: sidestep a provider issue
echo "PREFERRED_PROVIDER_virtual/mesa = \"\"" >> conf/local.conf

# Build the image
bitbake fsl-image-fb

if $sdk; then
  bitbake fsl-image-fb -c populate_sdk
  mv $WORKSPACE/temp_build_dir/build_fb/tmp/deploy/sdk/* $WORKSPACE/images_all/fb/imx_sdk
fi


# build entire image for slevk - so many differences
MACHINE=imx6slevk          bitbake gst-fsl-plugin -c cleansstate
MACHINE=imx6slevk          bitbake gpu-viv-bin-mx6q -c cleansstate
MACHINE=imx6slevk          bitbake imx-test -c cleansstate
MACHINE=imx6slevk          bitbake linux-imx -c cleansstate
MACHINE=imx6slevk          bitbake u-boot-imx -c cleansstate
MACHINE=imx6slevk          bitbake packagegroup-base -c cleansstate
MACHINE=imx6slevk          bitbake packagegroup-fsl -c cleansstate
MACHINE=imx6slevk          bitbake fsl-image-fb

# Copy the output binaries
mv $WORKSPACE/temp_build_dir/build_fb/tmp/deploy/images/* $WORKSPACE/images_all/fb

cd $WORKSPACE
if [ -e "$WORKSPACE/temp_build_dir/build_wayland" ]; then
   echo "wayland build already exists"
   EULA=1 MACHINE=imx6qdlsolo . ./setup-environment build_wayland
else
   echo "Setup wayland builds"
   cd $WORKSPACE/temp_build_dir
#   EULA=1 MACHINE=imx6qdlsolo . ./setup-environment build_wayland
#   echo "INHERIT += \"rm_work\"" >> conf/local.conf
#   cd $WORKSPACE/temp_build_dir
   EULA=1 MACHINE=imx6qdlsolo . ./fsl-setup-release.sh -b build_wayland -e wayland
   echo "INHERIT += \"rm_work\"" >> conf/local.conf
fi

#start the  wayland build second
cd $WORKSPACE/temp_build_dir/build_wayland
bitbake -c cleansstate gpu-viv-bin-mx6q
bitbake -c clean gpu-viv-bin-mx6q
rm -rf tmp/deploy

# FIXME: sidestep a provider issue
echo "PREFERRED_PROVIDER_virtual/mesa = \"\"" >> conf/local.conf

# Build the image
bitbake fsl-image-weston

if $sdk; then
  bitbake fsl-image-weston -c populate_sdk
  mv $WORKSPACE/temp_build_dir/build_wayland/tmp/deploy/sdk/* $WORKSPACE/images_all/wayland/imx_sdk
fi


# build entire image for slevk - so many differences
MACHINE=imx6slevk          bitbake gst-fsl-plugin -c cleansstate
MACHINE=imx6slevk          bitbake gpu-viv-bin-mx6q -c cleansstate
MACHINE=imx6slevk          bitbake imx-test -c cleansstate
MACHINE=imx6slevk          bitbake linux-imx -c cleansstate
MACHINE=imx6slevk          bitbake u-boot-imx -c cleansstate
MACHINE=imx6slevk          bitbake packagegroup-base -c cleansstate
MACHINE=imx6slevk          bitbake packagegroup-fsl -c cleansstate
MACHINE=imx6slevk          bitbake fsl-image-weston

# Copy the output binaries
mv $WORKSPACE/temp_build_dir/build_wayland/tmp/deploy/images/* $WORKSPACE/images_all/wayland


  # remove these to avoid confusion
  rm $WORKSPACE/images_all/wayland/imx6qdlsolo/uImage
  rm $WORKSPACE/images_all/wayland/imx6qdlsolo/u-boot*

  rm $WORKSPACE/images_all/dfb/imx6qdlsolo/uImage
  rm $WORKSPACE/images_all/dfb/imx6qdlsolo/u-boot*
  rm $WORKSPACE/images_all/dfb/imx6slevk/uImage
  rm $WORKSPACE/images_all/dfb/imx6slevk/u-boot*

  rm $WORKSPACE/images_all/fb/imx6qdlsolo/uImage
  rm $WORKSPACE/images_all/fb/imx6qdlsolo/u-boot*
  rm $WORKSPACE/images_all/fb/imx6slevk/uImage
  rm $WORKSPACE/images_all/fb/imx6slevk/u-boot*
