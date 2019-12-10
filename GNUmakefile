run: raspberry.sh
	bash -x ./$<

raspberry.sh: lib/preamble.sh lib/fetch.sh raspberry/main.sh
	cat $^ > $@
	chmod +x $@

clean:
	rm -rf raspberry.sh
