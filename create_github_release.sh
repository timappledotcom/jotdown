#!/bin/bash

# GitHub Release Creation Script for jotDown v0.2.1
# This script creates a GitHub release and uploads the packages

VERSION="0.2.1"
REPO="timappledotcom/jotdown"
RELEASE_DIR="release_packages"

echo "🚀 Creating GitHub Release for jotDown v${VERSION}"
echo "================================================"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

# Create the release
echo "📝 Creating release..."
gh release create "v${VERSION}" \
    --repo "$REPO" \
    --title "jotDown v${VERSION} - Latest Yaru Theme & Enhanced Flat File Storage" \
    --notes-file "RELEASE_v${VERSION}.md" \
    --draft

# Upload packages
echo "📦 Uploading packages..."
if [ -d "$RELEASE_DIR" ]; then
    for file in $RELEASE_DIR/*; do
        if [ -f "$file" ]; then
            echo "⬆️  Uploading $(basename "$file")..."
            gh release upload "v${VERSION}" "$file" --repo "$REPO"
        fi
    done
else
    echo "❌ Release directory not found. Please run build_release.sh first."
    exit 1
fi

echo ""
echo "✅ GitHub release created successfully!"
echo "🌐 View at: https://github.com/$REPO/releases/tag/v${VERSION}"
echo ""
echo "📝 Next steps:"
echo "1. Review the draft release on GitHub"
echo "2. Edit release notes if needed"
echo "3. Publish the release"
