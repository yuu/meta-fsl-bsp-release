# Copyright (C) 2013-14 Freescale Semiconductor

require recipes-graphics/gpu-viv-g2d/gpu-viv-g2d.inc

LIC_FILES_CHKSUM = "file://usr/include/g2d.h;endline=7;md5=861ebad4adc7236f8d1905338abd7eb2"

SRC_URI[md5sum] = "1e3f6e6f24c754d797f31c94949d5fc0"
SRC_URI[sha256sum] = "5552e72ff7141a3e71631c239e282b42ebc542d062ed42541e947c018dfbccf1"

FILES_${PN} += " ${bindir}/gmem_info "
FILES_${PN}-dbg += "$ {bindir}/.debug/gmem_info"
FILES_${PN} += " ${libdir}/libg2d-viv${SOLIBS} "
