#!/bin/sh

rm -rf ~/Library/Developer/Xcode/DerivedData/TyphoonRestClient-*
rm -rf ./build

#Fail immediately if a task fails
set -e
set -o pipefail

xcodebuild test -project TyphoonRestClient.xcodeproj/ -scheme 'TyphoonRestClient' \
-destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' #| xcpretty -c --report junit

# groovy http://frankencover.it/with -d -source-dir TyphoonRestClient -required-coverage 85
