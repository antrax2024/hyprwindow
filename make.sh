#!/usr/bin/env bash

echo "Cleaning up"
rm -rf build/*
rm -rf dist/*

echo "Committing and pushing changes"
git commit -a
git push

echo "Creating a new release on GitHub"
EXECUTABLE="hyprwindow"
BINARY_PATH="$(pwd)/dist/$EXECUTABLE"
REPO="antrax2024/$EXECUTABLE"
TAG="v$(python3 -c "import hyprwindow; print(hyprwindow.VERSION)")"
RELEASE_NAME="$TAG"

echo "Building $EXECUTABLE..."
pyinstaller --onefile \
    --clean \
    --workpath=build \
    --specpath=build \
    --log-level FATAL \
    $EXECUTABLE.py

echo "Copying $EXECUTABLE to $HOME/dotfiles/bin/"
cp dist/$EXECUTABLE $HOME/dotfiles/bin/

echo "Creating release $RELEASE_NAME for $REPO"
response=$(
    curl -s -X POST https://api.github.com/repos/$REPO/releases \
        -H "Authorization: token $GITHUB_TOKEN" \
        -d @- <<EOF
{
  "tag_name": "$TAG",
  "target_commitish": "main",
  "name": "$RELEASE_NAME",
  "body": "Automated release from script",
  "draft": false,
  "prerelease": false
}
EOF
)

echo "Extract the upload URL from the response"
upload_url=$(echo $response | jq -r .upload_url | sed -e "s/{?name,label}//")

echo "Uploading $BINARY_PATH to $upload_url"
curl -s -X POST "$upload_url?name=$(basename $EXECUTABLE)" \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/octet-stream" \
    --data-binary "@$BINARY_PATH"
