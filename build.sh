#!/bin/sh

xcodebuild test -workspace TyphoonRestClient.xcworkspace/ -scheme 'TyphoonRestClient' -configuration Debug \
-destination 'platform=iOS Simulator,name=iPhone 5s,OS=8.2' | xcpretty -c --report junit

groovy http://frankencover.it/with -source-dir ./TyphoonRestClient -required-coverage 85
