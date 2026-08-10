#!/bin/bash
set -e

JENKINS_URL="http://127.0.0.1:8080"
JOB_XML="/var/jenkins_home/deploy-ec2-job.xml"
JOB_NAME="Deploy-EC2"
JOB_CONFIG_PATH="/var/jenkins_home/jobs/${JOB_NAME}/config.xml"
COOKIE_JAR="/tmp/jenkins-cookies-$$.txt"

# If job already exists, skip
if [ -f "${JOB_CONFIG_PATH}" ]; then
  echo "Job ${JOB_NAME} already exists — skipping"
  exit 0
fi

# Fetch crumb and session cookie in one request
CRUMB_RESPONSE=$(curl -s -c "${COOKIE_JAR}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  "${JENKINS_URL}/crumbIssuer/api/json")

CRUMB_FIELD=$(echo "${CRUMB_RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['crumbRequestField'])")
CRUMB_VALUE=$(echo "${CRUMB_RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['crumb'])")

if [ -z "${CRUMB_VALUE}" ]; then
  echo "ERROR: Failed to fetch Jenkins crumb"
  echo "${CRUMB_RESPONSE}"
  exit 1
fi

# Create job using same session cookie
HTTP_STATUS=$(curl -s -o /tmp/jenkins-create-output.txt -w "%{http_code}" \
  -b "${COOKIE_JAR}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  -H "${CRUMB_FIELD}: ${CRUMB_VALUE}" \
  -H "Content-Type: application/xml" \
  --data-binary "@${JOB_XML}" \
  "${JENKINS_URL}/createItem?name=${JOB_NAME}")

echo "HTTP status: ${HTTP_STATUS}"

if [ "${HTTP_STATUS}" = "200" ] || [ "${HTTP_STATUS}" = "201" ]; then
  echo "Job ${JOB_NAME} created successfully"
  rm -f "${COOKIE_JAR}"
  exit 0
fi

# 400 = job already exists (race condition or second run) — idempotent OK
if [ "${HTTP_STATUS}" = "400" ]; then
  echo "Job ${JOB_NAME} already exists (400) — OK"
  rm -f "${COOKIE_JAR}"
  exit 0
fi

echo "ERROR: Failed to create job — HTTP ${HTTP_STATUS}"
head -30 /tmp/jenkins-create-output.txt
rm -f "${COOKIE_JAR}"
exit 1
