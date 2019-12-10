run: raspberry.sh
	bash ./$< -c $(shell pwd)/.cache

raspberry.sh: lib/preamble.sh lib/fetch.sh raspberry/main.sh
	cat $^ > $@
	chmod +x $@

clean:
	rm -rf raspberry.sh
