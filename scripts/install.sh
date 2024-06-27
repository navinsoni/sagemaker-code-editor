#!/bin/bash

# set +e to prevent quilt from exiting when no patches popped
set +e

# Set current project root
PROJ_ROOT=$(pwd)

# Clean out patches
printf "\n======== Cleaning out patches ========\n"
quilt pop -a
rm -rf .pc

# empty vscode module
printf "\n======== Delete data is vs code module if present ========\n"
rm -rf ${PROJ_ROOT}/vscode/.

# re-enable -e to allow exiting on error
set -e

# make sure module is current
printf "\n======== Updating submodule ========\n"
git submodule update --init

# Apply patches
printf "\n======== Applying patches ========\n"
{
    quilt push -a --leave-rejects --color=auto 
} || {
        printf "\nPatching error, review logs!\n"
        find ./vscode -name "*.rej"
        exit 1
}


# Generate Licenses
printf "\n======== Generate Licenses ========\n"
cd ${PROJ_ROOT}/vscode
cp LICENSE.txt LICENSE.vscode.txt
cp ThirdPartyNotices.txt LICENSE-THIRD-PARTY.vscode.txt
cp ../LICENSE-THIRD-PARTY .
cd ${PROJ_ROOT}

# Comment out breaking lines in postinstall.js
printf "\n======== Comment out breaking git config lines in postinstall.js ========\n"
sh ${PROJ_ROOT}/scripts/postinstall.sh

# Build tarball for conda feedstock from vscode dir
printf "\n======== Build Tarball for Conda Feedstock ========\n"
bash ${PROJ_ROOT}/scripts/create_code_editor_tarball.sh -v 1.2.0

# Copy resources
printf "\n======== Copy resources ========\n"
sh ${PROJ_ROOT}/scripts/copy-resources.sh

# Delete node_modules to prevent node-gyp build error
printf "\n======== Deleting vscode/node_modules ========\n"
rm -rf "${PROJ_ROOT}/vscode/node_modules"

# Build the project
printf "\n======== Building project in ${PROJ_ROOT}/vscode ========\n"
yarn --cwd "${PROJ_ROOT}/vscode" install --pure-lockfile --verbose
yarn --cwd "${PROJ_ROOT}/vscode" download-builtin-extensions
