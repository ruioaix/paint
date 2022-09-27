ifndef PROJECT_ROOT
$(error PROJECT_ROOT not defined)
endif

_SECOND_LAST_MAKEFILE := $(word $(words $(MAKEFILE_LIST)),DUMMY $(MAKEFILE_LIST))
MODULE_PATH := $(patsubst %/,%,$(dir $(abspath $(_SECOND_LAST_MAKEFILE))))
MODULE_NAME := $(notdir $(MODULE_PATH))
LIB_NAME := lib$(MODULE_NAME).a

ifndef $(LIB_NAME)
$(LIB_NAME) := included

SRC_PATHS := $(wildcard $(MODULE_PATH)/*.c)

SUB_MODULE_MAKEFILES := $(wildcard $(MODULE_PATH)/*/Makefile)
SUB_MODULE_NAMES := $(notdir $(patsubst %/Makefile,%,$(SUB_MODULE_MAKEFILES)))
SUB_LIB_NAMES := $(addsuffix .a,$(addprefix lib,$(SUB_MODULE_NAMES)))

HAS_SOMETHING_TO_DO := $(strip $(SRC_PATHS) $(SUB_MODULE_NAMES))

ifndef HAS_SOMETHING_TO_DO
ifneq "$(MAKECMDGOALS)" "clean"
$(error nothing to do in $(MODULE_PATH))
endif
endif

include $(PROJECT_ROOT)/prod/makefiles/base.mk

LIB_PATH := $(addprefix $(LIB_ROOT)/,$(LIB_NAME))
SUB_LIB_PATHS := $(addprefix $(LIB_ROOT)/,$(SUB_LIB_NAMES))

_MODULE_PATH_INTERNAL := $(patsubst $(SOURCE_ROOT)/%,%,$(MODULE_PATH))
OBJS_DIR := $(OBJS_ROOT)/$(_MODULE_PATH_INTERNAL)
_SIDE_EFFECT := $(shell mkdir -p $(OBJS_DIR))
OBJ_PATHS := $(addsuffix .o,$(addprefix $(OBJS_DIR)/,$(basename $(notdir $(SRC_PATHS)))))
HEADER_DEP_PATHS := $(patsubst %.o,%.d,$(OBJ_PATHS))
.SECONDARY: $(HEADER_DEP_PATHS)

CLEAN_MODULE := clean_$(MODULE_NAME)
.PHONY: all clean $(CLEAN_MODULE)

all: $(LIB_PATH)

clean : $(CLEAN_MODULE)

CLEAN_SUB_MODULES := $(addprefix clean_,$(SUB_MODULE_NAMES))
$(CLEAN_MODULE) : _OBJ_PATHS := $(OBJ_PATHS)
$(CLEAN_MODULE) : _LIB_PATH := $(LIB_PATH)
$(CLEAN_MODULE) : _HEADER_DEP_PATHS := $(HEADER_DEP_PATHS)
$(CLEAN_MODULE) : $(CLEAN_SUB_MODULES)
	rm -f $(_LIB_PATH) $(_OBJ_PATHS) $(_HEADER_DEP_PATHS)

ifdef SUB_LIB_PATHS
$(LIB_PATH) : _OBJS_DIR := $(OBJS_DIR)
$(LIB_PATH) : _OBJ_PATHS := $(OBJ_PATHS)
$(LIB_PATH) : _SUB_LIB_PATHS := $(SUB_LIB_PATHS)
$(LIB_PATH) : $(OBJ_PATHS) $(SUB_LIB_PATHS)
	if [ ! -z "$(_SUB_LIB_PATHS)" ]; then \
		for sub_lib in $(_SUB_LIB_PATHS); \
			do \
				mkdir $(_OBJS_DIR)/archive;\
				cd $(_OBJS_DIR)/archive; \
				$(AR) x $${sub_lib}; \
		done; \
	fi
	$(AR) rsv $@ $(_OBJ_PATHS) $(_OBJS_DIR)/archive/*.o
	rm -rf $(_OBJS_DIR)/archive
else
$(LIB_PATH) : $(OBJ_PATHS)
	$(AR) rsv $@ $^
endif

$(OBJS_DIR)/%.o : $(MODULE_PATH)/%.c $(OBJS_DIR)/%.d
	$(COMPILE.c) -Wall -g -std=c99 -pedantic -I$(PROJECT_ROOT)/src/h -o $@ $<

$(OBJS_DIR)/%.d: $(MODULE_PATH)/%.c
	set -e; rm -f $@; $(CC) -I$(PROJECT_ROOT)/src/h -M $(CFLAGS) $< > $@.$$$$; sed 's,\($*\)\.o[ :]*,$(OBJS_DIR)/\1.o $@ : ,g' < $@.$$$$ > $@; rm -f $@.$$$$

ifneq "$(MAKECMDGOALS)" "clean"
include $(HEADER_DEP_PATHS)
endif

include $(SUB_MODULE_MAKEFILES)
endif
