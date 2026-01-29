FROM amd64/alpine:20260127
ARG LAST_UPGRADE="2026-01-29T13:20:47+01:00"
RUN apk upgrade && \
	apk add --no-cache \
		openjdk21-jre-headless=21.0.10_p7-r0

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

USER "$APP_USER"
ENTRYPOINT ["java", "-Xmx1G", "-jar", "/opt/server.jar", "--nogui"]