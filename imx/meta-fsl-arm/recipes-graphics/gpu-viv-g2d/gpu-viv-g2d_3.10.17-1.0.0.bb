# Copyright (C) 2013-14 Freescale Semiconductor

require recipes-graphics/gpu-viv-g2d/gpu-viv-g2d.inc

LIC_FILES_CHKSUM = "file://usr/include/g2d.h;endline=7;md5=861ebad4adc7236f8d1905338abd7eb2"

SRC_URI[md5sum] = "710a23fd6f3b966a7887169af39a509b"
SRC_URI[sha256sum] = "5eab1e0b280ac2840e7519eed69a1bc373b06a67fc990a6495722129dd32ce4d"

FILES_${PN} += " ${bindir}/gmem_info "
FILES_${PN}-dbg += "$ {bindir}/.debug/gmem_info"
FILES_${PN} += " ${libdir}/libg2d-viv${SOLIBS} "
