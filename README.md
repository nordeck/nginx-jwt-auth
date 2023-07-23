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
