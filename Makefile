CC ?= gcc

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

msgpack: msgpack.pony
	echo "MAKE DIR $(current_dir)"
	CC=$(CC) ponyc .

run: msgpack
	./msgpack

clean:
	rm -f msgpack test/test

test: test/test
	./test/test

test/test: test/*.pony
	CC=$(CC) ponyc test -o test

.PHONY: test
