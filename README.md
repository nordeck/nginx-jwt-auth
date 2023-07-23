### Nginx config

```conf
location /hello {
    set $jwt_key "myappsecret";
    access_by_lua_file /usr/local/share/nginx-jwt-auth.lua;
}
```
