
# BUILD_FLAGS=--pedantic --library-profiling --executable-profiling
BUILD_FLAGS=--pedantic

RUN=stack exec -- lg

%.html: %.lhs
    pandoc --from markdown+lhs --to html5 --smart --standalone --output=$@ $<

run: build
	$(RUN) --help

init: stack.yaml

stack.yaml:
	stack init

docs:
	stack haddock
	open `stack path --local-doc-root`/index.html

# package:
# build a release tarball or executable
#
# dev:
# start dev server or process. `vagrant up`, `yesod devel`, etc.
#
# deploy:
# prep and push

configure:
	cabal configure \
		--package-db=clear \
		--package-db=global \
		--package-db=`stack path --snapshot-pkg-db` \
		--package-db=`stack path --local-pkg-db`

install:
	stack install

tags: $(SRC)
	codex update

hlint:
	hlint *.hs src specs

clean:
	stack clean
	codex cache clean

distclean: clean
	rm stack.yaml

build:
	stack build $(BUILD_FLAGS)

test:
	stack test $(BUILD_FLAGS) # --test-arguments "-m TODO"

bench:
	stack bench $(BUILD_FLAGS)

watch:
	stack build $(BUILD_FLAGS) --fast --file-watch --exec 'make run'

watch-test:
	stack build --file-watch --pedantic --exec 'make test'

restart: distclean init build

rebuild: clean build

.PHONY: init run docs configure install hlint clean distclean build test
.PHONY: bench watch watch-test restart rebuild
