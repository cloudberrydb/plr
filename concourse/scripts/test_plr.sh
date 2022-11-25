#!/bin/bash -l

set -exo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${CWDIR}/../../../
GPDB_CONCOURSE_DIR=${TOP_DIR}/gpdb_src/concourse/scripts

source "${GPDB_CONCOURSE_DIR}/common.bash"
INSTALL_DIR=${INSTALL_DIR:-/usr/local/cloudberry-db-devel}
function prepare_test(){

    cat > /home/gpadmin/test.sh <<-EOF
        #!/usr/bin/env bash
        set -exo pipefail

        source ${TOP_DIR}/gpdb_src/gpAux/gpdemo/gpdemo-env.sh
        source $INSTALL_DIR/greenplum_path.sh
        gppkg -i bin_plr/plr-*.gppkg || exit 1
        source $INSTALL_DIR/greenplum_path.sh
        gpstop -arf

        pushd plr_src/src

        PGOPTIONS='-c optimizer=off' make USE_PGXS=1 installcheck
        [ -s regression.diffs ] && cat regression.diffs && exit 1

        # PGOPTIONS='-c optimizer=on' make USE_PGXS=1 installcheck
        # [ -s regression.diffs ] && cat regression.diffs && exit 1

        popd
EOF

    chown -R gpadmin:gpadmin $(pwd)
    chown gpadmin:gpadmin /home/gpadmin/test.sh
    chmod a+x /home/gpadmin/test.sh

}

function test() {
    su gpadmin -c "bash /home/gpadmin/test.sh $(pwd)"
    mv bin_plr/plr-*.gppkg plr_gppkg/
}

function setup_gpadmin_user() {
    ${GPDB_CONCOURSE_DIR}/setup_gpadmin_user.bash
}

function install_pkg()
{
case $OSVER in
centos* | rhel*)
    yum install -y pkgconfig
    ;;
ubuntu*)
    apt update
    DEBIAN_FRONTEND=noninteractive apt install -y r-base pkg-config
    ;;
*)
    echo "unknown OSVER = $OSVER"
    exit 1
    ;;
esac
}

function make_cluster() {
    #source $INSTALL_DIR/greenplum_path.sh
    export BLDWRAP_POSTGRES_CONF_ADDONS=${BLDWRAP_POSTGRES_CONF_ADDONS}
    export STATEMENT_MEM=250MB
    pushd gpdb_src/gpAux/gpdemo
    su gpadmin -c "source $INSTALL_DIR/greenplum_path.sh; LANG=en_US.utf8 make create-demo-cluster"
    popd
}

function _main() {
    time install_pkg
    time install_gpdb
    time setup_gpadmin_user
    time make_cluster
    time prepare_test
    time test
}

_main "$@"
