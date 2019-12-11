export CACHE ?= $(shell pwd)/.cache

run: raspberry.sh
	bash ./$<

.PHONY: raspberry.sh
raspberry.sh:
	cat lib/preamble.sh > $@
	cat lib/fetch.sh >> $@
	bin/bundle.sh kernel_config < raspberry/kernel.config >> $@
	cat raspberry/toolchain.sh >> $@
	cat raspberry/main.sh >> $@
	chmod +x $@

clean:
	rm -rf raspberry.sh .cache

check:
	shellcheck --shell=bash $(shell git ls-files | grep '\.sh$$')

.PHONY: clean check
