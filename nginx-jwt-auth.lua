local cjson_safe  = require 'cjson.safe'
local basexx = require 'basexx'
local digest = require 'openssl.digest'
local hmac = require 'openssl.hmac'
local pkey = require 'openssl.pkey'
local algo = "HS256"

-- -----------------------------------------------------------------------------
-- unauthorized
-- -----------------------------------------------------------------------------
function unauthorized()
  ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- -----------------------------------------------------------------------------
-- algoSign
-- -----------------------------------------------------------------------------
local algoSign = {
  ['HS256'] = function(data, key)
	        return hmac.new(key, 'sha256'):final(data)
	      end,
  ['HS384'] = function(data, key)
	        return hmac.new(key, 'sha384'):final(data)
	      end,
  ['HS512'] = function(data, key)
	        return hmac.new(key, 'sha512'):final(data)
	      end
}

-- -----------------------------------------------------------------------------
-- algoVerify
--
-- verify method depends on the algorithm
-- -----------------------------------------------------------------------------
local algoVerify = {
  ['HS256'] = function(data, sign, key)
                return sign == algoSign['HS256'](data, key)
              end,
  ['HS384'] = function(data, sign, key)
                return sign == algoSign['HS384'](data, key)
              end,
  ['HS512'] = function(data, sign, key)
                return sign == algoSign['HS512'](data, key)
              end
}

-- -----------------------------------------------------------------------------
-- splitToken
--
-- token is a string with header, payload and signature combined with dots
-- -----------------------------------------------------------------------------
function splitToken(token)
  local segments={}
  for seg in string.gmatch(token, "[^.]+") do
    table.insert(segments, seg)
  end

  return segments
end

-- -----------------------------------------------------------------------------
-- parseToken
-- -----------------------------------------------------------------------------
function parseToken(token)
  local segments = splitToken(token)
  if #segments ~= 3 then unauthorized() end

  -- decode the header of token
  local header, err = cjson_safe.decode(basexx.from_url64(segments[1]))
  if err then unauthorized() end

  -- decode the payload of token
  local payload, err = cjson_safe.decode(basexx.from_url64(segments[2]))
  if err then unauthorized() end

  -- decode the signature of token
  local sign, err = basexx.from_url64(segments[3])
  if err then unauthorized() end

  -- data is the combination of the header and the payload without the signature
  local data = segments[1] .. "." .. segments[2]

  return header, payload, sign, data
end

-- -----------------------------------------------------------------------------
-- verify
-- -----------------------------------------------------------------------------
function verify(token, algo, key)
  local header, payload, sign, data = parseToken(token)

  if not header.typ or header.typ ~= "JWT" then unauthorized() end
  if not header.alg or header.alg ~= algo then unauthorized() end
  -- validate the token
  if not algoVerify[algo](data, sign, key) then unauthorized() end
  -- validate exp (expire time) if exists in the payload
  if payload.exp and type(payload.exp) ~= "number" then unauthorized() end
  if payload.exp and os.time() >= payload.exp then unauthorized() end
  -- validate nbf (not before time) if exists in the payload
  if payload.nbf and type(payload.nbf) ~= "number" then unauthorized() end
  if payload.nbf and os.time() < payload.nbf then unauthorized() end

  return true
end

-- -----------------------------------------------------------------------------
-- main
-- -----------------------------------------------------------------------------
-- get key from Nginx config
local key;
if ngx.var.jwt_key then
  key = ngx.var.jwt_key
elseif ngx.var.jwt_key_file then
  local f = io.open(ngx.var.jwt_key_file, "rb")
  key = f:read(_VERSION <= "Lua 5.2" and "*a" or "a")
  f.close()
else
  ngx.log(ngx.ERR, "JWT key is not found")
  unauthorized()
end

-- get algorithm from Nginx config
-- if it is not provided, use the default one
if ngx.var.jwt_algo then
  algo = ngx.var.jwt_algo
end

-- check if algorithm is supported
if not algoVerify[algo] then
  ngx.log(ngx.ERR, "JWT algoritm is not supported")
  unauthorized()
end

-- get the authorization header from the request
local headers = ngx.req.get_headers()
local auth = headers["authorization"]
if (not auth) then unauthorized() end
if (not string.match(auth, "^Bearer ")) then unauthorized() end

-- parse the token from the authorization header and verify it
local token = string.sub(auth, 8)
if (not token) then unauthorized() end
if (not verify(token, algo, key)) then unauthorized() end
