### Dependencies

```bash
apt-get install libnginx-mod-http-lua
apt-get install lua-cjson lua-basexx lua-luaossl
```

### Nginx config

```conf
location /hello {
    set $jwt_key "myappsecret";
    access_by_lua_file /usr/local/share/nginx-jwt-auth.lua;
}
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
