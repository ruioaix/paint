CURRENT_DIR = $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
DIRS = mod1 mod2 tool1 tool2
include $(addsuffix /Makefile,$(addprefix $(CURRENT_DIR)/,$(DIRS)))
