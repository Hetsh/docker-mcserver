FROM library/alpine:20201218
RUN apk add --no-cache \
    openjdk11-jre-headless=11.0.9_p11-r1

# App user
ARG APP_USER="mc"
ARG APP_UID=1357
RUN adduser --disabled-password --uid "$APP_UID" --no-create-home --gecos "$APP_USER" --shell /sbin/nologin "$APP_USER"

# Server binary
ARG BIN_URL="https://launcher.mojang.com/v1/objects/35139deedbd5182953cf1caa23835da59ca3d7cd/server.jar"
ARG APP_BIN="/opt/server.jar"
ADD "$BIN_URL" "$APP_BIN"
RUN chmod 644 "$APP_BIN"

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
ENV JAVA_OPT="-Xms8M -Xmx1G"
ENTRYPOINT exec java $JAVA_OPT -jar /opt/server.jar nogui
