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

  local header, err = cjson_safe.decode(basexx.from_url64(segments[1]))
  if err then unauthorized() end

  local payload, err = cjson_safe.decode(basexx.from_url64(segments[2]))
  if err then unauthorized() end

  local sign, err = basexx.from_url64(segments[3])
  if err then unauthorized() end

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
  if not algoVerify[algo](data, sign, key) then unauthorized() end
  if payload.exp and type(payload.exp) ~= "number" then unauthorized() end
  if payload.exp and os.time() >= payload.exp then unauthorized() end
  if payload.nbf and type(payload.nbf) ~= "number" then unauthorized() end
  if payload.nbf and os.time() < payload.nbf then unauthorized() end

  return true
end

-- -----------------------------------------------------------------------------
-- main
-- -----------------------------------------------------------------------------
if not (ngx.var.jwt_key or ngx.var.jwt_key_file) then
  ngx.log(ngx.ERR, "JWT key is not found")
  unauthorized()
end

local key = ngx.var.jwt_key

if ngx.var.jwt_algo then
  algo = ngx.var.jwt_algo
end

if not algoVerify[algo] then
  ngx.log(ngx.ERR, "JWT algoritm is not supported")
  unauthorized()
end

local headers = ngx.req.get_headers()
local auth = headers["authorization"]
if (not auth) then unauthorized() end
if (not string.match(auth, "^Bearer ")) then unauthorized() end

local token = string.sub(auth, 8)
if (not token) then unauthorized() end
if (not verify(token, algo, key)) then unauthorized() end
