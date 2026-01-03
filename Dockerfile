FROM amd64/alpine:20251224
ARG LAST_UPGRADE="2025-12-25T07:35:26+01:00"
RUN apk upgrade && \
    apk add --no-cache \
        openjdk21-jre-headless=21.0.9_p10-r0

# App user
ARG APP_USER="mcserver"
ARG APP_UID=1357
RUN adduser \
        --disabled-password \
        --uid "$APP_UID" \
        --no-create-home \
        --gecos "$APP_USER" \
        --shell /sbin/nologin \
        "$APP_USER"

# Server binary
ARG BIN_URL="https://piston-data.mojang.com/v1/objects/64bb6d763bed0a9f1d632ec347938594144943ed/server.jar"
ENV APP_BIN="/opt/server.jar"
RUN wget --quiet --output-document "$APP_BIN" "$BIN_URL"

# Working directory and EULA
ARG DATA_DIR="/mcserver"
RUN mkdir "$DATA_DIR" && \
    echo "eula=true" > "$DATA_DIR/eula.txt" && \
    chown -R "$APP_USER":"$APP_USER" "$DATA_DIR"
WORKDIR "$DATA_DIR"

#      GAME      RCON      QUERY
EXPOSE 25565/tcp 25575/tcp 25565/udp

USER "$APP_USER"
ENV JAVA_OPT="-Xmx1G"
ENTRYPOINT exec java $JAVA_OPT -jar "$APP_BIN" --nogui
