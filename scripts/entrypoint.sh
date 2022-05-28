#!/usr/bin/env bash

set -e

function array_join { local IFS="$1"; shift; echo "$*"; }

echo "=== starting server..."

# Default variables.
: ${MAP_NAME:="TheIsland"}
: ${SESSION_NAME:=""}
: ${SERVER_PASSWORD:=""}
: ${SERVER_ADMIN_PASSWORD:="admin"}
: ${NOBATTLEYE:="-NoBattlEye"}

# Safety check for empty $SESSION_NAME.
[ -z "${SESSION_NAME}" ] && echo "Must set \$SESSION_NAME!" && exit 1

# Copies/overwrites the INI configurations from the source baked into the image.
# NOTE: Since the dedicated server stores configurations in the persistent
# volume location, this allows the server configuration to be somewhat
# "immutable" and prevents tampering of configuration via the persistent volume
# to ensure what was built into the image is used.

# The $SERVER_DATA_DIR and $SERVER_SAVED_DATA_DIR variables come from the Dockerfile/docker ENV.

if [ -d ${SERVER_DATA_DIR}/config ]; then
    echo "=== copying/overwriting INI configurations with those baked into the image..."
    mkdir -p ${SERVER_SAVED_DATA_DIR}/Config/LinuxServer/
    cp -fpv \
        ${SERVER_DATA_DIR}/config/Game.ini \
        ${SERVER_SAVED_DATA_DIR}/Config/LinuxServer/
    echo "=== done!"
fi

# Assembles the ? and - flags passed into the game server as command line arguments.

declare -a question_flags
declare -a dash_flags

# TODO: parse/load question flags from input configuration files?

question_flags=(
    "${MAP_NAME}"
    "listen"
    "SessionName=${SESSION_NAME}"
    "ServerPassword=${SERVER_PASSWORD}"
    "ServerAdminPassword=${SERVER_ADMIN_PASSWORD}"
    MaxPlayers=20
    AllowCaveBuildingPVE=true
    AllowHitMarkers=true
    AllowThirdPersonPlayer=true
    alwaysNotifyPlayerJoined=true
    alwaysNotifyPlayerLeft=true
    AutoSavePeriodMinutes=10.000000
    DayCycleSpeedScale=0.8
    DayTimeSpeedScale=0.8
    NightTimeSpeedScale=1.5
    PlayerDamageMultiplier=1.5
    StructureDamageMultiplier=1.5
    PlayerResistanceMultiplier=0.5
    PlayerCharacterHealthRecoveryMultiplier=1.5
    ResourcesRespawnPeriodMultiplier=1.2
    DinoCountMultiplier=0.7
    DifficultyOffset=0.1
    DisableDinoDecayPvE=True
    DisableStructureDecayPvE=True
    ItemStackSizeMultiplier=2.0
    MaxTamedDinos=1000.0
    PreventDiseases=True
    PreventTribeAlliances=True
    RCONPort=27020
    RCONServerGameLogBuffer=600.000000
    ServerCrosshair=True
    serverPVE=True
    ShowMapPlayerLocation=True
    StructurePickupTimeAfterPlacement=300.0
)
dash_flags=(
    "-game" "-server" "${NOBATTLEYE}"
    "-log" "-servergamelog" "-servergamelogincludetribelogs"
)

joined_question_flags=$(array_join '?' ${question_flags[*]})
joined_dash_flags=$(array_join ' ' ${dash_flags[*]})

echo "Question flags: ${joined_question_flags}"
echo "Dash flags: ${joined_dash_flags}"

# The variable $SERVER_INSTALL_DIR comes from the Dockerfile/docker ENV
cd ${SERVER_INSTALL_DIR}/ShooterGame/Binaries/Linux/

# Bring the server up
./ShooterGameServer ${joined_question_flags} ${joined_dash_flags}
