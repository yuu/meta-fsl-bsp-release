# Copyright (C) 2013-14 Freescale Semiconductor
# Released under the MIT license (see COPYING.MIT for the terms)

require libfslcodec.inc

SRC_URI = "${FSL_MIRROR}/${PN}-${PV}.bin;fsl-eula=true"
S = "${WORKDIR}/${PN}-${PV}"

SRC_URI[md5sum] = "dd44ca15b88b79f8f958380bdf94a753"
SRC_URI[sha256sum] = "510b5362f7e357f05d4c9c059c2688733aa5df617d357c7c55e2ca3fa4be8654"

COMPATIBLE_MACHINE = "(mx28|mx5|mx6)"
