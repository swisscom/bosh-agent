#!/bin/bash

set -e

bin=$(dirname $0)

cd $bin/..

./bin/build-linux-amd64

# necessary so that fly -x can be used
mv out/bosh-agent bin/bosh-agent

time fly -t production execute -x -p -i agent-src=. -o stemcell=out/ -c ./bin/build-stemcell.yml
