# SPDX-License-Identifier: GPL-3.0-or-later
GHC := ghc
GHC_VERSION := $(shell $(GHC) --numeric-version)
GHC_LIBDIR := $(shell $(GHC) --print-libdir)
GHC_LINK_FLAGS := -shared  -dynamic -no-hs-main
GHC_LINK_EXTRA_LIBS := -l HSrts-ghc$(GHC_VERSION)
GHC_COMPILE_FLAGS := -c -O -pie -dynamic

CXX := g++
CXXFLAGS := -std=c++17 -fpermissive -Wall -fPIC -isystem $(GHC_LIBDIR)/include

EMACS_TEST_COMMAND :=  emacs -q -batch -L . -l ert -l test.el
EMACS_TEST = ${EMACS_TEST_COMMAND} --eval "(ert-run-tests-batch-and-exit '$1))"

all: emacs-ghc-rts.so

test: emacs-ghc-rts.so ghc-rts.el test.el
	$(call EMACS_TEST,test-internal-funs)
	$(call EMACS_TEST,test-internal-funs-no-init)
	$(call EMACS_TEST,test-internal-funs-after-exit)
	$(call EMACS_TEST,test-exposed-funs)
	$(call EMACS_TEST,test-exposed-funs-no-init)
	$(call EMACS_TEST,test-exposed-funs-after-exit)
	$(call EMACS_TEST,test-rts-options-command-line)
	$(call EMACS_TEST,test-rts-options-default-args)

emacs-ghc-rts.so : emacs-ghc-rts.o
	$(GHC) $(GHC_LINK_FLAGS) $(GHC_LINK_EXTRA_LIBS) -o $@ $^

emacs-ghc-rts.o: emacs-ghc-rts.cpp emacs-ghc-rts.hpp
	$(CXX) $(CXXFLAGS) -c $<

clean:
	rm -f *.o *.so *_stub.h *.hi

.PHONY: clean emacs-ghc-rts.so test

# Local Variables: *
# compile-command: "make" *
# End: *
