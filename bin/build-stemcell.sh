#!/bin/bash

set -e

bin=$(dirname $0)

cd $bin/..

./bin/build-linux-amd64

# todo -x?
time fly -t production execute -p -i agent-src=. -c ./bin/build-stemcell.yml
