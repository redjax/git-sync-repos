##!/bin/bash

## Set variable to path where script was launched from
CWD=$(pwd)

# Change to the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR || exit 1

## Set working directory for mirrors
MIRROR_DIR="${SCRIPT_DIR}/repositories"
## File containing source and target repository pairs
REPOS_FILE="${SCRIPT_DIR}/mirrors"

## Flip to 1 when GNU parallel is installed
RUN_CONCURRENTLY=0

## Function to ensure git URL ends with .git
ensure_git_suffix() {
  local repo_url="$1"
  if [[ "$repo_url" != *.git ]]; then
    repo_url="${repo_url}.git"
  fi
  echo "$repo_url"
}

## Function to clone a repository if it doesn't exist
clone_repo() {
  local repo_url="$1"
  local repo_name=$(basename "$repo_url" .git)

  ## Clone if the repository does not exist
  if [[ ! -d "$MIRROR_DIR/$repo_name" ]]; then
    echo "Cloning repository $repo_url into $MIRROR_DIR/$repo_name"
    git clone --mirror "$repo_url" "$MIRROR_DIR/$repo_name"
  else
    echo "Repository $repo_name already exists. Skipping clone."
  fi
}

## Function to mirror repositories between source and target
push_new_remote() {
  local src_repo="$1"
  local target_repo="$2"
  local repo_name=$(basename "$src_repo" .git)

  echo "Mirroring from $src_repo to $target_repo"

  cd "$MIRROR_DIR/$repo_name"

  ## Ensure the remote target URL is set
  git remote set-url --push origin "$target_repo"
  
  ## Push to target
  git push --mirror
}

mirror() {
  ## Read each line in the file
  while IFS=" " read -r src_repo target_repo; do
    ## Skip empty lines and lines starting with '##'
    if [[ -z "$src_repo" || -z "$target_repo" || "$src_repo" == \##* ]]; then
      continue
    fi

    ## Ensure the URLs end with .git
    src_repo=$(ensure_git_suffix "$src_repo")
    target_repo=$(ensure_git_suffix "$target_repo")

    ## Clone repository if not done yet
    clone_repo "$src_repo"

    ## Push the repository to target
    push_new_remote "$src_repo" "$target_repo"
  done < "$REPOS_FILE"
}

async_mirror() {
  export -f ensure_git_suffix
  export -f clone_repo
  export -f push_new_remote

  cat "$REPOS_FILE" | parallel -j 0 'src_repo=$(echo {} | cut -d " " -f1); target_repo=$(echo {} | cut -d " " -f2); src_repo=$(ensure_git_suffix "$src_repo"); target_repo=$(ensure_git_suffix "$target_repo"); clone_repo "$src_repo"; push_new_remote "$src_repo" "$target_repo"'
}

## Main function
main() {
  if [[ ! -f "$REPOS_FILE" ]]; then
    echo "[ERROR] Repository file not found: $REPOS_FILE"
    exit 1
  fi

  if ! command -v parallel --version > /dev/null 2>&1; then
    echo "[WARNING] GNU parallel is not installed. Operations will be run synchronously."
    echo "          Install GNU parallel to run operations concurrently, resulting in"
    echo "          faster execution."

    mirror
  else
    echo "[INFO] GNU parallel detected. Git operations will be performed concurrently."
    async_mirror
  fi

  if [[ $? -ne 0 ]]; then
    echo "[WARNING] Mirror command returned a non-zero exit code: $?"
  fi
}

## Run main function
main

