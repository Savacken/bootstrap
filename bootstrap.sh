#!/usr/bin/env bash

set -e

# Make sure OS is supported by this script
OS=$(uname -s)
case $OS in
Darwin)
  export LINUX=0 MACOS=1 UNIX=1
  if [[ $(uname -m) == "arm64" ]]; then
    # DEFAULT_HOMEBREW_PREFIX="/opt/homebrew"
    export ARM64=1
  else
    # DEFAULT_HOMEBREW_PREFIX="/usr/local"
    export ARM64=0
  fi
  ;;
  *) echo "$OS is not a supported operating system" && exit 1 ;;
esac

# Does user have admin privledges
STRAP_ADMIN=${STRAP_ADMIN:-0}
if groups | grep -qE "\b(admin)\b"; then STRAP_ADMIN=1; else STRAP_ADMIN=0; fi
export STRAP_ADMIN

# Variables to be used for configuring Git
# STRAP_GIT_NAME=${STRAP_GIT_NAME:?Variable not set}
# STRAP_GIT_EMAIL=${STRAP_GIT_EMAIL:?Variable not set}
# Variables to be used for getting dotfiles
STRAP_GITHUB_USER=${STRAP_GITHUB_USER:="Savacken"}
DEFAULT_DOTFILES_URL="https://github.com/$STRAP_GITHUB_USER/.dotfiles"
STRAP_DOTFILES_URL=${STRAP_DOTFILES_URL:="$DEFAULT_DOTFILES_URL"}
STRAP_DOTFILES_BRANCH=${STRAP_DOTFILES_BRANCH:="main"}

# exit bootstrapping due to an issue
abort() {
  STRAP_STEP=""
  echo "!!! $*" >&2
  exit 1
}

# skip a step
logskip() {
  STRAP_STEP=""
  echo "SKIPPED"
  echo "$*"
}

[ "$USER" = "root" ] && abort "Run bootstrap.sh as yourself, not root."

PROMPT="This script will install or update;
  * Homebrew
  * XCode Command Line Tools
  * Github CLI
This will require your admin password. Reply 'y' to continue: "
# PROMPT="$PROMPT\n  * Github CLI (required to access dotfiles)"
read -p "$PROMPT" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # install Homebrew, includes XCode Command Line Tools
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # and add to PATH
  if ! grep -F 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile; then
    echo "Adding brew toPATH"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  if ! command -v gh &> /dev/null; then
    brew install gh
    gh auth login
  fi
  cd $HOME
  if ! [ -d ~/.dotfiles ]; then
    echo "Installing dotfiles"
    gh repo clone .dotfiles
  else
    cd ~/.dotfiles
    git pull
  fi
  ./.dotfiles/install
fi
