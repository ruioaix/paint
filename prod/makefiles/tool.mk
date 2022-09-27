ifndef PROJECT_ROOT
$(error PROJECT_ROOT not defined)
endif

_SECOND_LAST_MAKEFILE := $(word $(words $(MAKEFILE_LIST)),DUMMY $(MAKEFILE_LIST))
TOOL_PATH := $(patsubst %/,%,$(dir $(abspath $(_SECOND_LAST_MAKEFILE))))
TOOL_NAME := $(notdir $(TOOL_PATH))
TOOL_MAIN_SRC_NAME := $(TOOL_NAME).c

SRC_PATHS := $(wildcard $(TOOL_PATH)/*.c)

SUB_MODULE_MAKEFILES := $(wildcard $(TOOL_PATH)/*/Makefile)
SUB_MODULE_NAMES := $(notdir $(patsubst %/Makefile,%,$(SUB_MODULE_MAKEFILES)))
SUB_LIB_NAMES := $(addsuffix .a,$(addprefix lib,$(SUB_MODULE_NAMES)))
LIB_DEP_NAMES := $(addsuffix .a,$(addprefix lib,$(LIB_DEPS)))

HAS_SOMETHING_TO_DO := $(strip $(SRC_PATHS) $(SUB_MODULE_NAMES))

ifndef HAS_SOMETHING_TO_DO
ifneq "$(MAKECMDGOALS)" "clean"
$(error nothing to do in $(TOOL_PATH))
endif
endif

include $(PROJECT_ROOT)/prod/makefiles/base.mk

BIN_PATH := $(addprefix $(BIN_ROOT)/,$(TOOL_NAME))
SUB_LIB_PATHS := $(addprefix $(LIB_ROOT)/,$(SUB_LIB_NAMES))

_find_lib_dep = $(shell find $(SOURCE_ROOT) -type f -wholename '*/$1/Makefile')
LIB_DEP_MAKEFILES := $(call _find_lib_dep,$(LIB_DEPS))

LIB_DEP_PATHS := $(addprefix $(LIB_ROOT)/,$(LIB_DEP_NAMES))

_TOOL_PATH_INTERNAL := $(patsubst $(SOURCE_ROOT)/%,%,$(TOOL_PATH))
OBJS_DIR := $(OBJS_ROOT)/$(_TOOL_PATH_INTERNAL)
_SIDE_EFFECT := $(shell mkdir -p $(OBJS_DIR))
OBJ_PATHS := $(addsuffix .o,$(addprefix $(OBJS_DIR)/,$(basename $(notdir $(SRC_PATHS)))))
HEADER_DEP_PATHS := $(patsubst %.o,%.d,$(OBJ_PATHS))
.SECONDARY: $(HEADER_DEP_PATHS)

CLEAN_TOOL := clean_$(TOOL_NAME)
.PHONY: all clean $(CLEAN_TOOL)

all: $(BIN_PATH)

clean : $(CLEAN_TOOL)

CLEAN_SUB_MODULES := $(addprefix clean_,$(SUB_MODULE_NAMES))
$(CLEAN_TOOL) : _BIN_PATH := $(BIN_PATH)
$(CLEAN_TOOL) : _OBJ_PATHS := $(OBJ_PATHS)
$(CLEAN_TOOL) : _HEADER_DEP_PATHS := $(HEADER_DEP_PATHS)
$(CLEAN_TOOL) : $(CLEAN_SUB_MODULES)
	rm -f $(_BIN_PATH) $(_OBJ_PATHS) $(_HEADER_DEP_PATHS)

$(BIN_PATH) : $(OBJ_PATHS) $(SUB_LIB_PATHS) $(LIB_DEP_PATHS)
	$(LINK.c) -o $@ $^

$(OBJS_DIR)/%.o : $(TOOL_PATH)/%.c $(OBJS_DIR)/%.d
	$(COMPILE.c) -Wall -g -std=c99 -pedantic -I$(PROJECT_ROOT)/src/h -o $@ $<

$(OBJS_DIR)/%.d: _OBJS_DIR := $(OBJS_DIR)
$(OBJS_DIR)/%.d: $(TOOL_PATH)/%.c
	set -e; rm -f $@; $(CC) -I$(PROJECT_ROOT)/src/h -M $(CFLAGS) $< > $@.$$$$; sed 's,\($*\)\.o[ :]*,$(_OBJS_DIR)/\1.o $@ : ,g' < $@.$$$$ > $@; rm -f $@.$$$$

ifneq "$(MAKECMDGOALS)" "clean"
include $(HEADER_DEP_PATHS)
endif

include $(SUB_MODULE_MAKEFILES)
include $(LIB_DEP_MAKEFILES)
