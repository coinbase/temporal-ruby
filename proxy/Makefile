GOENV=GO111MODULE=on GOSUMDB=off
GO=${GOENV} go
OUT=gen
PREFIX=github.com/coinbase/cadence-ruby/proxy/${OUT}
THRIFT_PATH=../thrift/cadence.thrift

all: bin/proxy

clean:
	rm -rvf bin/*

bin/proxy:
	${GO} build -o bin/proxy main.go

# Generate Thrift go libraries
.PHONY: thrift
thrift: thriftrw thriftrw-plugin-yarpc clean_thrift
	thriftrw --plugin yarpc --out ${OUT} --pkg-prefix ${PREFIX} ${THRIFT_PATH}

clean_thrift:
	rm -rf gen

.PHONY: thriftrw
thriftrw:
	go get go.uber.org/thriftrw

.PHONY: thriftrw-plugin-yarpc
thriftrw-plugin-yarpc:
	go get go.uber.org/yarpc/encoding/thrift/thriftrw-plugin-yarpc
