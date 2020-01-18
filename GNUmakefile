export CACHE ?= $(shell pwd)/.cache
export LOG_FILE ?= .log

all: check raspberry.sh debian.sh

test-raspberry: raspberry.sh
	./$< -1 -s example -o raspberry.img

test-debian: debian.sh
	./$< -o debian.img

define recipe
$(strip $(1)): $(strip $(1)).recipe $(shell bin/mk.sh -d < "$(strip $(1)).recipe")
	bin/mk.sh "$$@" < "$$<"
	shellcheck --exclude=SC2001,SC1090 "$$@"
endef

$(eval $(call recipe, raspberry.sh))
$(eval $(call recipe, raspberry.kernel-menuconfig.sh))
$(eval $(call recipe, raspberry.busybox-menuconfig.sh))
$(eval $(call recipe, debian.sh))
$(eval $(call recipe, debian.kernel-menuconfig.sh))

configure-raspberry-kernel1: raspberry.kernel-menuconfig.sh
	./$< -1 $(shell pwd)/raspberry/kernel1.config

configure-raspberry-kernel3: raspberry.kernel-menuconfig.sh
	./$< -3 $(shell pwd)/raspberry/kernel3.config

configure-raspberry-busybox: raspberry.busybox-menuconfig.sh
	./$< -1 $(shell pwd)/lib/busybox.config

configure-debian-kernel: debian.kernel-menuconfig.sh
	./$< $(shell pwd)/debian/kernel.config

clean:
	rm -rf raspberry.sh raspberry.*.sh debian.sh debian.*.sh .cache .log

check:
	shellcheck --shell=bash --exclude=SC2001,SC2034,SC1090,SC2153 \
		$(shell git ls-files | grep '\.sh$$')

.PHONY: all clean check
.PHONY: test-raspberry test-debian
.PHONY: configure-raspberry-kernel configure-raspberry-busybox
.PHONY: configure-debian-kernel
