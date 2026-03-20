#!/bin/bash
set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────────
REPO="oronbz/Sitter"
TAP_REPO="oronbz/homebrew-tap"
CASK_FILE="Casks/sitter.rb"
PROJECT="Sitter.xcodeproj"
SCHEME="Sitter"
ARCHIVE_PATH="/tmp/Sitter.xcarchive"
ZIP_PATH="/tmp/Sitter.zip"
TAP_CLONE="/tmp/homebrew-tap-release"

# ─── Helpers ────────────────────────────────────────────────────────────────────
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

die() { red "Error: $*" >&2; exit 1; }

cleanup() {
    rm -rf "$ARCHIVE_PATH" "$ZIP_PATH" "$TAP_CLONE"
}

# ─── Preflight checks ──────────────────────────────────────────────────────────
command -v gh        >/dev/null 2>&1 || die "gh CLI is required (brew install gh)"
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild is required (install Xcode)"
command -v ditto     >/dev/null 2>&1 || die "ditto is required"

[[ -f "$PROJECT/project.pbxproj" ]] || die "Run this script from the project root"

if [[ -n "$(git status --porcelain)" ]]; then
    die "Working tree is not clean. Commit or stash changes first."
fi

# ─── Determine version ──────────────────────────────────────────────────────────
CURRENT_VERSION=$(grep -m1 'MARKETING_VERSION = ' "$PROJECT/project.pbxproj" \
    | sed 's/.*= //; s/;.*//' | tr -d '[:space:]')

if [[ -n "${1:-}" ]]; then
    NEW_VERSION="$1"
else
    bold "Current version: $CURRENT_VERSION"
    printf "New version: "
    read -r NEW_VERSION
fi

[[ -n "$NEW_VERSION" ]] || die "Version cannot be empty"
[[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Version must be semver (e.g. 1.0.0)"
[[ "$NEW_VERSION" != "$CURRENT_VERSION" ]] || die "New version is the same as current ($CURRENT_VERSION)"

bold "Releasing v$NEW_VERSION (current: $CURRENT_VERSION)"
echo

# ─── Step 1: Bump version in source files ───────────────────────────────────────
bold "[1/6] Bumping version to $NEW_VERSION..."

sed -i '' "s/MARKETING_VERSION = $CURRENT_VERSION;/MARKETING_VERSION = $NEW_VERSION;/g" \
    "$PROJECT/project.pbxproj"

green "  Version bumped in source files"

# ─── Step 2: Commit and push ───────────────────────────────────────────────────
bold "[2/6] Committing and pushing..."

git add -A
git commit -m "Bump version to $NEW_VERSION"
git push

green "  Pushed to origin/main"

# ─── Step 3: Build Release archive ─────────────────────────────────────────────
bold "[3/6] Building Release archive..."

cleanup

xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    -quiet \
    || die "Archive build failed"

green "  Archive built"

# ─── Step 4: Zip and compute sha256 ────────────────────────────────────────────
bold "[4/6] Creating zip..."

ditto -c -k --sequesterRsrc --keepParent \
    "$ARCHIVE_PATH/Products/Applications/Sitter.app" \
    "$ZIP_PATH"

SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')

green "  Zip created (sha256: $SHA256)"

# ─── Step 5: Create GitHub release ─────────────────────────────────────────────
bold "[5/6] Creating GitHub release v$NEW_VERSION..."

gh release create "v$NEW_VERSION" "$ZIP_PATH" \
    --repo "$REPO" \
    --title "Sitter v$NEW_VERSION" \
    --generate-notes

RELEASE_URL="https://github.com/$REPO/releases/tag/v$NEW_VERSION"
green "  Release created: $RELEASE_URL"

# ─── Step 6: Update Homebrew tap ───────────────────────────────────────────────
bold "[6/6] Updating Homebrew tap..."

git clone --depth 1 "git@github.com:$TAP_REPO.git" "$TAP_CLONE" 2>/dev/null

CASK="$TAP_CLONE/$CASK_FILE"
[[ -f "$CASK" ]] || die "Cask file not found at $CASK"

OLD_CASK_VERSION=$(grep -m1 'version "' "$CASK" | sed 's/.*version "//; s/".*//')

sed -i '' "s/version \"$OLD_CASK_VERSION\"/version \"$NEW_VERSION\"/" "$CASK"

OLD_SHA=$(grep -m1 'sha256 "' "$CASK" | sed 's/.*sha256 "//; s/".*//')
sed -i '' "s/sha256 \"$OLD_SHA\"/sha256 \"$SHA256\"/" "$CASK"

(
    cd "$TAP_CLONE"
    git add -A
    git commit -m "Update sitter to $NEW_VERSION"
    git push
)

green "  Homebrew tap updated"

# ─── Done ───────────────────────────────────────────────────────────────────────
cleanup

echo
green "========================================="
green "  Released Sitter v$NEW_VERSION"
green "========================================="
echo
echo "  GitHub:   $RELEASE_URL"
echo "  Homebrew: brew update && brew upgrade --cask sitter"
echo
