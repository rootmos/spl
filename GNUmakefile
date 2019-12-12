export CACHE ?= $(shell pwd)/.cache
export TOOLCHAIN_PREFIX ?= $(shell pwd)/.toolchain
export LOG_FILE ?= .log

run: raspberry.sh
	./$<

all: check raspberry.sh

raspberry.sh: lib/preamble.sh lib/fetch.sh \
	raspberry/kernel.config raspberry/toolchain.sh raspberry/main.sh
	cat lib/preamble.sh > $@
	cat lib/fetch.sh >> $@
	bin/bundle.sh kernel_config < raspberry/kernel.config >> $@
	cat raspberry/toolchain.sh >> $@
	cat raspberry/main.sh >> $@
	chmod +x $@

menuconfig: raspberry.sh
	MENUCONFIG=$(shell pwd)/raspberry/kernel.config ./raspberry.sh

clean:
	rm -rf raspberry.sh .cache .toolchain .log

check:
	shellcheck --shell=bash $(shell git ls-files | grep '\.sh$$')

.PHONY: all clean check
.PHONY: menuconfig
