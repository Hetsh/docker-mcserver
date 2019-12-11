FROM alpine:3.10.3
RUN apk add --no-cache openjdk11-jre-headless

ARG MC_USER="mc"
ARG MC_URL="https://launcher.mojang.com/v1/objects/e9f105b3c5c7e85c7b445249a93362a22f62442d/server.jar"
ARG MC_DIR="/mcserver"
ARG MC_JAR="/server.jar"

RUN adduser -D -u 1357 "$MC_USER"
ADD --chown=mc:mc "$MC_URL" "$MC_JAR"
USER "$MC_USER"
WORKDIR "$MC_DIR"
VOLUME ["$MC_DIR"]
EXPOSE 25565

ENV JAVA_OPT="-Xms8M -Xmx1G"
ENV MC_JAR="$MC_JAR"
ENTRYPOINT exec java -jar $JAVA_OPT "$MC_JAR" nogui
