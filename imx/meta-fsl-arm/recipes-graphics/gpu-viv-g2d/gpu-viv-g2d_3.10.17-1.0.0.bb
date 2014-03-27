# Copyright (C) 2013-14 Freescale Semiconductor

require recipes-graphics/gpu-viv-g2d/gpu-viv-g2d.inc

LIC_FILES_CHKSUM = "file://usr/include/g2d.h;endline=7;md5=861ebad4adc7236f8d1905338abd7eb2"

SRC_URI[md5sum] = "008d6e51b148aa55660f335d4a51c26e"
SRC_URI[sha256sum] = "ddb6a8c153588e58e432381dee713d19e5013d39eefb43312e284d796c145bbb"

FILES_${PN} += " ${bindir}/gmem_info "
FILES_${PN}-dbg += "$ {bindir}/.debug/gmem_info"
FILES_${PN} += " ${libdir}/libg2d-viv${SOLIBS} "
