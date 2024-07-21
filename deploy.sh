#!/bin/sh

# Exit script on any error
set -e

# Build the project
npm run build

# Navigate to the build directory
cd dist

# Initialize a new Git repository
git init
git add -A
git commit -m "deploy (commit: $(git rev-parse --short HEAD))"

# Force push to the gh-pages branch
git push -f https://github.com/gilespi/StoreLocatorApp.git master:gh-pages

# Navigate back to the original directory
cd ..

