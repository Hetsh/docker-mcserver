FROM alpine:3.10.3
RUN apk add --no-cache openjdk11-jre-headless

ARG MC_USER="mc"
RUN adduser -D -u 1357 "$MC_USER"

ARG MC_JAR="/server.jar"
ARG MC_URL="https://launcher.mojang.com/v1/objects/e9f105b3c5c7e85c7b445249a93362a22f62442d/server.jar"
ADD "$MC_URL" "$MC_JAR"
RUN chown "$MC_USER":"$MC_USER" "$MC_JAR"

ARG MC_DIR="/mcserver"
WORKDIR "$MC_DIR"
RUN echo "eula=true" > eula.txt && \
    chown -R "$MC_USER":"$MC_USER" .

USER "$MC_USER"
VOLUME ["$MC_DIR"]
EXPOSE 25565/tcp 25575/tcp 25565/udp
#      GAME      RCON      QUERY

ENV JAVA_OPT="-Xms8M -Xmx1G"
ENV MC_JAR="$MC_JAR"
ENTRYPOINT exec java $JAVA_OPT -jar "$MC_JAR" nogui
