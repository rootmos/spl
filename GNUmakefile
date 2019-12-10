export CACHE ?= $(shell pwd)/.cache

run: raspberry.sh
	bash ./$<

raspberry.sh: lib/preamble.sh lib/fetch.sh raspberry/main.sh
	cat $^ > $@
	chmod +x $@

clean:
	rm -rf raspberry.sh .cache

check:
	shellcheck --shell=bash $(shell git ls-files | grep '\.sh$$')

.PHONY: clean check
