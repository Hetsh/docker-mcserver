FROM library/alpine:20200917
RUN apk add --no-cache \
    openjdk11-jre-headless=11.0.9_p11-r0

# App user
ARG APP_USER="mc"
ARG APP_UID=1357
RUN adduser --disabled-password --uid "$APP_UID" --no-create-home --gecos "$APP_USER" --shell /sbin/nologin "$APP_USER"

# Server binary
ARG BIN_URL="https://launcher.mojang.com/v1/objects/f02f4473dbf152c23d7d484952121db0b36698cb/server.jar"
ARG APP_BIN="/opt/server.jar"
ADD "$BIN_URL" "$APP_BIN"
RUN chmod 644 "$APP_BIN"

# EULA and Volumes
ARG DATA_DIR="/mcserver"
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
