#!/bin/sh

pod update

#Fail immediately if a task fails
set -e
set -o pipefail

rm -rf ~/Library/Developer/Xcode/DerivedData/TyphoonRestClient-*
rm -fr ./build

xcodebuild test -workspace TyphoonRestClient.xcworkspace/ -scheme 'TyphoonRestClient' \
-destination 'platform=iOS Simulator,name=iPhone 5s,OS=8.3' | xcpretty -c --report junit

groovy http://frankencover.it/with -source-dir TyphoonRestClient -required-coverage 85
