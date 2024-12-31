#!/bin/bash

## Set this as the Dockerfile's ENTRYPOINT

if ! command -v ssh-keygen &> /dev/null; then
    echo "[ERROR] SSH does not seem to be installed, ssh-keygen command failed. Exiting."
    cd $CWD

    exit 1
else
    echo "SSH installed, continuing."
fi

USR=${CONTAINER_USER:-root}
if [[ "$USR" == "root" ]]; then
    HOMEPATH="/root"
else
    HOMEPATH="/home/${USR}"
fi

echo ""
echo " [ Git Mirror Sync Container Entrypoint Script ] "
echo " ----------------------------------------------- "
echo " [ Container User: ${USR} | Container Home Path: ${HOMEPATH} ]"
echo ""

if [[ ! -d "${HOMEPATH}/.ssh" ]]; then
    echo "Creating path '${HOMEPATH}/.ssh'"
    mkdir "${HOMEPATH}/.ssh"
fi
echo "Set chmod 700 on ${HOMEPATH}/.ssh"
chmod 700 "${HOMEPATH}/.ssh"

if [[ ! -f "${HOMEPATH}/.ssh/config" ]]; then
    echo "Creat ${HOMEPATH}/.ssh/config file"

    cat <<EOF > "${SCRIPT_DIR}/ssh/config"
#######################################################
# SSH config for Docker container                     #
#                                                     #
# This configuration will not be used on the host OS. #
# This file was generated by the generate-ssh-keys.sh #
# script. Feel free to make changes to it, but keep it#
# in the .gitignore.                                  #
#######################################################

Host github.com
  User git
  IdentityFile ~/.ssh/git_mirror_id_rsa
  StrictHostKeyChecking no

Host codeberg.org
  User git
  IdentityFile ~/.ssh/git_mirror_id_rsa
  StrictHostKeyChecking no

Host gitlab.com
  User git
  IdentityFile ~/.ssh/git_mirror_id_rsa
  StrictHostKeyChecking no
EOF
fi
echo "Set chmod 600 on ${HOMEPATH}/.ssh/config"
chmod 600 "${HOMEPATH}/.ssh/config"

if [[ ! -f "${HOMEPATH}/.ssh/git_mirror_id_rsa" ]]; then
    echo "${HOMEPATH}/.ssh/git_mirror_id_rsa does not exist. Generating SSH keys."

    ssh-keygen -t rsa -b 4096 -f "${HOMEPATH}./ssh/git_mirror_id_rsa" -N ""
fi
echo "Set chmod 600 on private key '${HOMEPATH}/.ssh/git_mirror_id_rsa'"
chmod 600 "${HOMEPATH}/.ssh/git_mirror_id_rsa"

echo "Set chmod 644 on ${HOMEPATH}/.ssh/git_mirror_id_rsa"
chmod 644 "${HOMEPATH}/.ssh/git_mirror_id_rsa.pub"

chown -R $USR:$USR "${HOMEPATH}/.ssh"

echo ""
echo " [ Docker Entrypoint ${HOMEPATH}/.ssh permissions ]"
echo " --------------------------------------------------"
ls -l "${HOMEPATH}/.ssh"

if [[ $? -ne 0 ]]; then
    echo "[ERROR] An error occurred during Docker entrypoint startup."
    exit $?
else
    ## Continue with Docker command execution
    exec "$@"
fi