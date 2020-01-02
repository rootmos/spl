export CACHE ?= $(shell pwd)/.cache
export LOG_FILE ?= .log

run: raspberry.sh
	./$< -3

all: check raspberry.sh

define recipe
$(strip $(1)): $(strip $(1)).recipe $(shell bin/mk.sh -d < "$(strip $(1)).recipe")
	bin/mk.sh "$$@" < "$$<"
endef

$(eval $(call recipe, raspberry.sh))
$(eval $(call recipe, raspberry.kernel-menuconfig.sh))
$(eval $(call recipe, raspberry.busybox-menuconfig.sh))

menuconfig-kernel: raspberry.kernel-menuconfig.sh
	./$< $(shell pwd)/raspberry/kernel.config

menuconfig-busybox: raspberry.busybox-menuconfig.sh
	./$< $(shell pwd)/lib/busybox.config

clean:
	rm -rf raspberry.sh raspberry.*.sh .cache .toolchain .log

check:
	shellcheck --shell=bash --exclude=SC2001,SC2034,SC1090,SC2153 \
		$(shell git ls-files | grep '\.sh$$')

.PHONY: all clean check
.PHONY: menuconfig-kernel menuconfig-busybox
