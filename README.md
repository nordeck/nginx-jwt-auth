# nginx-jwt-auth

`Lua` module to authorize clients by validating `JWT` in `Nginx`.

### Dependencies

For `Debian`, install the following packages.

```bash
apt-get install libnginx-mod-http-lua
apt-get install lua-cjson lua-basexx lua-luaossl
```

### Installation

```bash
wget -O /usr/local/share/nginx-jwt-auth.lua \
    https://raw.githubusercontent.com/nordeck/nginx-jwt-auth/main/nginx-jwt-auth.lua
```

### Nginx config with jwt_key

```conf
location /hello {
    set $jwt_key "myappsecret";
    access_by_lua_file /usr/local/share/nginx-jwt-auth.lua;
}
```

### Nginx config with jwt_key_file

```conf
location /hello {
    set $jwt_key_file /path/secret;
    access_by_lua_file /usr/local/share/nginx-jwt-auth.lua;
}
```

```bash
echo -n "myappsecret" >/path/secret
```

### Testing

```bash
TOKEN="\
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ik5vcmRlY2siLCJuYmYiOjE1MTYyMzkwMjIsImV4cCI6MjAxNjIzOTAyMn0.\
OWw9KK7xPXBJ_AXbaETrhkPMw_2NNyrrrHHhwTwCnKY\
"

curl -L -H "Authorization: Bearer $TOKEN" https://my.host.address/hello
```
