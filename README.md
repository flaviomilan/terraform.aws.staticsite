# Terraform AWS Static Site

Terraform infrastructure for deploying **highly secure, scalable, and cost-effective** static sites on AWS using S3, CloudFront, Route53, ACM, and WAF.

## ✨ Features

### 🔒 Security
- **AWS WAF v2** with 5 layers of protection: Rate Limiting, OWASP Common Rules, Known Bad Inputs, IP Reputation, and Anonymous IP filtering
- **Complete Security Headers**: HSTS (preload), CSP, X-Frame-Options, X-Content-Type-Options, XSS-Protection, Referrer-Policy, Permissions-Policy
- **Private S3** with AES-256 encryption (SSE-S3), versioning, and exclusive access via CloudFront (OAC with SigV4)
- **TLS 1.2+** with configurable minimum protocol version
- **Flexible authentication**: supports both OIDC (recommended) and static access keys for GitHub Actions

### 🚀 Performance
- **CloudFront with HTTP/3** (QUIC) for low latency
- **IPv6** with A and AAAA records
- **Automatic compression** (Brotli/Gzip)
- **SSL Certificate** with SAN for root domain and www
- **SPA routing** via CloudFront Function

### 📊 Monitoring (opt-in)
- **CloudWatch Dashboard** with request, error, bytes, and cache hit rate metrics
- **Alarms** for 5xx/4xx error rate spikes and WAF block surges
- **Email notifications** via SNS
- **WAF Logging** to CloudWatch (block/count events only)
- **CloudFront Real-Time Metrics**

### 🔄 CI/CD
- **4-step deployment** with approval gates for safety
- **Terraform Plan** saved as artifact for review before applying
- **Automatic DNS propagation check** before certificate validation
- **Automatic CloudFront cache invalidation** after deploy

## 📁 Project Structure

```
├── src/                     # Main infrastructure
│   ├── main.tf              # Provider and backend
│   ├── variables.tf         # Input variables (with validations)
│   ├── locals.tf            # Local values and tags
│   ├── s3.tf                # S3 bucket (encryption, versioning, upload)
│   ├── cloudfront.tf        # CloudFront (HTTP/3, headers, OAC, function)
│   ├── acm.tf               # ACM certificate (DNS validation, SAN www)
│   ├── route53.tf           # DNS (A, AAAA, www, ACM validation)
│   ├── waf.tf               # WAF v2 (rate limit, managed rules, logging)
│   ├── monitoring.tf        # CloudWatch (dashboard, alarms, SNS)
│   ├── data.tf              # Data sources
│   ├── outputs.tf           # Outputs
│   └── function/
│       └── function.js      # CloudFront function (SPA rewrite)
│
├── bootstrap/               # Terraform state backend
│   ├── main.tf              # S3 + DynamoDB for state locking
│   ├── variables.tf
│   └── outputs.tf
│
└── .github/
    ├── workflows/
    │   ├── bootstrap.yml    # Create backend (manual, one-time)
    │   ├── deploy.yml       # Main deployment (4 steps)
    │   └── pr-check.yml     # PR validation
    └── dependabot.yml
```

## 🚀 Getting Started

### Prerequisites

1. **AWS Account** with permissions to create IAM, S3, CloudFront, Route53, ACM, and WAF resources
2. **Registered domain** at any registrar (Route 53, GoDaddy, Namecheap, etc.)
3. **GitHub repository** with GitHub Actions enabled

### Step 1: Configure AWS Authentication

You have two options for authenticating GitHub Actions with AWS:

#### Option A: Access Keys (simpler)

1. In your repository, go to **Settings > Secrets and variables > Actions**
2. Create two secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

#### Option B: OIDC (recommended for production)

OIDC uses short-lived tokens instead of long-lived access keys:

1. In the AWS console, go to **IAM > Identity providers > Add provider**
2. Select **OpenID Connect**
3. Provider URL: `https://token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Create an IAM Role with a trust policy for your repository:

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

6. Attach policies for S3, CloudFront, Route53, ACM, WAF, CloudWatch, and SNS
7. In your GitHub repository, add the secret `AWS_ROLE_ARN` with the role ARN

> **Note:** The workflows automatically detect which credentials are available. If `AWS_ROLE_ARN` is set, OIDC is used. Otherwise, it falls back to access keys.

### Step 2: Bootstrap State Backend (optional but recommended)

1. In GitHub, go to **Actions > Bootstrap State Backend > Run workflow**
2. Enter the S3 bucket name for the state
3. After execution, update `src/main.tf` with the S3 backend configuration

### Step 3: Configure Variables

Create a `src/terraform.tfvars` file:

```hcl
domain      = "yourdomain.com"
bucket_name = "yourdomain-static-site"
files_path  = "./function"

# Optional (all cost-bearing features default to false)
project_name         = "MySite"
environment          = "production"
enable_waf           = true
enable_monitoring    = true
enable_s3_versioning = true
notification_email   = "your@email.com"
csp_policy           = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
```

Add the `DOMAIN` variable in GitHub at **Settings > Environments > dns-validated > Environment variables**.

### Step 4: Deploy

1. **Push to `main`** — triggers the workflow
2. **Plan** runs automatically and saves the plan as an artifact
3. **DNS Deploy** — creates the Route53 zone and outputs nameservers in the logs
4. **Configure nameservers** at your domain registrar
5. **Wait for DNS propagation** (minutes to hours)
6. **Approve the `dns-validated` environment** — the workflow verifies DNS propagation and creates the ACM certificate + full infrastructure
7. **Approve the `production` environment** — uploads files and invalidates the cache

```
Push → [Plan] → [DNS Deploy] → Nameservers in logs
                                      ↓
                    Configure nameservers at registrar
                                      ↓
         [Approve dns-validated] → [Verify DNS] → [ACM + Infra]
                                                         ↓
               [Approve production] → [Upload + Cache Invalidation]
```

## ⚙️ Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `domain` | string | — | Site domain (e.g., `example.com`) |
| `bucket_name` | string | — | S3 bucket name |
| `files_path` | string | — | Path to static site files |
| `domain_enabled` | bool | `false` | Enable domain-related resources (ACM, CloudFront, etc.) |
| `enable_waf` | bool | `false` | Enable WAF (~$5/month + rules + requests) |
| `project_name` | string | `StaticSite` | Project name for tags |
| `environment` | string | `production` | Environment (development/staging/production) |
| `csp_policy` | string | restrictive | Customizable Content-Security-Policy |
| `waf_rate_limit` | number | `2000` | Max requests per 5min per IP |
| `enable_monitoring` | bool | `false` | CloudWatch dashboard and alarms (~$10-15/month) |
| `notification_email` | string | `""` | Email for alerts (empty = disabled) |
| `minimum_tls_version` | string | `TLSv1.2_2021` | Minimum TLS version |
| `force_destroy_zone` | bool | `false` | Allow DNS zone destruction |
| `enable_s3_versioning` | bool | `false` | S3 versioning (extra storage cost) |

## 💰 Estimated Costs

All cost-bearing features are **opt-in** (disabled by default).

| Resource | Free Tier | Cost (if enabled) | Variable |
|---|---|---|---|
| S3 + CloudFront | 5GB + 1TB/month + 10M req | < $0.05/month | always active |
| Route53 | — | $0.50/month per zone | always active |
| ACM | Free | Free | always active |
| S3 Versioning | — | ~$0.02-2.00/month | `enable_s3_versioning` |
| WAF | — | ~$7-10/month | `enable_waf` |
| Monitoring | 10 free alarms | ~$10-15/month | `enable_monitoring` |

## 🔧 Troubleshooting

### DNS not propagated after hours
- Verify nameservers were correctly configured at the registrar
- Use `dig NS yourdomain.com` to check propagation
- Some registrars take up to 48 hours to propagate

### ACM certificate stuck in "Pending validation"
- Confirm nameservers point to Route53
- Check validation records: `dig CNAME _acm-challenge.yourdomain.com`
- ACM has a 72-hour timeout for validation

### CloudFront 403 error
- The S3 bucket is private by design — access only via CloudFront
- Verify the bucket policy references the correct CloudFront distribution

### WAF blocking legitimate requests
- Review WAF logs in CloudWatch (`aws-waf-logs-*`)
- Adjust `waf_rate_limit` as needed

### CI failing with "Credentials could not be loaded"
- Ensure either `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` or `AWS_ROLE_ARN` secrets are configured
- For OIDC, verify the IAM OIDC provider and role trust policy are set up correctly
- The PR quality check workflow does **not** require AWS credentials

## 🤝 Contributing

Contributions are welcome! Open issues and pull requests to improve this project.
