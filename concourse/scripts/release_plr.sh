#!/bin/bash -l

set -exo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${CWDIR}/../../../
pushd ${TOP_DIR}/plr_src
PLR_VERSION=$(git describe --tags | awk -F. '{printf("%d.%d.%d", $1, $2, $3)}')
popd
function release_gpdb() {
	cp bin_plr/plr-*.gppkg plr_gppkg/plr-$PLR_VERSION-$BLDARCH.gppkg
}

function _main() {
    time release_gpdb
}

_main "$@"
