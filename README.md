
# RDS Provisioning Automation

A **SRE/DevOps automation tool** for generating AWS RDS infrastructure using **Bash, Terraform, Git, and GitHub Pull Requests**.

The goal is to make RDS provisioning **faster, safer, standardized, and fully traceable**.

## Workflow

```text
interactive User Input
    ↓
RDS Configuration
    ↓
Production Safety Checks ( Delete protection )
    ↓
Terraform Validate
    ↓
Auto Git Branch
    ↓
AUTO Commit & Push
    ↓
GitHub Pull Request
```

## Features

* **Simple and Interactive provisioning** — enter RDS name and instance size.
* **Automatic environment detection** — names containing `prod` are treated as production.
* **Production guardrail** — production RDS automatically gets:

  ```hcl
  deletion_protection = true
  ```
* **Terraform validation** — runs `terraform fmt` and `terraform validate`.
* **Duplicate protection** — prevents creating the same RDS resource twice.
* **Automatic Git branch** — creates `rds/<rds-name>`.
* **Tracked commits** — every RDS change is recorded in Git history.
* **Automatic Pull Request** — branch is pushed and a GitHub PR is created automatically.
* **No automatic deployment** — `terraform apply` is intentionally not executed.

## Why?

### Faster

Automates repetitive Terraform and Git operations.

### Safer

Production resources receive deletion protection automatically.

### Better Visibility

Infrastructure changes are visible as Terraform code, commits, branches, and Pull Requests.

### Easy to Track

Git provides a history of **what changed, when it changed, and who changed it**.

### Standardized

RDS resources follow the same naming, tagging, and configuration process.

### Reviewable

Infrastructure changes go through a Pull Request before deployment.

## Example

```text
RDS name: amanprodtest5
Instance: db.t3.medium
```

Automatically creates :

```text
rds/amanprodtest5
```

with:

```text
Environment: prod
Deletion Protection: true
Terraform Validation: PASSED
```

Then PR is created:

```text
Commit → Push → Pull Request → Human Review
```
<img width="1193" height="590" alt="PR" src="https://github.com/user-attachments/assets/794e4920-abf8-476c-ab90-6acd69e53efb" />

## Project Structure

```text
rds-provisioning-automation/
├── v3.sh
├── .gitignore
├── terraform/
│   └── rds.tf
└── output/
    └── <rds-name>.conf
```

## Technologies

* Bash
* Terraform
* AWS RDS
* Git
* GitHub CLI


