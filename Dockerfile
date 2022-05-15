FROM amd64/alpine:20220328
RUN apk update && \
    apk add --no-cache \
        openjdk17-jre-headless=17.0.3_p7-r2

# App user
ARG APP_USER="mc"
ARG APP_UID=1357
RUN adduser --disabled-password --uid "$APP_UID" --no-create-home --gecos "$APP_USER" --shell /sbin/nologin "$APP_USER"

# Server binary
ARG BIN_URL="https://launcher.mojang.com/v1/objects/c8f83c5655308435b3dcf03c06d9fe8740a77469/server.jar"
ARG APP_BIN="/opt/server.jar"
RUN wget --quiet --output-document "$APP_BIN" "$BIN_URL"

# EULA and Volumes
ARG DATA_DIR="/mcserver"
RUN mkdir "$DATA_DIR" && \
    echo "eula=true" > "$DATA_DIR/eula.txt" && \
    chown -R "$APP_USER":"$APP_USER" "$DATA_DIR"
VOLUME ["$DATA_DIR"]

#      GAME      RCON      QUERY
EXPOSE 25565/tcp 25575/tcp 25565/udp

USER "$APP_USER"
WORKDIR "$DATA_DIR"
ENV APP_BIN="$APP_BIN" \
    JAVA_OPT="-Xms8M -Xmx1G"
ENTRYPOINT exec java $JAVA_OPT -jar "$APP_BIN" nogui
