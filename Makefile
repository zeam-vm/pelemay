MIX := mix
CC := clang

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj
CODE = $(MIX_APP_PATH)/native

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

calling_from_make:
	mix compile

.PHONY: all libnif clean

all: $(BUILD) $(PREFIX) $(PREFIX)/libnif.so

# native/lib.s: native/lib.c
# 		$(CC) $(CFLAGS) -c -S -o $@ $^

$(PREFIX)/libnif.so: $(CODE)/lib.c
		$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ $^

$(PREFIX):
	mkdir -p $@

$(BUILD):
	mkdir -p $@

clean:
		$(RM) -rf $(PREFIX)/*
