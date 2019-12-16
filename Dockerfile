FROM alpine:3.10.3
RUN apk add --no-cache openjdk11-jre-headless

ARG APP_USER="mc"
RUN adduser -D -u 1357 "$APP_USER"

ARG APP_BIN="/server.jar"
ARG BIN_URL="https://launcher.mojang.com/v1/objects/e9f105b3c5c7e85c7b445249a93362a22f62442d/server.jar"
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
