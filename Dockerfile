FROM alpine:3.11.3
RUN apk add --no-cache \
    openjdk11-jre-headless=11.0.5_p10-r0

ARG BIN_URL="https://launcher.mojang.com/v1/objects/bb2b6b1aefcd70dfd1892149ac3a215f6c636b07/server.jar"
ARG APP_BIN="/server.jar"
ADD "$BIN_URL" "$APP_BIN"
RUN chmod 644 "$APP_BIN"

ARG APP_USER="mc"
ARG APP_UID=1357
ARG APP_DIR="/mcserver"
RUN adduser --disabled-password --uid "$APP_UID" --home "$APP_DIR" --gecos mcserver --shell /sbin/nologin "$APP_USER"

USER "$APP_USER"
WORKDIR "$APP_DIR"
RUN echo "eula=true" > eula.txt
VOLUME ["$APP_DIR"]

EXPOSE 25565/tcp 25575/tcp 25565/udp
#      GAME      RCON      QUERY

ENV JAVA_OPT="-Xms8M -Xmx1G"
ENTRYPOINT exec java $JAVA_OPT -jar /server.jar nogui
