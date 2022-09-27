# Paint for C project on Linux

## Table of Contents

- [What Paint for C project on Linux looks like](#What-Paint-C-Linux-looks-like)
- [Two core concept behind: module and tool](#Two-core-concept-behind-module-and-tool)
    - [module and library](#module-and-library)
    - [tool and executable](#tool-and-executable)
- [Single Complete Dependence Graph](#Single-Complete-Dependence-Graph)
- [Single root header directory](#Single-root-header-directory)
- [Do nothing to OS](#Do-nothing-to-OS)
- [Five Makefile files](#Five-Makefile-files)
- [How to create a new library](#How-to-create-a-new-library)
- [How to create a new tool](#How-to-create-a-new-tool)
- [Examples](#Examples)
    - [Examples 1](#Example-1)

## What Paint-C-Linux looks like

The source code is inside `PROJECT_ROOT/src` folder.

The structure is
```
├── Makefile
├── h
│   ├── header1.h
│   ├── header2.h
│   ├── header3.h
│   └── header4.h
├── mod1
│   ├── Makefile
│   ├── mod11
│   │   ├── Makefile
│   │   ├── mod111
│   │   │   ├── Makefile
│   │   │   └── mod111_a.c
│   │   ├── mod112
│   │   │   ├── Makefile
│   │   │   └── mod112_a.c
│   │   └── mod11_a.c
│   ├── mod1_a.c
│   └── mod1_b.c
├── mod2
│   ├── Makefile
│   └── mod2_a.c
├── tool1
│   ├── Makefile
│   ├── tool1.c
│   └── tool1_mod1
│       ├── Makefile
│       └── tmod1.c
└── tool2
    ├── Makefile
    └── tool2_a.c
```

Execute `make` in `PROJECT_ROOT`.

The output is a new `PROJECT_ROOT/_prod` folder and all its content.
```
_prod
├── bin
│   ├── tool1
│   └── tool2
├── lib
│   ├── libmod1.a
│   ├── libmod11.a
│   ├── libmod111.a
│   ├── libmod112.a
│   ├── libmod2.a
│   └── libtool1_mod1.a
└── objs
    ├── mod1
    │   ├── mod11
    │   │   ├── mod111
    │   │   │   ├── mod111_a.d
    │   │   │   └── mod111_a.o
    │   │   ├── mod112
    │   │   │   ├── mod112_a.d
    │   │   │   └── mod112_a.o
    │   │   ├── mod11_a.d
    │   │   └── mod11_a.o
    │   ├── mod1_a.d
    │   ├── mod1_a.o
    │   ├── mod1_b.d
    │   └── mod1_b.o
    ├── mod2
    │   ├── mod2_a.d
    │   └── mod2_a.o
    ├── tool1
    │   ├── tool1.d
    │   ├── tool1.o
    │   └── tool1_mod1
    │       ├── tmod1.d
    │       └── tmod1.o
    └── tool2
        ├── tool2_a.d
        └── tool2_a.o
```

The `_prod/bin` folder contains two executables, corresponding to the `src/tool1` and `src/tool2`.

The `_prod/lib` folder contains 6 libraries, corresponding to:
* `src/mod1`, `src/mod1/mod11`, `src/mod1/mod11/mod111` and `src/mod1/mod11/mod112`.
* `src/mod2`
* `src/tool1/tool1_mod1`

* type `make` in any directory containing a Makefile file to generate libraries and/or executables.
    * e.g. the output of executing `make` in `src/mod1/mod11/mod111` is:
```
_prod
├── bin
├── lib
│   └── libmod111.a
└── objs
    └── mod1
        └── mod11
            └── mod111
                ├── mod111_a.d
                └── mod111_a.o
```
* type `make clean` in any directory containing a Makefile file to clean up what `make` generated.
* create a directory, copy src/mod1/Makefile into the directory, write one or more src.c, just `make` to generate a library.
* create a directory, copy src/tool1/Makefile into the directory, write one main.c and/or more src.c, just `make` to generate a executable.

## Two core concept behind: module and tool

The output of a typical C project on Linux is libraries(static or dynamic) and executables.

Correspondingly, two concepts are defined in **Paint-C-Linux**: modules and tools.

A module is a directory, which satisfies the following requirements:
* the directory contains a Makefile.
* the directory contains at leset one source file.
    * There is no `main` function defined in any source file.
* the directory could contain other module directory.

A tool is a directory, which satisfies the following requirements:
* the directory contains a Makefile.
* the directory contains at leset one source file.
    * There is a `main` function defined in one and only one source file.
* the directory could contain other module directory.

Modules can not contain tools.

Compiling a module generates a main library and some sub-libraries, each sub-directory corresponds to a sub-library; compiling a tool generates an executable and some sub-libraries, each sub-directory corresponds to a sub-library.

### module and library

The name of the module directory is used as a part of the name of the library.

For example, if a module is located at `/PATH/TO/A/MODULE/net`, the name of the generated library will be `libnet.a`, e.g. `/PATH/TO/OUTPUT/LIBRARY/DIR/libnet.a`.

If the module contains some sub-modules, each sub-module will be used to generate corresponding library.

For example, if there are two sub-modules in `/PATH/TO/A/MODULE/net`: `/PATH/TO/A/MODULE/net/ipv4` and `/PATH/TO/A/MODULE/net/ipv6`, then two libraries, `/PATH/TO/OUTPUT/LIBRARY/DIR/libipv4.a` and `/PATH/TO/OUTPUT/LIBRARY/DIR/libipv6.a`, will be generated.

As you may already noticed, all the libraries, including root-library and sub-libraries, are all located in the same output directory, e.g. `/PATH/TO/OUTPUT/LIBRARY/DIR/`, as a result, the name of the module need to be unique across the whole project.

The parent module contains all the contents in all his children modules.
In the above example, `libnet.a` contains all the object files (`.o` file) in both `libipv4.a` and `libipv6.a`.

In this repo, the default library output path is `/PROJECT_ROOT/_prod/lib/`.

### tool and executable

Each tool directory at least contains a source file. tool directory can contains multiple source files, there should be exact one source file containing the main function.

If the tool directory contains some sub-modules, each sub-module will generate a corresponding library which is located in the same project-scope library output directory, e.g. the above `/PATH/TO/OUTPUT/LIBRARY/DIR/`.

A tool usually depends on some modules not located inside its directory, then we need to explicitly specify the dependences in the Makefile of the tool, e.g. `/PATH/TO/A/TOOL/checknet/Makefile`.

The output of compiling a tool directory is an executable (and some libraries if sub-module existing in the tool directory).

In this repo, the default tool output path is `/PROJECT_ROOT/_prod/bin/`.

## Single Complete Dependence Graph

There are two styles of using Makefile:
1. calling `make -C /ANOTHER/PATH` in recipts of rules.
2. not calling `make -C /ANOTHER/PATH` in recipts of rules.

**Paint-C-Linux** is style 2.

There is a Makefile in each tool or module directory, which is the root Makefile.
It's ok to execute `make` in any tool or module directory, and `make` will do the right thing.

Each time executing `make` command in a tool or module directory, `make` will read the root Makefile, as well as all the Makefiles included in the root Makefile; after reading all the Makefiles, `make` will construct a dependence graph and start to executing recipes according to the graph.

## Single root header directory

To make **Paint-C-Linux** simple, all the header files are placed in one root header directory.

How to structure the root header directory is up to you.

In the project, by default, the root header directory is `/PROJECT_ROOT/src/h/`, and there is no sub directory in the root header directory; all the header files are directly placed in the root header directory; the `-I/PROJECT_ROOT/src/h` is added to the command of compiling _.c_ to _.o_; as a result, all _.c_ files include header files in the way of `#include "header.h"`, instead of `#include "path/to/header.h"`. And the limit is that the name of each header file has to be unique.

## Do nothing to OS

No matter how the repo is retrieved, git-cloning the repo or downloading the zip file, No matter how many times the `make` command is executed inside the repo, when you remove the repo, there is nothing left on your OS.

In the project, all the output generated by executing any `make` command is placed in `/PROJECT_ROOT/_prod/`, removing this directory cleans up all the output.

## Five Makefile files

1. Module Makefile, e.g. [mod1/Makefile](https://github.com/ruioaix/paint/blob/master/src/mod1/Makefile), [mod2/Makefile](https://github.com/ruioaix/paint/blob/master/src/mod2/Makefile), [mod11/Makefile](https://github.com/ruioaix/paint/blob/master/src/mod1/mod11/Makefile); they are all complete same.
2. Tool Makefile, e.g. [tool1/Makefile](https://github.com/ruioaix/paint/blob/master/src/tool1/Makefile) and [tool2/Makefile](https://github.com/ruioaix/paint/blob/master/src/tool2/Makefile); they are almost same.
3. [prod/makefiles/module.mk](https://github.com/ruioaix/paint/blob/master/prod/makefiles/module.mk), included by Module Makefile.
4. [prod/makefiles/tool.mk](https://github.com/ruioaix/paint/blob/master/prod/makefiles/tool.mk), included by Tool Makefile.
5. [prod/makefiles/base.mk](https://github.com/ruioaix/paint/blob/master/prod/makefiles/base.mk), included by module.mk and tool.mk.

## How to create a new library

Create a directory in `/PROJECT_ROOT/src/`, copy Module Makefile into the directory, write codes.

## How to create a new tool

Create a directory in `/PROJECT_ROOT/src/`, copy Tool Makefile into the directory, write codes.

## Examples

### Example 1
Directory `A` is a module containing `a1.c` and sub-directories `AB` & `AC`; `AB` contains `ab1.c` and `ab2.c`, `AC` contains `ac1.c` and `ac2.c`.

`cd /PATH/TO/A && make` or `make -C /PATH/TO/A` will generate
1. `/PATH/TO/lib/libA.a`, which archives `a1.o`, `ab1.o`, `ab2.o`, `ac1.o` and `ac2.o`.
2. `/PATH/TO/lib/libAC.a`, which archives `ac1.o` and `ac2.o`.
3. `/PATH/TO/lib/libAB.a`, which archives `ab1.o` and `ab2.o`.
4. `/PATH/TO/objs/A/a1.o`
5. `/PATH/TO/objs/A/AB/ab1.o`
5. `/PATH/TO/objs/A/AB/ab2.o`
5. `/PATH/TO/objs/A/AC/ac1.o`
5. `/PATH/TO/objs/A/AC/ac2.o`

