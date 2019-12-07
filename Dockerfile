FROM alpine:3.10.3
RUN apk add --no-cache openjdk11-jre-headless

ARG MC_USER="mc"
ARG MC_URL="https://launcher.mojang.com/v1/objects/3dc3d84a581f14691199cf6831b71ed1296a9fdf/server.jar"
ARG MC_DIR="/mcserver"

RUN adduser -D -u 1357 "$MC_USER"
ADD --chown=mc:mc "$MC_URL" /server.jar
USER "$MC_USER"
WORKDIR "$MC_DIR"
VOLUME ["$MC_DIR"]
EXPOSE 25565
ENTRYPOINT ["java", "-jar", "/server.jar", "nogui"]
