#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
# Script fails if trying to access to an undefined variable
set -u

# Required inputs
SOURCE_REPO="${1}"
SOURCE_PATH="${2}"
DESTINATION_PATH="${3}"
COMMIT_MESSAGE="${4}"
CREATE_PR="${5}"
PR_TITLE="${6}"
SOURCE_REPO_TOKEN="${7}"
GITHUB_TOKEN="${8}"

# Clone the source repository
git clone https://x-access-token:${SOURCE_REPO_TOKEN}@github.com/${SOURCE_REPO}.git source-repo

# Create the destination directory if it doesn't exist
mkdir -p ${DESTINATION_PATH}

# Copy files from source to destination
cp -r source-repo/${SOURCE_PATH} ${DESTINATION_PATH}

# Configure git
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"

# Add, commit, and push changes
git add ${DESTINATION_PATH}
git commit -m "${COMMIT_MESSAGE}"
git push

if [ "${CREATE_PR}" == "true" ]; then
  OWNER=$(echo $GITHUB_REPOSITORY | cut -d'/' -f1)
  REPO=$(echo $GITHUB_REPOSITORY | cut -d'/' -f2)
  BASE=$(echo $GITHUB_REF | sed 's|refs/heads/||')
  HEAD="auto-file-copy-$(date +%s)"

  # Create a new branch for the PR
  git checkout -b ${HEAD}
  git push --set-upstream origin ${HEAD}

  # Create the PR
  curl -X POST -H "Authorization: token ${GITHUB_TOKEN}" \
       -d "{\"title\":\"${PR_TITLE}\", \"head\":\"${HEAD}\", \"base\":\"${BASE}\"}" \
       https://api.github.com/repos/${OWNER}/${REPO}/pulls
fi
