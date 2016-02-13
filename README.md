# TyphoonRestClient

TyphoonRestClient is flexible HTTP client for integration against contract-first web service.
It provides facilities for customisable serialisation / marshalling, validation and stubbing requests.

TRC helps to quickly achieve end-to-end proof of concept, at the same time as providing a robust platform for deploying into demanding production environments.

# Features

* Response and request body validation, using schema file.
* Automatically transforms basic types such a date into model object (NSDate)
* Automatic marshalling of model objects
* Common solution for server errors handling
* User able to apply common rules to any NSURLRequest created by TRC.
* User has control over sending of each NSURLRequest.
* Easy to stub any network call
* Has extendable architecture


# How to use

* [Quick Start](https://github.com/appsquickly/TyphoonRestClient/wiki/Quick-Start)
* [Frequently Asked Questions](https://github.com/appsquickly/TyphoonRestClient/wiki/Frequently-Asked-Questions)
* [API Docs](http://appsquickly.github.io/TyphoonRestClient/docs/latest/api/)

# Installation


## CocoaPods

Preferred way is using CocoaPods:

```
pod 'TyphoonRestClient'
```

## From Sources

1. Drag `TyphoonRestClient` folder into your project
2. Install `AFNetworking` with your prefered way


# Sponsors

TyphoonRestClient was developed by AppsQuick.ly with kind sponsorship from <a href="http://www.codemonastery.com.au/">Code Monastery</a>. 
