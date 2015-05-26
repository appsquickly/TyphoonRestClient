#!/bin/sh

rm -rf ~/Library/Developer/Xcode/DerivedData/TyphoonRestClient-*

xcodebuild test -workspace TyphoonRestClient.xcworkspace/ -scheme 'Tests' -configuration Debug \
-destination 'platform=iOS Simulator,name=iPhone 5s,OS=8.3' | xcpretty -c --report junit

groovy http://frankencover.it/with -source-dir ./TyphoonRestClient -required-coverage 85
