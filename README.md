# workshop-auth-lambda

## Visão Geral

Este repositório contém o **serviço de autenticação serverless** da arquitetura.

Ele é executado como um **Knative Service** dentro do cluster Kubernetes e atua como **gateway de autenticação**, sendo totalmente desacoplado da aplicação principal.

---

## Responsabilidades

- Validar CPF do usuário
- Consultar o usuário na API interna (`workshop`)
- Gerar token JWT
- Validar token JWT
- Servir como middleware de autenticação via Ingress

---

## Fluxo de Autenticação

1. Cliente faz requisição para `/auth`
2. Serviço valida o CPF
3. Consulta a API Rails para validar o usuário
4. Gera e retorna um JWT
5. Requisições subsequentes passam por `/auth/validate`
6. Token válido permite acesso à API principal

---

## Endpoints

| Método | Endpoint         | Descrição |
|-------|------------------|-----------|
| POST  | `/auth`          | Geração de token JWT |
| GET   | `/auth/validate` | Validação de token (auth_request) |

---

## Tecnologias Utilizadas

- Knative
- Kubernetes
- Docker
- JWT
- Ruby

---

## Características Importantes

- Stateless
- Scale-to-zero
- Não possui banco de dados
- Totalmente desacoplado da aplicação principal

---

## Deploy

O deploy é realizado via pipeline de CI/CD, gerando uma imagem Docker e aplicando um Knative Service no cluster.

---

## Observabilidade

- Métricas, logs e traces coletados via Datadog
- Integração automática com o Datadog Agent do cluster
