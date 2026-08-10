#!/bin/bash
# create-job.sh — idempotent Jenkins job creation via REST API
# Called by Ansible with JENKINS_ADMIN_PASSWORD set in the environment.
set -e

JENKINS_URL="http://127.0.0.1:8080"
JOB_NAME="Deploy-EC2"
JOB_XML="/tmp/deploy-ec2-job.xml"   # host path — written by Ansible copy task
COOKIE_JAR="/tmp/jenkins-cookies-$$.txt"

echo "==> Checking if job '${JOB_NAME}' already exists..."
EXIST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  "${JENKINS_URL}/job/${JOB_NAME}/api/json")

if [ "${EXIST_STATUS}" = "200" ]; then
  echo "Job '${JOB_NAME}' already exists — skipping."
  exit 0
fi

echo "==> Fetching Jenkins crumb..."
CRUMB_RESPONSE=$(curl -s -c "${COOKIE_JAR}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  "${JENKINS_URL}/crumbIssuer/api/json")

echo "Crumb response: ${CRUMB_RESPONSE}"

CRUMB_FIELD=$(echo "${CRUMB_RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['crumbRequestField'])")
CRUMB_VALUE=$(echo "${CRUMB_RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['crumb'])")

if [ -z "${CRUMB_VALUE}" ]; then
  echo "ERROR: Empty crumb — Jenkins auth failed. Check JENKINS_ADMIN_PASSWORD."
  exit 1
fi

echo "==> Creating job '${JOB_NAME}'..."
HTTP_STATUS=$(curl -s -o /tmp/jenkins-create-out.txt -w "%{http_code}" \
  -b "${COOKIE_JAR}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  -H "${CRUMB_FIELD}: ${CRUMB_VALUE}" \
  -H "Content-Type: application/xml" \
  --data-binary "@${JOB_XML}" \
  "${JENKINS_URL}/createItem?name=${JOB_NAME}")

echo "HTTP status: ${HTTP_STATUS}"
cat /tmp/jenkins-create-out.txt || true

rm -f "${COOKIE_JAR}" /tmp/jenkins-create-out.txt

if [ "${HTTP_STATUS}" = "200" ] || [ "${HTTP_STATUS}" = "201" ]; then
  echo "SUCCESS: Job '${JOB_NAME}' created."
  exit 0
fi

# 400 means the job already exists — idempotent OK
if [ "${HTTP_STATUS}" = "400" ]; then
  echo "Job '${JOB_NAME}' already exists (HTTP 400) — OK."
  exit 0
fi

echo "ERROR: Unexpected HTTP status ${HTTP_STATUS}"
exit 1
