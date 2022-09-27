# Paint: paint a graph with Makefile

Here I introduce a way of writing Makefile.

## Features:

### single logical Makefile using only absolute path in rules

When a Makefile `include` other Makefiles, essentially it's still a single logical Makefile, containing a single dependency graph.

If we call `make` in a recipt in a Makefile, there are at least two dependency graphs, or at least two logical Makefile.

The way in which we write Makefile:
* Never call `make` in recipts, only include other Makefiles.
* Only use absolute path in rules.

Then what you have is a single, simple, complete and straightforward dependency graph.

### execute make anywhere

Most likely, the source code of your project has a tree structure and contains many directories.

The way in which we write Makefile:
* allow you to execute `make` in any directory

## General Idea

### 1st, find out the absolute path of your project root directory.

Here is the code to figure out the absolute path of your project root directory:
```
ifndef PROJECT_ROOT
    sp :=
    sp +=
    anchor := prod/makefiles/base.mk
    _walk = $(if $1,$(wildcard /$(subst $(sp),/,$1)/$2) $(call _walk,$(wordlist 2,$(words $1),x $1),$2))
    _find = $(firstword $(call _walk,$(strip $(subst /, ,$1)),$2))
    PROJECT_ROOT := $(patsubst %/$(anchor),%,$(call _find,$(CURDIR),$(anchor)))
endif
```

`anchor` is just a file existing in your project, could be something dummy, could be something important.

`PROJECT_ROOT` is the absolute path of your project root directory.

### 2nd, find out the working directory and corresponding output directory

If `cd PROJECT_ROOT/src/mod1 && make`, then working directory is `PROJECT_ROOT/src/mod1`.

If `make -C PROJECT_ROOT/src/tool1`, then working directories is `PROJECT_ROOT/src/tool1`.

```
LAST_MAKEFILE := $(lastword $(MAKEFILE_LIST))
WORKING_DIR := $(patsubst %/,%,$(dir $(abspath $(LAST_MAKEFILE))))

RELATIVE_WORKING_DIR := $(patsubst $(PROJECT_ROOT)/%,%,$(WORKING_DIR))
OUTPUT_DIR := $(PROJECT_ROOT)/output/$(RELATIVE_WORKING_DIR)
```

### 3rd, write rules with absolute path

Example for C project.
```
$(OUTPUT_DIR)/%.d: $(WORKING_DIR)/%.c
	set -e; rm -f $@; $(CC) -I$(PROJECT_ROOT)/headers -M $(CFLAGS) $< > $@.$$$$; sed 's,\($*\)\.o[ :]*,$(OUTPUT_DIR)/\1.o $@ : ,g' < $@.$$$$ > $@; rm -f $@.$$$$

$(OUTPUT_DIR)/%.o : $(WORKING_DIR)/%.c $(OUTPUT_DIR)/%.d
	$(COMPILE.c) -Wall -g -std=c99 -pedantic -I$(PROJECT_ROOT)/headers -o $@ $<
```

## Implementation for C project on Linux

Document: [Paint for C on Linux](https://github.com/ruioaix/paint/tree/master/doc)
