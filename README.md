# mcserver
Super small and simple vanilla minecraft server.

## Running the server
```bash
docker run -d --interactive --name mcserver --publish 25565:25565 --mount type=bind,source=/path/to/storage,target=/mcserver hetsh/mcserver
```
`--interactive` enables passing commands to the running server (required for shutdown).

## Stopping the container
```bash
echo stop | docker attach mcserver
```
Because the minecraft server does not catch the `SIGTERM` signal that is sent by `docker stop`, we have to gracefully shut down the server by piping the `stop` command to container.

## Creating persistent storage
```bash
MP="/path/to/storage"
mkdir -p "$MP"
echo "eula=true" > "$MP/eula.txt"
chown -R 1357:1357 "$MP"
```
`1357` is the numerical id of the user running the server (see Dockerfile). Mojang also requires you to accept their EULA. Honestly, you would just klick 'accept' anyway...

## Automate startup and shutdown via systemd
```bash
systemctl enable mcserver@<port> --now
```
The systemd unit can be found in my [GitHub](https://github.com/Hetsh/docker-mcserver) repository. Individual server instances are distinguished by host-port. By default, the systemd service assumes `/srv/mcserver_<port>` for persistent storage.

## Fork Me!
This is an open project (visit [GitHub](https://github.com/Hetsh/docker-mcserver)). Please feel free to ask questions, file an issue or contribute to it.