MIX := mix
CC := clang

CFLAGS := -Ofast -g -ansi -pedantic -femit-all-decls

ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)

CFLAGS += -I/usr/local/include -I/usr/include -L/usr/local/lib -L/usr/lib
CFLAGS += -std=c11 -Wno-unused-function

ifneq ($(OS),Windows_NT)
		CFLAGS += -fPIC

		ifeq ($(shell uname),Darwin)
				LDFLAGS += -dynamiclib -undefined dynamic_lookup
		endif
endif

.PHONY: all libnifvec clean

all: libnif # native/lib.s


libnif:
		$(MIX) compile

# native/lib.s: native/lib.c
# 		$(CC) $(CFLAGS) -c -S -o $@ $^

priv/libnif.so: native/lib.c
		$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ $^

clean:
		$(MIX) clean
		$(RM) -rf priv/*
