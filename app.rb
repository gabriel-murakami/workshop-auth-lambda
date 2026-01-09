require "json"
require "jwt"
require "cpf_cnpj"
require "net/http"
require "uri"
require "webrick"

JWT_SECRET = ENV.fetch("JWT_SECRET")
JWT_TTL    = 900
JWT_ISS    = "auth.local"
JWT_AUD    = "api.local"

APP_BASE_URL       = ENV.fetch("APP_BASE_URL")
INTERNAL_AUTH_TOKEN = ENV.fetch("INTERNAL_AUTH_TOKEN")

PORT = 8080

def json_response(res, status, payload)
  res.status = status
  res["Content-Type"] = "application/json"
  res.body = payload.to_json
end

def client_active?(cpf, password)
  uri = URI("#{APP_BASE_URL}/internal/users/#{cpf}")

  request = Net::HTTP::Post.new(uri)
  request["X-Internal-Token"] = INTERNAL_AUTH_TOKEN
  request["Content-Type"] = "application/json"

  request.body = {
    password: password
  }.to_json

  response = Net::HTTP.start(
    uri.hostname,
    uri.port,
    open_timeout: 2,
    read_timeout: 2
  ) do |http|
    http.request(request)
  end

  response.code.to_i == 200
rescue
  false
end

def generate_jwt(cpf, client_id)
  payload = {
    sub: client_id,
    cpf: cpf,
    iss: JWT_ISS,
    aud: JWT_AUD,
    exp: Time.now.to_i + JWT_TTL
  }

  JWT.encode(payload, JWT_SECRET, "HS256")
end

server = WEBrick::HTTPServer.new(
  Port: PORT,
  AccessLog: [],
  Logger: WEBrick::Log.new($stdout, WEBrick::Log::INFO)
)

server.mount_proc "/auth" do |req, res|
  begin
    unless req.request_method == "POST"
      json_response(res, 405, error: "Method not allowed")
      next
    end

    body = JSON.parse(req.body || "{}")
    cpf  = body["cpf"]
    password = body["password"]

    unless cpf && CPF.valid?(cpf)
      json_response(res, 400, error: "CPF inválido")
      next
    end

    unless client_active?(cpf, password)
      json_response(res, 403, error: "Usuário inexistente ou autenticação inválida")
      next
    end

    client_id = "client-#{cpf[-4..]}"

    token = generate_jwt(cpf, client_id)

    json_response(res, 200, token: token)
  rescue JSON::ParserError
    json_response(res, 400, error: "Payload inválido")
  rescue => e
    json_response(res, 500, error: "Erro interno")
  end
end

server.mount_proc "/auth/validate" do |req, res|
  begin
    auth = req["Authorization"]
    unless auth&.start_with?("Bearer ")
      res.status = 401
      next
    end

    token = auth.split.last

    payload, = JWT.decode(
      token,
      JWT_SECRET,
      true,
      {
        algorithm: "HS256",
        iss: JWT_ISS,
        aud: JWT_AUD
      }
    )

    res.status = 200
    res["X-User-Id"]  = payload["sub"]
    res["X-User-CPF"] = payload["cpf"]

  rescue JWT::ExpiredSignature, JWT::DecodeError
    res.status = 401
  end
end

trap("INT") { server.shutdown }
trap("TERM") { server.shutdown }

server.start
