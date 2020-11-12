#!/usr/bin/env bash
set -xe

function array_join { local IFS="$1"; shift; echo "$*"; }

echo "Starting server..."

# Default variables.
: ${MAP_NAME:="TheIsland"}
: ${SESSION_NAME:=""}
: ${SERVER_PASSWORD:=""}
: ${SERVER_ADMIN_PASSWORD:="admin"}
: ${NOBATTLEYE:="-NoBattlEye"}

# Safety check for empty $SESSION_NAME.
[ -z "${SESSION_NAME}" ] && echo "Must set \$SESSION_NAME!" && exit 1

# Copies/overwrites the INI configurations from the source baked into the image.
# NOTE: Since the dedicated server stores configurations in the persistent volume location,
#       this allows the server configuration to be somewhat "immutable" and prevents tampering
#       of configuration via the persistent volume to ensure what was built into the image
#       is used.

# The $SERVER_DATA_DIR and $SERVER_SAVED_DATA_DIR variables come from the Dockerfile/docker ENV.

if [ -d ${SERVER_DATA_DIR}/config ]; then
    echo "Copying/overwriting INI configurations with those baked into the image."
    cp -fpv \
        ${SERVER_DATA_DIR}/config/{Game,GameUserSettings}.ini \
        ${SERVER_SAVED_DATA_DIR}/Config/LinuxServer/
    echo "Done."
fi

# Assembles the ? and - flags passed into the game server as command line arguments.

declare -a question_flags
declare -a dash_flags

question_flags=(
    "${MAP_NAME}"
    "listen"
    "SessionName=${SESSION_NAME}"
    "ServerPassword=${SERVER_PASSWORD}"
    "ServerAdminPassword=${SERVER_ADMIN_PASSWORD}"
    "AllowCaveBuildingPVE=true"
    "PreventDiseases=true"
    "PreventTribeAlliances=true"
)
dash_flags=(
    "-game" "-server" "${NOBATTLEYE}"
    "-log" "-servergamelog" "-servergamelogincludetribelogs"
)

joined_question_flags=$(array_join '?' ${question_flags[*]})
joined_dash_flags=$(array_join ' ' ${dash_flags[*]})

# echo "Joined flags: ${joined_question_flags}"
# echo "Joined dash flags: ${joined_dash_flags}"

exit 0

# This comes from the Dockerfile/docker ENV.
cd ${SERVER_INSTALL_DIR}/ShooterGame/Binaries/Linux/

./ShooterGameServer ${joined_question_flags} ${joined_dash_flags}
