FROM alpine:3.11.3
RUN apk add --no-cache \
    openjdk11-jre-headless=11.0.5_p10-r0

ARG APP_USER="mc"
RUN adduser -D -u 1357 "$APP_USER"

ARG APP_BIN="/server.jar"
ARG BIN_URL="https://launcher.mojang.com/v1/objects/bb2b6b1aefcd70dfd1892149ac3a215f6c636b07/server.jar"
ADD "$BIN_URL" "$APP_BIN"
RUN chown "$APP_USER":"$APP_USER" "$APP_BIN"

ARG APP_DIR="/mcserver"
WORKDIR "$APP_DIR"
RUN echo "eula=true" > eula.txt && \
    chown -R "$APP_USER":"$APP_USER" .

USER "$APP_USER"
VOLUME ["$APP_DIR"]
EXPOSE 25565/tcp 25575/tcp 25565/udp
#      GAME      RCON      QUERY

ENV JAVA_OPT="-Xms8M -Xmx1G"
ENV APP_BIN="$APP_BIN"
ENTRYPOINT exec java $JAVA_OPT -jar "$APP_BIN" nogui
