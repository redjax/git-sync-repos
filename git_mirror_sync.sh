##!/bin/bash

## Uncomment while debugging to show traces
# set -x

## Set variable to path where script was launched from
CWD=$(pwd)

# Change to the directory where the script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
cd $SCRIPT_DIR || exit 1

## Set working directory for mirrors
MIRROR_DIR="${GIT_SYNC_MIRROR_DIR:-$SCRIPT_DIR}/repositories"
## File containing source and target repository pairs
REPOS_FILE="${SCRIPT_DIR}/mirrors"

## Flip to 1 when GNU parallel is installed
RUN_CONCURRENTLY=0

function get_ts() {
  ## Return a formatted timestamp.
  #  Format: $1 or %Y-%m-%d %H:%M:%S
  fmt="${1:-%Y-%m-%d %H:%M:%S}"

  date "+${fmt}"
}

echo "$(cat <<EOF

[$(get_ts)] [ DEBUG Script Variables ]
\$CWD=${CWD}
\$SCRIPT_DIR=${SCRIPT_DIR}
\$MIRROR_DIR=${MIRROR_DIR}
\$REPOS_FILE=${REPOS_FILE}
 
EOF
)"

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
    echo "[$(get_ts)] Cloning repository $repo_url into $MIRROR_DIR/$repo_name"
    git clone --mirror "$repo_url" "$MIRROR_DIR/$repo_name"
  else
    echo "[$(get_ts)] Repository $repo_name already exists. Skipping clone & pulling changes."
    
    cd "$MIRROR_DIR/$repo_name"
    if [[ $? -ne 0 ]]; then
      echo "[$(get_ts)] [ERROR] Could not change path to '$MIRROR_DIR/$repo_name'."
    else
      echo "[$(get_ts)] Pulling changes in fast-forward mode."
      git pull --ff

      if [[ $? -ne 0 ]]; then
        echo "[$(get_ts)] [ERROR] Unable to pull changes for '$MIRROR_DIR/$repo_name'"
      fi
    fi
  fi

  cd $CWD
}

## Function to mirror repositories between source and target
push_new_remote() {
  local src_repo="$1"
  local target_repo="$2"
  local repo_name=$(basename "$src_repo" .git)

  echo "[$(get_ts)] Mirroring from $src_repo to $target_repo"

  cd "$MIRROR_DIR/$repo_name"

  # ## Ensure the remote target URL is set
  # git remote set-url --push origin "$target_repo"
  
  # ## Push to target
  # git push --mirror

  ## Change to the repository directory
  if cd "$MIRROR_DIR/$repo_name"; then
    ## Ensure the remote target URL is set for this specific repo
    git remote set-url --push origin "$target_repo"

    ## Push to the target repository
    git push --mirror

    ## Return to the script directory
    cd - > /dev/null
  else
    echo "[$(get_ts)] [ERROR] Failed to change to repository directory: $MIRROR_DIR/$repo_name"
    return 1
  fi
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
  ## Export functions to parallel session
  export -f ensure_git_suffix
  export -f clone_repo
  export -f push_new_remote
  export -f get_ts
  ## Export environment variables to parallel session
  export CWD
  export SCRIPT_DIR
  export MIRROR_DIR
  export REPOS_FILE

  cat "$REPOS_FILE" | parallel -j 0 'src_repo=$(echo {} | cut -d " " -f1); target_repo=$(echo {} | cut -d " " -f2); src_repo=$(ensure_git_suffix "$src_repo"); target_repo=$(ensure_git_suffix "$target_repo"); clone_repo "$src_repo"; push_new_remote "$src_repo" "$target_repo"'
}

## Main function
main() {
  if [[ ! -f "$REPOS_FILE" ]]; then
    echo "[$(get_ts)] [ERROR] Repository file not found: $REPOS_FILE"
    exit 1
  fi

  if ! command -v parallel --version &> /dev/null; then
    echo "[$(get_ts)] [WARNING] GNU parallel is not installed. Operations will be run synchronously."
    echo "          Install GNU parallel to run operations concurrently, resulting in"
    echo "          faster execution."

    mirror
  else
    echo "[$(get_ts)] [INFO] GNU parallel detected. Git operations will be performed concurrently."
    async_mirror
  fi

  if [[ $? -ne 0 ]]; then
    echo "[$(get_ts)] [WARNING] Mirror command returned a non-zero exit code: $?"
  fi
}

## Run main function
main

