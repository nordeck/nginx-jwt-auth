# Generating RSA keys

Tested in `Debian 12 Bookworm`.

```bash
mkdir -p rsa-keys
cd rsa-keys

openssl genrsa -out jwt-rsa.key 4096
openssl rsa -in jwt-rsa.key -pubout -outform PEM -out jwt-rsa.pub
```

- `jwt-rsa.key` is the private key

- `jwt-rsa.pub` is the public key
