#!/bin/sh

#Fail immediately if a task fails
set -e
set -o pipefail

rm -rf ~/Library/Developer/Xcode/DerivedData/TyphoonRestClient-*
rm -fr ./build

xcodebuild test -project TyphoonRestClient.xcodeproj/ -scheme 'TyphoonRestClient' \
-destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' #| xcpretty -c --report junit

# groovy http://frankencover.it/with -d -source-dir TyphoonRestClient -required-coverage 85
