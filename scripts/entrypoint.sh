#!/usr/bin/env bash
set -xe

echo "Starting server..."

: ${MAP_NAME:="TheIsland"}
: ${SESSION_NAME:=""}
: ${SERVER_PASSWORD:=""}
: ${SERVER_ADMIN_PASSWORD:=""}
: ${NOBATTLEYE:="-NoBattlEye"}

[ -z "${SESSION_NAME}" ] && echo "Must set \$SESSION_NAME!" && exit 1

# This comes from the Dockerfile/docker ENV.
cd ${SERVER_INSTALL_DIR}/ShooterGame/Binaries/Linux/

./ShooterGameServer \
    ${MAP_NAME}?listen?SessionName=${SESSION_NAME}?ServerPassword=${SERVER_PASSWORD}?ServerAdminPassword=${SERVER_ADMIN_PASSWORD} \
    -server ${NOBATTLEYE} \
    -log
