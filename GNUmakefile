export CACHE ?= $(shell pwd)/.cache
export TOOLCHAIN_PREFIX ?= $(shell pwd)/.toolchain
export LOG_FILE ?= .log

run: raspberry.sh
	./$<

all: check raspberry.sh

raspberry.sh: lib/preamble.sh  lib/log.sh lib/cache.sh \
	lib/initramfs.sh lib/fetch.sh \
	raspberry/versions.sh \
	raspberry/toolchain.sh raspberry/kernel.config raspberry/kernel.sh \
	lib/busybox.config lib/busybox.sh \
	raspberry/main.sh
	cat lib/preamble.sh > $@
	cat lib/log.sh >> $@
	cat lib/cache.sh >> $@
	cat lib/fetch.sh >> $@
	cat lib/initramfs.sh >> $@
	cat raspberry/versions.sh >> $@
	cat raspberry/toolchain.sh >> $@
	bin/bundle.sh kernel_config < raspberry/kernel.config >> $@
	cat raspberry/kernel.sh >> $@
	bin/bundle.sh busybox_config < lib/busybox.config >> $@
	cat lib/busybox.sh >> $@
	cat raspberry/main.sh >> $@
	chmod +x $@

raspberry.kernel.sh: lib/preamble.sh lib/log.sh lib/cache.sh \
	lib/fetch.sh \
	raspberry/versions.sh \
	raspberry/toolchain.sh raspberry/kernel.config raspberry/kernel.sh
	cat lib/preamble.sh > $@
	cat lib/log.sh >> $@
	cat lib/cache.sh >> $@
	cat lib/fetch.sh >> $@
	cat raspberry/versions.sh >> $@
	cat raspberry/toolchain.sh >> $@
	bin/bundle.sh kernel_config < raspberry/kernel.config >> $@
	cat raspberry/kernel.sh >> $@
	echo 'kernel_menuconfig "$$1"' >> $@
	chmod +x $@

raspberry.busybox.sh: lib/preamble.sh lib/log.sh lib/cache.sh \
	lib/fetch.sh \
	raspberry/versions.sh \
	raspberry/toolchain.sh \
	lib/busybox.config lib/busybox.sh
	cat lib/preamble.sh > $@
	cat lib/log.sh >> $@
	cat lib/cache.sh >> $@
	cat lib/fetch.sh >> $@
	cat raspberry/versions.sh >> $@
	cat raspberry/toolchain.sh >> $@
	bin/bundle.sh busybox_config < lib/busybox.config >> $@
	cat lib/busybox.sh >> $@
	echo 'busybox_menuconfig "$$1"' >> $@
	chmod +x $@

menuconfig-kernel: raspberry.kernel.sh
	./$< $(shell pwd)/raspberry/kernel.config

menuconfig-busybox: raspberry.busybox.sh
	./$< $(shell pwd)/lib/busybox.config

clean:
	rm -rf raspberry.sh raspberry.*.sh .cache .toolchain .log

check:
	shellcheck --shell=bash --exclude=SC2001,SC2034 \
		$(shell git ls-files | grep '\.sh$$')

.PHONY: all clean check
.PHONY: menuconfig-kernel menuconfig-busybox
