EARSAVER_VERSION = 1
EARSAVER_SITE = https://github.com/sensorium/earsaver-lv2
EARSAVER_SITE_METHOD = git
EARSAVER_BUNDLES = EarSaver.lv2
EARSAVER_BUILD_CMD = $(TARGET_MAKE_ENV) $(TARGET_CONFIGURE_OPTS) \
    hvcc EarSaver.pd \
    -o /tmp/earsaver-build \
    -n EarSaver \
    -g dpf \
    --dpf-path $(BUILD_DIR)/../dpf
EARSAVER_INSTALL_CMD = cp -r EarSaver.lv2 $(TARGET_DIR)/usr/lib/lv2/

$(eval $(generic-package))