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

class TRCObjectMapperIssue: NSObject, TRCObjectMapper {
    
    func objectFromResponseObject(responseObject: AnyObject!, error: NSErrorPointer) -> AnyObject! {
        
        let responseDictionary = responseObject as! NSDictionary
        
        var issue = Issue()
        issue.identifier = responseDictionary["id"] as! Int
        issue.projectName = responseDictionary.valueForKeyPath("project.name") as? String
        issue.authorName = responseDictionary.valueForKeyPath("author.name") as? String
        issue.statusText = responseDictionary.valueForKeyPath("status.name") as? String
        issue.subject = responseDictionary["subject"] as! String
        issue.descriptionText = responseDictionary["description"] as! String
        issue.updated = responseDictionary["created_on"] as? NSDate
        issue.created = responseDictionary["updated_on"] as? NSDate
        issue.doneRatio = responseDictionary["done_ratio"] as! Double
        
        return issue
        
    }
}