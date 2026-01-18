#!/bin/bash
set -e

# Copy scripts to ~/.claude/bin
mkdir -p ~/.claude/bin
cp bin/*.sh ~/.claude/bin/
chmod +x ~/.claude/bin/*.sh

# Add to PATH if not already
if ! grep -q "~/.claude/bin" ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.claude/bin:$PATH"' >> ~/.bashrc
fi

echo "Installed to ~/.claude/bin/"
echo "Please run: source ~/.bashrc"
