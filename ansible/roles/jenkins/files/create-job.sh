#!/bin/bash
# create-job.sh — idempotent Jenkins job creation via REST API
# Requires: JENKINS_ADMIN_PASSWORD set in the calling environment.
# The crumb and session cookie MUST come from the same curl call — Jenkins
# ties the crumb to the session; a crumb fetched without -c jar.txt is rejected.
set -e

JENKINS_URL="http://127.0.0.1:8080"
JOB_NAME="Deploy-EC2"
JOB_XML="/tmp/deploy-ec2-job.xml"
COOKIE_JAR="/tmp/jenkins-cookies-$$.txt"

echo "==> Checking if job '${JOB_NAME}' already exists..."
EXIST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  "${JENKINS_URL}/job/${JOB_NAME}/api/json")

if [ "${EXIST_STATUS}" = "200" ]; then
  echo "Job '${JOB_NAME}' already exists — skipping."
  exit 0
fi

echo "==> Fetching crumb + session cookie together..."
CRUMB_JSON=$(curl -s -c "${COOKIE_JAR}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  "${JENKINS_URL}/crumbIssuer/api/json")

echo "Crumb response: ${CRUMB_JSON}"

CRUMB_VALUE=$(echo "${CRUMB_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['crumb'])")

if [ -z "${CRUMB_VALUE}" ]; then
  echo "ERROR: Failed to get crumb — check JENKINS_ADMIN_PASSWORD and Jenkins health."
  exit 1
fi

echo "==> Posting job XML to /createItem..."
HTTP_STATUS=$(curl -s -o /tmp/jenkins-create-out.txt -w "%{http_code}" \
  -b "${COOKIE_JAR}" \
  -u "admin:${JENKINS_ADMIN_PASSWORD}" \
  -H "Jenkins-Crumb: ${CRUMB_VALUE}" \
  -H "Content-Type: application/xml" \
  --data-binary "@${JOB_XML}" \
  "${JENKINS_URL}/createItem?name=${JOB_NAME}")

echo "HTTP status: ${HTTP_STATUS}"

rm -f "${COOKIE_JAR}"

if [ "${HTTP_STATUS}" = "200" ] || [ "${HTTP_STATUS}" = "201" ]; then
  echo "SUCCESS: Job '${JOB_NAME}' created."
  exit 0
fi

# 400 = job already exists (idempotent OK)
if [ "${HTTP_STATUS}" = "400" ]; then
  echo "Job '${JOB_NAME}' already exists (HTTP 400) — OK."
  exit 0
fi

echo "ERROR: Unexpected HTTP ${HTTP_STATUS}"
cat /tmp/jenkins-create-out.txt || true
exit 1
