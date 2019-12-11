export CACHE ?= $(shell pwd)/.cache

run: raspberry.sh
	bash ./$<

raspberry.sh: lib/preamble.sh lib/fetch.sh raspberry/kernel.config raspberry/main.sh
	cat lib/preamble.sh > $@
	cat lib/fetch.sh >> $@
	bin/bundle.sh kernel_config < raspberry/kernel.config >> $@
	cat raspberry/main.sh >> $@
	chmod +x $@

clean:
	rm -rf raspberry.sh .cache

check:
	shellcheck --shell=bash $(shell git ls-files | grep '\.sh$$')

.PHONY: clean check
