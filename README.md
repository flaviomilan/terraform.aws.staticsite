# Terraform AWS Static Site

Infraestrutura Terraform para deploy de sites estáticos **altamente seguros, escaláveis e de baixo custo** na AWS, utilizando S3, CloudFront, Route53, ACM e WAF.

## ✨ Recursos

### 🔒 Segurança
- **AWS WAF v2** com 5 camadas de proteção: Rate Limiting, OWASP Common Rules, Known Bad Inputs, IP Reputation e Anonymous IP filtering
- **Security Headers completos**: HSTS (preload), CSP, X-Frame-Options, X-Content-Type-Options, XSS-Protection, Referrer-Policy, Permissions-Policy
- **S3 privado** com criptografia AES-256 (SSE-S3), versionamento e acesso exclusivo via CloudFront (OAC com SigV4)
- **TLS 1.2+** com protocolo mínimo configurável
- **OIDC** para autenticação segura no GitHub Actions (sem access keys de longa duração)

### 🚀 Performance
- **CloudFront com HTTP/3** (QUIC) para baixa latência
- **IPv6** com registros A e AAAA
- **Compressão automática** (Brotli/Gzip)
- **Certificado SSL** com SAN para domínio principal e www
- **SPA routing** via CloudFront Function

### 📊 Monitoramento
- **CloudWatch Dashboard** com métricas de requests, erros, bytes e cache hit rate
- **Alarmes** para taxa de erros 5xx/4xx e picos de bloqueio WAF
- **Notificações por email** via SNS
- **WAF Logging** para CloudWatch (apenas eventos de bloqueio/contagem)
- **CloudFront Real-Time Metrics**

### 🔄 CI/CD
- **Deploy em 4 etapas** com approval gates para segurança
- **Terraform Plan** como artefato para review antes de aplicar
- **Verificação de propagação DNS** automática antes de validar certificados
- **Invalidação automática** do cache CloudFront após deploy

## 📁 Estrutura do Projeto

```
├── src/                     # Infraestrutura principal
│   ├── main.tf              # Provider e backend
│   ├── variables.tf         # Variáveis de entrada (com validações)
│   ├── locals.tf            # Valores locais e tags
│   ├── s3.tf                # Bucket S3 (criptografia, versionamento, upload)
│   ├── cloudfront.tf        # CloudFront (HTTP/3, headers, OAC, function)
│   ├── acm.tf               # Certificado ACM (DNS validation, SAN www)
│   ├── route53.tf           # DNS (A, AAAA, www, validação ACM)
│   ├── waf.tf               # WAF v2 (rate limit, regras gerenciadas, logging)
│   ├── monitoring.tf        # CloudWatch (dashboard, alarmes, SNS)
│   ├── data.tf              # Data sources
│   ├── outputs.tf           # Outputs
│   └── function/
│       └── function.js      # CloudFront function (SPA rewrite)
│
├── bootstrap/               # Backend para Terraform state
│   ├── main.tf              # S3 + DynamoDB para state locking
│   ├── variables.tf
│   └── outputs.tf
│
└── .github/
    ├── workflows/
    │   ├── bootstrap.yml    # Criar backend (manual, 1x)
    │   ├── deploy.yml       # Deploy principal (4 etapas)
    │   └── pr-check.yml     # Validação de PRs
    └── dependabot.yml
```

## 🚀 Começando

### Pré-requisitos

1. **Conta AWS** com permissões para criar IAM, S3, CloudFront, Route53, ACM e WAF
2. **Domínio registrado** em qualquer provedor (Route 53, GoDaddy, Namecheap, etc.)
3. **Repositório GitHub** com GitHub Actions habilitado

### Etapa 1: Configurar OIDC (recomendado)

Configure a autenticação OIDC entre GitHub Actions e AWS para eliminar o uso de access keys:

1. No console AWS, vá em **IAM > Identity providers > Add provider**
2. Selecione **OpenID Connect**
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Crie uma IAM Role com trust policy para seu repositório:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID::oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

6. Anexe políticas para S3, CloudFront, Route53, ACM, WAF, CloudWatch e SNS
7. No repositório GitHub, adicione o secret `AWS_ROLE_ARN` com o ARN da role criada

### Etapa 2: Bootstrap do State Backend (opcional mas recomendado)

1. No GitHub, vá em **Actions > Bootstrap State Backend > Run workflow**
2. Informe o nome do bucket S3 para o state
3. Após a execução, atualize `src/main.tf` com a configuração do backend S3

### Etapa 3: Configurar Variáveis

Crie um arquivo `src/terraform.tfvars`:

```hcl
domain      = "seudominio.com.br"
bucket_name = "seudominio-static-site"
files_path  = "./function"

# Opcionais
project_name       = "MeuSite"
environment        = "production"
enable_waf         = true
enable_monitoring  = true
notification_email = "seu@email.com"
csp_policy         = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
```

Adicione a variável `DOMAIN` no GitHub em **Settings > Environments > dns-validated > Environment variables**.

### Etapa 4: Deploy

1. **Push para `main`** — aciona o workflow
2. **Plan** executa automaticamente e salva o plano como artefato
3. **DNS Deploy** — cria a zona Route53 e exibe os nameservers nos logs
4. **Configure os nameservers** no seu registrador de domínio
5. **Aguarde a propagação DNS** (minutos a horas)
6. **Aprove o environment `dns-validated`** — o workflow verifica a propagação DNS e cria o certificado ACM + toda a infraestrutura
7. **Aprove o environment `production`** — faz upload dos arquivos e invalida o cache

```
Push → [Plan] → [DNS Deploy] → Nameservers nos logs
                                      ↓
                    Configurar nameservers no registrador
                                      ↓
         [Approve dns-validated] → [Verifica DNS] → [ACM + Infra]
                                                          ↓
               [Approve production] → [Upload + Cache Invalidation]
```

## ⚙️ Variáveis

| Variável | Tipo | Padrão | Descrição |
|---|---|---|---|
| `domain` | string | — | Domínio do site (ex: `example.com`) |
| `bucket_name` | string | — | Nome do bucket S3 |
| `files_path` | string | — | Caminho dos arquivos estáticos |
| `domain_enabled` | bool | `false` | Habilitar recursos de domínio (ACM, CloudFront, etc.) |
| `enable_waf` | bool | `false` | Habilitar WAF (~$5/mês + regras + requests) |
| `project_name` | string | `StaticSite` | Nome do projeto para tags |
| `environment` | string | `production` | Ambiente (development/staging/production) |
| `csp_policy` | string | restritivo | Content-Security-Policy customizável |
| `waf_rate_limit` | number | `2000` | Limite de requests por 5min por IP |
| `enable_monitoring` | bool | `false` | Dashboard e alarmes CloudWatch (~$10-15/mês) |
| `notification_email` | string | `""` | Email para alertas (vazio = desativado) |
| `minimum_tls_version` | string | `TLSv1.2_2021` | Versão mínima TLS |
| `force_destroy_zone` | bool | `false` | Permitir destruição da zona DNS |
| `enable_s3_versioning` | bool | `false` | Versionamento S3 (custo extra de armazenamento) |

## 💰 Custos Estimados

Todos os recursos com custo adicional são **opt-in** (desabilitados por padrão).

| Recurso | Free Tier | Custo (se habilitado) | Variável |
|---|---|---|---|
| S3 + CloudFront | 5GB + 1TB/mês + 10M req | < $0.05/mês | sempre ativo |
| Route53 | — | $0.50/mês por zona | sempre ativo |
| ACM | Grátis | Grátis | sempre ativo |
| S3 Versioning | — | ~$0.02-2.00/mês | `enable_s3_versioning` |
| WAF | — | ~$7-10/mês | `enable_waf` |
| Monitoramento | 10 alarmes grátis | ~$10-15/mês | `enable_monitoring` |

## 🔧 Troubleshooting

### DNS não propagou após horas
- Verifique se os nameservers foram configurados corretamente no registrador
- Use `dig NS seudominio.com` para verificar a propagação
- Alguns registradores levam até 48h para propagar

### Certificado ACM ficou preso em "Pending validation"
- Confirme que os nameservers apontam para o Route53
- Verifique os registros de validação: `dig CNAME _acm-challenge.seudominio.com`
- O ACM tem timeout de 72h para validação

### Erro 403 no CloudFront
- O bucket S3 é privado por design — acesse apenas via CloudFront
- Verifique se a policy do bucket referencia o CloudFront distribution correto

### WAF bloqueando requests legítimos
- Revise os logs do WAF no CloudWatch (`aws-waf-logs-*`)
- Ajuste o `waf_rate_limit` se necessário

## 🤝 Contribuições

Contribuições são bem-vindas! Abra issues e pull requests para melhorar este projeto.
