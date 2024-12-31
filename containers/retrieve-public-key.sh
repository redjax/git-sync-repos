#!/bin/bash

## Set variable to path where script was launched from
CWD=$(pwd)  # CWD stores the current working directory when the script is launched.

# Change to the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Get the directory where the script is located, not where it was invoked from.
cd "$SCRIPT_DIR" || exit 1  # Change to that directory, exit if it fails.

echo ""
echo "Script will run 'cat $SCRIPT_DIR/ssh/git_mirror_id_rsa.pub' to retrieve the public key generated on the container's first run."
echo "You must manually add this key to any source/target git hosting site (Github, Codeberg, Gitlab, etc) before the container will run successfully."

# Check if the script is being run by a non-root user
if [ "$(whoami)" != "root" ]; then  # Corrected condition for clarity
    echo "Script requires sudo permissions because the container user is root. I'll change this at some point and this script won't be needed."
fi

echo ""

# Check if the file exists, if so, print its contents
sudo test -f "${SCRIPT_DIR}/ssh/git_mirror_id_rsa.pub" \
    && echo "Your git mirror SSH public key:" \
    || { echo "File ${SCRIPT_DIR}/ssh/git_mirror_id_rsa.pub does not exist."; cd "$CWD" && exit 1; }  # Safer exit with cd to original dir

# Show the contents of the SSH public key file
sudo cat "${SCRIPT_DIR}/ssh/git_mirror_id_rsa.pub"

# If the cat command fails, display an error
if [[ $? -ne 0 ]]; then
    echo "[ERROR] Could not show contents of '${SCRIPT_DIR}/ssh/git_mirror_id_rsa.pub'."
    echo "        If you have not run the Docker container, or the ./containers/generate-ssh-keys.sh script,"
    echo "          your SSH keys do not exist yet."

    cd "$CWD"  # Ensure we return to the original directory
    exit 1
fi
