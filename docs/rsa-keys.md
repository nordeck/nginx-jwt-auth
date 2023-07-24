# Generating RSA keys

Tested in `Debian 12 Bookworm`.

```bash
mkdir -p rsa-keys
cd rsa-keys

ssh-keygen -qP '' -t rsa -b 4096 -m PEM -f my-jwt.key
openssl rsa -in my-jwt.key -pubout -outform PEM -out my-jwt.pub

rm -f my-jwt.key.pub
```

- `my-jwt.key` is the private key

- `my-jwt.pub` is the public key
