# jenkins-terraform-ec2 — Build Notes

## Status
- Plan approved ✅
- Architecture written ✅
- Pipeline written ✅
- Design approved ✅
- Files generated ✅

## Decisions
- Jenkins on EC2 t3.medium (2 vCPU / 4 GB) — sufficient for a small team running Terraform pipelines
- Nginx reverse proxy on :80 → Jenkins on :8080 (Jenkins not exposed directly)
- Setup wizard disabled via JAVA_OPTS; admin user seeded via Groovy init script (no_log: true)
- IAM instance role grants EC2 + S3 + IAM permissions so Jenkins pipeline jobs can run Terraform without storing long-lived keys on the instance (instance profile picks them up automatically)
- Target EC2 Terraform lives in infra/target-ec2/ with its own S3 state key (project/target-ec2/terraform.tfstate)
- Jenkins job "Deploy-EC2" seeded via CLI (jenkins-cli.jar) from Ansible; idempotent via creates: guard on config.xml
- REPO_URL_PLACEHOLDER in seed-job.xml: user must update this with the actual GitHub repo URL after first deploy (or do it in Jenkins UI)

## Known post-deploy steps for user
1. Update Deploy-EC2 job: replace REPO_URL_PLACEHOLDER with actual GitHub repo URL
2. Add Jenkins credentials: aws-credentials (user/pass), TF_STATE_BUCKET (secret text), SSH_PUBLIC_KEY (secret text)

## Secrets
- JENKINS_ADMIN_PASSWORD — set via set_pipeline_secret before deploy

## Next
- validate_project
- test_project
- create_repo_and_push
- set_pipeline_secret JENKINS_ADMIN_PASSWORD
- deploy
