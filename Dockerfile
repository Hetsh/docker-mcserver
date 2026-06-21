FROM hetsh/alpine:20260127-8
ARG LAST_UPGRADE="2026-06-21T12:19:51+02:00"
RUN apk upgrade --no-cache && \
	apk add --no-cache \
		openjdk21-jre-headless=21.0.11_p10-r0

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
ARG BIN_URL="https://piston-data.mojang.com/v1/objects/823e2250d24b3ddac457a60c92a6a941943fcd6a/server.jar"
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