ifndef PROJECT_ROOT
	sp :=
	sp +=
	anchor := prod/makefiles/base.mk
	_walk = $(if $1,$(wildcard /$(subst $(sp),/,$1)/$2) $(call _walk,$(wordlist 2,$(words $1),x $1),$2))
	_find = $(firstword $(call _walk,$(strip $(subst /, ,$1)),$2))
	PROJECT_ROOT := $(patsubst %/$(anchor),%,$(call _find,$(CURDIR),$(anchor)))
endif

LIB_DEPS := mod11

include $(PROJECT_ROOT)/prod/makefiles/tool.mk
