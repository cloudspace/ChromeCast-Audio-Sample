#!/bin/sh
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "This is a pull request. No incrementing will be done."
  exit 0
fi
if [[ "$TRAVIS_BRANCH" != "acceptance" ]]; then
  echo "Testing on a branch other than master. No incrementing will be done."
  exit 0
fi

ruby ./scripts/increment-build-number.rb
git add "$PLIST_DIR"
git commit -m "Version Number Here"
git push
