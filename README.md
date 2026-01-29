# MCServer
Small and simple vanilla minecraft server.

## Running the server
```bash
docker run --rm --detach --interactive --publish 25565:25565 --name mcserver hetsh/mcserver
```

## Stopping the server
```bash
echo stop | docker attach mcserver
```
Because the minecraft server does not handle the `SIGTERM` signal that is sent by `docker stop` gracefully, it is necessary to use the `stop` command to prevent data loss when shutting down the container. This is only possible when the container was started with the `--interactive` flag.

## Creating persistent storage
Create persistent storage on your host to avoid data loss:
```bash
MP="/path/to/storage"
mkdir -p "$MP"
# Accept the Minecraft EULA
# https://www.minecraft.net/eula
echo "eula=true" > "$MP/eula.txt"
chown -R 1357:1357 "$MP"
```
`1357` is the numerical id of the user running the server (see Dockerfile).
The user must have RW access to the storage directory.
Start the container with this additional parameter:
```bash
docker run --volume /path/to/storage:/mcserver
```
