# Patched file to only build linguist
TEMPLATE = subdirs

qtHaveModule(widgets) {
    no-png {
        message("Some graphics-related tools are unavailable without PNG support")
    } else {
        QT_FOR_CONFIG += widgets
        qtConfig(pushbutton):qtConfig(toolbutton) {
            SUBDIRS = designer

            linguist.depends = designer
        }
    }
}

SUBDIRS += linguist \
    qtattributionsscanner

win32|winrt:SUBDIRS += windeployqt

# This is necessary to avoid a race condition between toolchain.prf
# invocations in a module-by-module cross-build.
cross_compile:isEmpty(QMAKE_HOST_CXX.INCDIRS) {
    windeployqt.depends += qtattributionsscanner
    linguist.depends += qtattributionsscanner
}
