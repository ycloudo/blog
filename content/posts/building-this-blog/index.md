---
title: "Building This Blog on AWS"
date: 2026-05-29
draft: false
categories:
  - Cloud
tags:
  - AWS
  - Terraform
  - Hugo
  - CI/CD
description: "How I set up a personal blog using Hugo, S3, CloudFront, and GitHub Actions — and what I learned about AWS along the way."
---

## Why I built this

I wanted a hands-on AWS project that covered real production concerns: DNS, CDN, TLS, infrastructure-as-code, and CI/CD. A personal blog turned out to be the perfect canvas.

## The stack

| Concern | Choice |
|---|---|
| Static site generator | Hugo + PaperMod |
| Hosting | S3 + CloudFront |
| DNS | Route 53 (delegated from GoDaddy) |
| TLS | ACM (DNS-validated) |
| IaC | Terraform |
| CI/CD | GitHub Actions (OIDC auth) |

## How it works

A `git push` to `main` triggers a GitHub Actions workflow that builds the site with Hugo, syncs the output to S3, and invalidates the CloudFront cache. The whole process takes about two minutes.

The infrastructure is defined entirely in Terraform. Terraform state is stored remotely in an S3 bucket with DynamoDB locking.

## What I learned

More to come as I build this out.
