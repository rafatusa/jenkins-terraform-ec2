# jenkins-terraform-ec2

A production-ready Jenkins CI/CD server on AWS EC2 with a built-in Terraform pipeline that deploys a second EC2 instance on demand.

## Architecture

```
Developer → GitHub → GitHub Actions CI/CD
                          │
                          ▼
                  Terraform provisions
                  Jenkins EC2 (t3.medium, Ubuntu 22.04)
                  + Elastic IP
                  + IAM role (EC2 + S3 for Terraform)
                          │
                  Ansible configures
                  Jenkins LTS + Nginx (:80 → :8080) + Terraform binary
                          │
                  Jenkins UI at http://<ELASTIC_IP>
                          │
                  Jenkins pipeline "Deploy-EC2"
                          ▼
                  Terraform deploys Target EC2 (t3.micro)
                  State → S3 (project/target-ec2/terraform.tfstate)
```

See `.udap/architecture.d2` for the architecture diagram source.

## Stack

| Component        | Technology                  |
|------------------|-----------------------------|
| Cloud            | AWS us-east-1               |
| Jenkins Server   | EC2 t3.medium, Ubuntu 22.04 |
| Web proxy        | Nginx (:80 → Jenkins :8080) |
| Configuration    | Ansible                     |
| IaC              | Terraform >= 1.5            |
| Target instance  | EC2 t3.micro, Ubuntu 22.04  |
| Terraform state  | S3 (platform-managed bucket)|
| CI/CD            | GitHub Actions              |

## Deploy

Deployment is fully automated through GitHub Actions on push to `main`.

### Pipeline stages

| Stage      | What it does                                        |
|------------|-----------------------------------------------------|
| provision  | Terraform: creates EC2, EIP, SG, IAM role           |
| configure  | Ansible: installs Java, Jenkins, Nginx, Terraform   |
| verify     | curl Jenkins /login with retries                    |

### First-time setup

After the first successful deploy, you must manually add Jenkins credentials for the Terraform pipeline:

1. Open Jenkins at `http://<ELASTIC_IP>` (IP shown in the Actions run log)
2. Log in as `admin` with the password from your `JENKINS_ADMIN_PASSWORD` secret
3. Go to **Manage Jenkins → Credentials → Global → Add Credentials**:
   - **Kind**: Username with password
   - **ID**: `aws-credentials`
   - **Username**: your `AWS_ACCESS_KEY_ID`
   - **Password**: your `AWS_SECRET_ACCESS_KEY`
4. Add another credential:
   - **Kind**: Secret text
   - **ID**: `TF_STATE_BUCKET`
   - **Secret**: your Terraform state bucket name (available from the Actions run log)
5. Add another credential:
   - **Kind**: Secret text
   - **ID**: `SSH_PUBLIC_KEY`
   - **Secret**: your SSH public key (used to provision the target EC2)

## Running the Deploy-EC2 Jenkins Pipeline

1. In Jenkins, click **Deploy-EC2**
2. Click **Build with Parameters**
3. Choose `ACTION`:
   - `plan` — show what Terraform would create (safe, no changes)
   - `apply` — provision the target EC2 instance (requires manual approval in the pipeline)
   - `destroy` — tear down the target EC2 instance (requires manual approval)
4. Set `INSTANCE_TYPE` (default `t3.micro`)

## Configuration

| Variable               | Where                     | Purpose                                  |
|------------------------|---------------------------|------------------------------------------|
| `JENKINS_ADMIN_PASSWORD` | GitHub repo secret      | Jenkins admin password (set by UDAP)     |
| `SSH_PUBLIC_KEY`       | GitHub repo secret        | Key injected into Jenkins + target EC2   |
| `SSH_PRIVATE_KEY`      | GitHub repo secret        | Used by Ansible to configure the server  |
| `TF_STATE_BUCKET`      | GitHub repo secret        | S3 bucket for Terraform state            |
| `AWS_ACCESS_KEY_ID`    | GitHub repo secret        | AWS credentials for Terraform            |
| `AWS_SECRET_ACCESS_KEY`| GitHub repo secret        | AWS credentials for Terraform            |

## Operations

### Access Jenkins logs
```bash
ssh -i <key> ubuntu@<ELASTIC_IP>
sudo journalctl -u jenkins -f
```

### Restart Jenkins
```bash
sudo systemctl restart jenkins
```

### Restart Nginx
```bash
sudo systemctl restart nginx
```

### Destroy the Jenkins server
Trigger the **Destroy** workflow from the GitHub Actions tab.

### Destroy the target EC2
Run the **Deploy-EC2** pipeline in Jenkins with `ACTION=destroy`.

## Cost

| Resource              | Approx cost/mo        |
|-----------------------|-----------------------|
| Jenkins EC2 t3.medium | ~$30                  |
| Elastic IP (attached) | ~$0                   |
| Target EC2 t3.micro   | ~$8 (when running)    |
| S3 state storage      | <$1                   |
