# Add needed Freescale packages and definitions

# Add it into tools & Test applications group
RDEPENDS_${PN}-tools-testapps += "\
    imx-kobs \
    imx-vpu \
    canutils \
    bluez4 \
"

RDEPENDS_${PN}-gstreamer += " \
    gst-meta-debug \
"
