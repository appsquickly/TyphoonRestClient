////////////////////////////////////////////////////////////////////////////////
//
//  APPS QUICKLY
//  Copyright 2015 Apps Quickly Pty Ltd
//  All Rights Reserved.
//
//  NOTICE: Prepared by AppsQuick.ly on behalf of Apps Quickly. This software
//  is proprietary information. Unauthorized use is prohibited.
//
////////////////////////////////////////////////////////////////////////////////


import Foundation

class Issue {
    var identifier = 0
    var projectName: String? = ""
    var authorName: String? = ""
    var statusText: String? = ""
    
    var subject = ""
    var descriptionText = ""
    
    var created: NSDate?
    var updated: NSDate?
    
    var doneRatio = 0.0
}