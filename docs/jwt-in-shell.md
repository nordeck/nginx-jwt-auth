# JWT in Shell

### HS256

```bash
SECRET="myappsecret"

HEADER=$(echo -n '{"alg":"HS256","typ":"JWT"}' | \
    base64 | tr '+/' '-_' | tr -d '=\n')

PAYLOAD=$(echo -n '{"sub":"1234567890","name":"Nordeck"}' | \
    base64 | tr '+/' '-_' | tr -d '=\n')

SIGN=$(echo -n "$HEADER.$PAYLOAD" | \
    openssl dgst -binary -sha256 -hmac $SECRET | \
    base64 | tr '+/' '-_' | tr -d '=\n')

curl -k -L -H "Authorization: Bearer $HEADER.$PAYLOAD.$SIGN" \
    https://172.18.18.40/hello
```

### RS256

```bash
HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | \
    base64 | tr '+/' '-_' | tr -d '=\n')

PAYLOAD=$(echo -n '{"sub":"1234567890","name":"Nordeck"}' | \
    base64 | tr '+/' '-_' | tr -d '=\n')

SIGN=$(echo -n "$HEADER.$PAYLOAD" | \
    openssl dgst -sha256 -binary -sign /path/rsa-private.key | \
    openssl enc -base64 | tr '+/' '-_' | tr -d '=\n')

curl -k -L -H "Authorization: Bearer $HEADER.$PAYLOAD.$SIGN" \
    https://172.18.18.40/hello
```
