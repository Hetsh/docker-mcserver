FROM library/alpine:20200428
RUN apk add --no-cache \
    openjdk11-jre-headless=11.0.7_p10-r1

# App user
ARG APP_USER="mc"
ARG APP_UID=1357
RUN adduser --disabled-password --uid "$APP_UID" --no-create-home --gecos "$APP_USER" --shell /sbin/nologin "$APP_USER"

# Server binary
ARG BIN_URL="https://launcher.mojang.com/v1/objects/a0d03225615ba897619220e256a266cb33a44b6b/server.jar"
ARG APP_BIN="/opt/server.jar"
ADD "$BIN_URL" "$APP_BIN"
RUN chmod 644 "$APP_BIN"

# EULA and Volumes
ARG DATA_DIR="/mcserver-data"
ARG EULA="eula.txt"
RUN echo "eula=true" > "$EULA" && \
    chown "$APP_USER":"$APP_USER" "$EULA"
VOLUME ["$DATA_DIR"]

#      GAME      RCON      QUERY
EXPOSE 25565/tcp 25575/tcp 25565/udp

USER "$APP_USER"
WORKDIR "$DATA_DIR"
ENV JAVA_OPT="-Xms8M -Xmx1G"
ENTRYPOINT exec java $JAVA_OPT -jar /opt/server.jar nogui
