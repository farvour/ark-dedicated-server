FROM ubuntu:focal
LABEL maintainer="Thomas Farvour <tom@farvour.com>"

ARG DEBIAN_FRONTEND=noninteractive

# Top level directory where everything related to the ARK server is installed to.
# Since you can bind-mount data volumes for worlds, saves or other things, this
# doesn't really have to change, but is here for clarity and customization in case.

ENV SERVER_HOME=/app/ark
ENV SERVER_INSTALL_DIR=/app/ark/dedicated-server
ENV SERVER_DATA_DIR=/app/ark/data

# Steam still requires 32-bit cross compilation libraries.
RUN echo "=== installing necessary system packages to support steam CLI installation..." \
    && apt-get update \
    && apt-get install -y bash expect htop tmux lib32gcc1 pigz telnet wget git vim

ENV PROC_UID 7998
ENV PROC_USER game-server
ENV PROC_GROUP nogroup

RUN echo "=== create a non-privileged user to run with..." && \
    useradd -u ${PROC_UID} -d ${SERVER_HOME} -g ${PROC_GROUP} ${PROC_USER}

RUN echo "=== create server directories..." && \
    mkdir -p ${SERVER_HOME} && \
    mkdir -p ${SERVER_INSTALL_DIR} && \
    mkdir -p ${SERVER_INSTALL_DIR}/Mods && \
    mkdir -p ${SERVER_DATA_DIR} && \
    chown -R ${PROC_USER} ${SERVER_HOME}

USER ${PROC_USER}

WORKDIR ${SERVER_HOME}

RUN echo "=== downloading and installing steamcmd..." \
    && cd Steam \
    && wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz \
    && tar -zxvf steamcmd_linux.tar.gz \
    && chown -R ${PROC_USER}:${PROC_GROUP} . \
    && cd -

# This is most likely going to be the largest layer created; all the game
# files for the dedicated server
# NOTE: It is a good idea to do as much as possible _beyond_ this point to
# avoid Docker having to re-create it
RUN echo "=== downloading and installing ark server with steamcmd..." \
    && ${SERVER_HOME}/Steam/steamcmd.sh \
    +force_install_dir ${SERVER_INSTALL_DIR} \
    +login anonymous \
    +app_update 376030 validate \
    +quit

ENV SERVER_SAVED_DATA_DIR ${SERVER_INSTALL_DIR}/ShooterGame/Saved

COPY --chown=${PROC_USER}:${PROC_GROUP} config/ ${SERVER_DATA_DIR}/config/

# Query port for Steam server browser
EXPOSE 27015/udp
EXPOSE 27015/tcp

# Game client port(s)
EXPOSE 7777/udp
EXPOSE 7777/tcp
EXPOSE 7778/udp
EXPOSE 7778/tcp

# RCON remote console port
EXPOSE 27020/tcp

# Install custom entrypoint script
COPY scripts/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
