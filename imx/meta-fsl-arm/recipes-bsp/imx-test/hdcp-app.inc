SUMMARY = "Test programs for IMX BSP"
DESCRIPTION = "Linux HDCP test application for imx6 platform"
SECTION = "base"
LICENSE = "Proprietary"

inherit fsl-eula-unpack

SRC_URI = "${FSL_MIRROR}/hdcp-app-${PV}.bin;fsl-eula=true"
S = "${WORKDIR}/${PN}-${PV}"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

do_install() {
        install -d ${D}/unit_tests
	install -m 755 ${S}/*.out ${D}/unit_tests/
}

FILES_${PN} += "/unit_tests"
#FILES_${PN}-dbg += "/unit_tests/.debug"

PACKAGE_ARCH = "${MACHINE_ARCH}"

