
# only include this change for X11 backend

DEPENDS += "virtual/xserver xserver-xorg-extension-viv-hdmi"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI = "file://rc.local.etc \
	  file://rc.local.init \
           file://LICENSE"

