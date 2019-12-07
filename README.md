# mcserver
Super simple vanilla minecraft server.

Quick start guide (run as root):
```bash
MP="/srv/mcserver"
mkdir -p "$MP"
echo "eula=true" > "$MP/eula.txt"
chown -R 1357:1357 "$MP"# 1357 is the numerical id of the user running the server. This is predefined and must not be changed!
docker run -d --name mcserver -p 25565:25565 --mount type=bind,source="$MP",target=/mcserver hetsh/mcserver
```
