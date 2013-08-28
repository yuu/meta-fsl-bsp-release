# Copyright (C) 2013 Freescale Semiconductor
# Released under the MIT license (see COPYING.MIT for the terms)
DESCRIPTION = "Freescale Multimedia VPU wrapper"
DEPENDS = "imx-lib"
LICENSE = "Proprietary"
SECTION = "multimedia"
LIC_FILES_CHKSUM = "file://EULA.txt;md5=93b784b1c11b3fffb1638498a8dde3f6"

DEPENDS = "imx-vpu"

inherit fsl-eula-unpack autotools pkgconfig

SRC_URI = "${FSL_MIRROR}/${PN}-3.10.9-1.0.0.bin;fsl-eula=true"
S = "${WORKDIR}/${PN}-3.10.9-1.0.0"
SRC_URI[md5sum] = "c24cb5d9fc0e4efe6b01743ebec4167d"
SRC_URI[sha256sum] = "a9acf35404a507d29e99974e3b1f7b2c9f53fa4e34fea19d5590c849d7de999d"


do_install_append() {
    # FIXME: Drop examples for now
    rm -r ${D}${datadir}/imx-mm
}

PACKAGE_ARCH = "${MACHINE_ARCH}"
COMPATIBLE_MACHINE = "(mx6)"