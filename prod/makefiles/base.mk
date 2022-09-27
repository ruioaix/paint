ifndef PROJECT_ROOT
	$(error PROJECT_ROOT not defined)
endif

BIN_ROOT := $(PROJECT_ROOT)/_prod/bin
_SIDE_EFFECT := $(shell mkdir -p $(BIN_ROOT))

LIB_ROOT := $(PROJECT_ROOT)/_prod/lib
_SIDE_EFFECT := $(shell mkdir -p $(LIB_ROOT))

OBJS_ROOT := $(PROJECT_ROOT)/_prod/objs
_SIDE_EFFECT := $(shell mkdir -p $(OBJS_ROOT))

SOURCE_ROOT := $(PROJECT_ROOT)/src

CC := gcc

