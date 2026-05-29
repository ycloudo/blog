# Personal Blog — Project Context

## Goals
- Learn fundamentals of AWS cloud infrastructure through hands-on usage
- Build a personal blog for recording writing and documentation

---

## Stack Decisions

| Concern | Decision | Rationale |
|---|---|---|
| Hosting | S3 + CloudFront | Canonical static site pattern on AWS; teaches IAM, S3, CDN |
| CI/CD | GitHub Actions | Free, simpler than CodePipeline; still covers AWS primitives via OIDC + aws-actions |
| DNS | Route 53 (delegated from GoDaddy) | Enables Route 53 learning; required for ACM DNS validation |
| IaC | Terraform | Industry standard, transferable across cloud providers |
| Terraform state | S3 + DynamoDB (remote backend) | Versioned, locked, production-standard; bootstrapped manually before main infra |
| SSL | ACM certificate, DNS-validated via Route 53 | Must be provisioned in us-east-1 for CloudFront |
| Hugo theme | PaperMod | Actively maintained, minimal, dark mode, built-in search and ToC |
| Domain | Apex canonical (`yourdomain.com`), `www` redirects to apex | Modern standard; requires two S3 buckets + two CloudFront distributions |
| AWS region | us-east-1 | Cheapest, most services, required region for ACM + CloudFront |
| Repo structure | Monorepo (Hugo + Terraform in one repo) | Simpler for a personal project; GitHub Actions scoped by directory |
| Content organization | Categories + Tags | Broad grouping via categories, specific topics via tags; PaperMod supports both natively |
| Comments | Skipped for now | Can add Giscus later if needed |
| Analytics | Skipped for now | Phase 2: enable CloudFront access logs, integrate with Grafana |

---

## Repository Structure

```
/
├── terraform/            # infrastructure (S3, CloudFront, Route 53, ACM)
├── content/
│   ├── posts/
│   │   └── my-first-post/
│   │       ├── index.md  # page bundle — keeps images co-located
│   │       └── image.png
│   └── about.md
├── themes/               # PaperMod as git submodule
├── static/
├── config.yml
└── .github/
    └── workflows/        # GitHub Actions: build → s3 sync → CloudFront invalidation
```

---

## Infrastructure Overview

```
GoDaddy (registrar)
  └── nameservers → Route 53 hosted zone
        ├── A record (alias) → CloudFront distribution (apex)
        └── A record (alias) → CloudFront distribution (www → redirects to apex)

CloudFront (apex)  →  S3 bucket (hugo build output)
CloudFront (www)   →  S3 bucket (redirect only, no content)

ACM certificate (us-east-1, covers apex + www)
```

---

## Build Order

1. Buy domain on GoDaddy
2. Manually bootstrap Terraform remote state (S3 bucket with versioning + DynamoDB table)
3. Write Terraform: ACM → Route 53 → S3 buckets → CloudFront distributions
4. Delegate GoDaddy nameservers to Route 53
5. Initialize Hugo locally, add PaperMod as git submodule
6. Wire up GitHub Actions workflow (push to main → hugo build → aws s3 sync → CloudFront invalidation)
7. Write first post

---

## Image Handling

Use Hugo **page bundles**: create a folder per post containing `index.md` + images. Reference images as `![alt](image.png)`. Hugo copies them into `public/` at build time; GitHub Actions syncs everything to S3.

Best practices:
- Compress images before committing (use `squoosh` or `imageoptim`)
- Phase 2: consider a dedicated S3 media bucket if repo grows large

---

## Phase 2 Ideas

- CloudFront access logs → S3 → Athena or Grafana for traffic analytics
- Giscus comments (GitHub Discussions-backed)
- Dedicated S3 bucket for media/images
