# Patched file to only build needed dependencies for linguist
TEMPLATE = subdirs

SUBDIRS = \
    uiplugin \
    uitools

uitools.depends = uiplugin
