# MCServer
Super small and simple vanilla minecraft server.

## Running the server
```bash
docker run --rm --detach --interactive --name mcserver --publish 25565:25565 hetsh/mcserver
```

## Stopping the server
```bash
echo stop | docker attach mcserver
```
Because the minecraft server does not handle the `SIGTERM` signal that is sent by `docker stop`, it is necessary to use the `stop` command to gracefully shut down the container, which in turn is only possible when the container was started with the `--interactive` flag.

## Creating persistent storage
```bash
MP="/path/to/storage"
mkdir -p "$MP"
# Accept the Minecraft EULA
# https://www.minecraft.net/eula
echo "eula=true" > "$MP/eula.txt"
chown -R 1357:1357 "$MP"
```
`1357` is the numerical id of the user running the server (see Dockerfile).
Start the container with this additional parameter:
```
--volume /path/to/storage:/mcserver
```
`/mcserver` is the working directory inside the container (see Dockerfile).

## Automate startup and shutdown via systemd
The systemd unit can be found in my GitHub [repository](https://github.com/Hetsh/docker-mcserver).
```bash
systemctl enable mcserver@<port> --now
```
Individual server instances are distinguished by host-port.
By default, the systemd service assumes `/apps/mcserver/<port>` for persistent storage and `/etc/localtime` for timezone.
Since this is a personal systemd unit file, you might need to adjust some parameters to suit your setup.

## Fork Me!
This is an open project (visit [GitHub](https://github.com/Hetsh/docker-mcserver)).
Please feel free to ask questions, file an issue or contribute to it.