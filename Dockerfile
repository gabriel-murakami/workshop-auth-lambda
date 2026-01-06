FROM ruby:3.2-slim

WORKDIR /app

RUN gem install jwt cpf_cnpj webrick

COPY app.rb .

EXPOSE 8080

CMD ["ruby", "app.rb"]
