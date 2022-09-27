PROJECT_ROOT := $(CURDIR)
DIRS = src
include $(addsuffix /Makefile,$(addprefix $(PROJECT_ROOT)/,$(DIRS)))

.PHONY: clean

clean:
	rm -rf $(PROJECT_ROOT)/_prod
