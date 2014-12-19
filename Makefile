# OASIS_START
# DO NOT EDIT (digest: a3c674b4239234cbbe53afe090018954)

SETUP = ocaml setup.ml

build: setup.data
	$(SETUP) -build $(BUILDFLAGS)

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)

all:
	$(SETUP) -all $(ALLFLAGS)

install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

reinstall: setup.data
	$(SETUP) -reinstall $(REINSTALLFLAGS)

clean:
	$(SETUP) -clean $(CLEANFLAGS)

distclean:
	$(SETUP) -distclean $(DISTCLEANFLAGS)

setup.data:
	$(SETUP) -configure $(CONFIGUREFLAGS)

configure:
	$(SETUP) -configure $(CONFIGUREFLAGS)

.PHONY: build doc test all install uninstall reinstall clean distclean configure

# OASIS_STOP

EXAMPLES = examples/mem_size.native examples/collatz.native \
	examples/bencode_write.native # examples/crawl.native
OPTIONS = -use-ocamlfind -I _build

examples: all
	ocamlbuild $(OPTIONS) -package unix -I . $(EXAMPLES)

push_doc: doc
	scp -r containers.docdir/* cedeela.fr:~/simon/root/software/containers/
	scp -r containers_string.docdir/* cedeela.fr:~/simon/root/software/containers/string/
	scp -r containers_advanced.docdir/* cedeela.fr:~/simon/root/software/containers/advanced
	scp -r containers_misc.docdir/* cedeela.fr:~/simon/root/software/containers/misc/
	scp -r containers_lwt.docdir/* cedeela.fr:~/simon/root/software/containers/lwt/

DONTTEST=myocamlbuild.ml setup.ml $(wildcard src/**/*.cppo.*)
QTESTABLE=$(filter-out $(DONTTEST), \
	$(wildcard src/core/*.ml) \
	$(wildcard src/core/*.mli) \
	$(wildcard src/data/*.ml) \
	$(wildcard src/data/*.mli) \
	$(wildcard src/string/*.ml) \
	$(wildcard src/string/*.mli) \
	$(wildcard src/io/*.ml) \
	$(wildcard src/io/*.mli) \
	$(wildcard src/sexp/*.ml) \
	$(wildcard src/sexp/*.mli) \
	$(wildcard src/advanced/*.ml) \
	$(wildcard src/advanced/*.mli) \
	$(wildcard src/iter/*.ml) \
	$(wildcard src/iter/*.mli) \
	$(wildcard src/bigarray/*.ml) \
	$(wildcard src/bigarray/*.mli) \
	)

qtest-clean:
	@rm -rf qtest/

QTEST_PREAMBLE='open CCFun;; '

#qtest-build: qtest-clean build
#	@mkdir -p qtest
#	@qtest extract --preamble $(QTEST_PREAMBLE) \
#		-o qtest/qtest_all.ml \
#		$(QTESTABLE) 2> /dev/null
#	@ocamlbuild $(OPTIONS) -pkg oUnit,QTest2Lib,ocamlbuildlib \
#		-I core -I misc -I string \
#		qtest/qtest_all.native

qtest-gen: qtest-clean
	@mkdir -p qtest
	@if which qtest > /dev/null ; then \
		qtest extract --preamble $(QTEST_PREAMBLE) \
			-o qtest/run_qtest.ml \
			$(QTESTABLE) 2> /dev/null ; \
	else touch qtest/run_qtest.ml ; \
	fi

push-stable:
	git checkout stable
	git merge master -m 'merge from master'
	oasis setup
	git commit -a -m 'oasis files'
	git push origin
	git checkout master

clean-generated:
	rm **/*.{mldylib,mlpack,mllib} myocamlbuild.ml -f

run-test: build
	./run_qtest.native
	./run_tests.native

test-all: run-test

tags:
	otags *.ml *.mli

VERSION=$(shell awk '/^Version:/ {print $$2}' _oasis)

update_next_tag:
	@echo "update version to $(VERSION)..."
	zsh -c 'sed -i "s/NEXT_VERSION/$(VERSION)/g" **/*.ml **/*.mli'
	zsh -c 'sed -i "s/NEXT_RELEASE/$(VERSION)/g" **/*.ml **/*.mli'

udpate_sequence:
	git subtree pull --prefix sequence sequence stable --squash

.PHONY: examples push_doc tags qtest clean update_sequence update_next_tag push-stable clean-generated
