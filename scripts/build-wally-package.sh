#!/bin/sh

set -e

rm -rf roblox

mkdir -p roblox

cp -r src roblox/src

./scripts/remove-tests.sh roblox

wally_package=build/wally
rm -rf $wally_package

echo Process package

mkdir -p $wally_package
cp LICENSE.txt $wally_package/LICENSE.txt

node ./scripts/npm-to-wally.js package.json $wally_package/wally.toml roblox/wally-package.project.json

cp .darklua-wally.json roblox
cp -r node_modules/.luau-aliases/* roblox

rojo sourcemap roblox/wally-package.project.json --output roblox/sourcemap.json

darklua process --config roblox/.darklua-wally.json roblox/src $wally_package/src

cp default.project.json $wally_package
wally package --project-path $wally_package --list
