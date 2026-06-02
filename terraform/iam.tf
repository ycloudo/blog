# OIDC
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

data "aws_caller_identity" "current" {}

# Deploy Role (Only for Hugo content sync & cache invalidation)
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ycloudo/blog:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "github-actions-blog-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.content.arn,
      "${aws_s3_bucket.content.arn}/*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.apex.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "blog-deploy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}

# Terraform CI: Plan Role (Read-Only)
data "aws_iam_policy_document" "github_actions_tf_plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ycloudo/blog:pull_request"]
    }
  }
}

resource "aws_iam_role" "github_actions_tf_plan" {
  name               = "github-actions-blog-tf-plan"
  assume_role_policy = data.aws_iam_policy_document.github_actions_tf_plan_trust.json
}

data "aws_iam_policy_document" "github_actions_tf_plan_policy" {
  statement {
    sid       = "InfraReadOnly"
    effect    = "Allow"
    actions   = ["s3:Get*", "s3:List*", "cloudfront:Get*", "cloudfront:List*", "cloudfront:Describe*", "acm:Describe*", "acm:List*", "iam:Get*", "iam:List*"]
    resources = ["*"]
  }

  statement {
    sid    = "StateLockingReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::cloudoblog-s3",
      "arn:aws:s3:::cloudoblog-s3/*",
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_tf_plan" {
  name   = "blog-tf-plan"
  role   = aws_iam_role.github_actions_tf_plan.id
  policy = data.aws_iam_policy_document.github_actions_tf_plan_policy.json
}

# Terraform CI: Apply Role (Read-Write)
data "aws_iam_policy_document" "github_actions_tf_apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ycloudo/blog:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_tf_apply" {
  name               = "github-actions-blog-tf-apply"
  assume_role_policy = data.aws_iam_policy_document.github_actions_tf_apply_trust.json
}

data "aws_iam_policy_document" "github_actions_tf_apply" {
  statement {
    sid     = "ContentAndStateBuckets"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.content.arn,
      "${aws_s3_bucket.content.arn}/*",
      "arn:aws:s3:::cloudoblog-s3",
      "arn:aws:s3:::cloudoblog-s3/*",
    ]
  }

  statement {
    sid       = "CloudFrontAndAcm"
    effect    = "Allow"
    actions   = ["cloudfront:*", "acm:*"]
    resources = ["*"]
  }

  statement {
    sid    = "ManageBlogRoles"
    effect = "Allow"
    actions = [
      "iam:GetRole", "iam:CreateRole", "iam:DeleteRole", "iam:TagRole", "iam:UntagRole",
      "iam:ListRolePolicies", "iam:GetRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:ListAttachedRolePolicies", "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:PassRole"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-blog*"]
  }

  statement {
    sid    = "ManageOIDCProvider"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider", "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider", "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:AddClientIDToOpenIDConnectProvider", "iam:TagOpenIDConnectProvider"
    ]
    resources = [aws_iam_openid_connect_provider.github_actions.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_tf_apply" {
  name   = "blog-tf-apply"
  role   = aws_iam_role.github_actions_tf_apply.id
  policy = data.aws_iam_policy_document.github_actions_tf_apply.json
}

# Outputs
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}

output "github_actions_tf_plan_role_arn" {
  value = aws_iam_role.github_actions_tf_plan.arn
}

output "github_actions_tf_apply_role_arn" {
  value = aws_iam_role.github_actions_tf_apply.arn
}