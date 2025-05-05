#!/bin/bash

# Current dotfiles path
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Config global gitignore 
git config --global core.excludesfile "$DIR/global_gitignore"

# Verifies config was correct
git config --global core.excludesfile