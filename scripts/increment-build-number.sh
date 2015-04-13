#!/bin/sh
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "This is a pull request. No incrementing will be done."
  exit 0
fi
if [[ "$TRAVIS_BRANCH" != "master" ]]; then
  echo "Testing on a branch other than beta_release. No incrementing will be done."
  exit 0
fi

git config --global user.email "isaac@cloudspace.com"
git config --global user.name "Travis-CI"

git config credential.helper "store --file=.git/credentials"
echo "https://${GH_TOKEN}:@github.com" > .git/credentials

APP_VERSION=$(ruby ./scripts/increment-build-number.rb)
git add "$PLIST_DIR"
git commit -m $APP_VERSION
git push origin beta_release
