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

class TRCValueTransformerDateISO8601: NSObject, TRCValueTransformer {
    
    static let sharedFormatter = NSDateFormatter()
    
    override class func initialize() {
        sharedFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        sharedFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    }
    
    func objectFromResponseValue(responseValue: AnyObject!, error: NSErrorPointer) -> AnyObject! {
        
        let date = TRCValueTransformerDateISO8601.sharedFormatter.dateFromString(responseValue as! String)
        
        if date == nil && error != nil {
            
            error.memory = NSError(domain: "", code: 0, userInfo: [ NSLocalizedDescriptionKey: "Can't create NSDate from string \(responseValue)"])
        }
        
        return date
    }
    
    
    func requestValueFromObject(object: AnyObject!, error: NSErrorPointer) -> AnyObject! {
        
        if object.isKindOfClass(NSDate.classForCoder()) == false {
            
            if error != nil {
                error.memory = NSError(domain: "", code: 0, userInfo: [ NSLocalizedDescriptionKey: "input object is not NSDate"])
            }
            return nil;
        }
        
        let string = TRCValueTransformerDateISO8601.sharedFormatter.stringFromDate(object as! NSDate)
    
        if !string.isEmpty && error != nil {
            error.memory = NSError(domain: "", code: 0, userInfo: [ NSLocalizedDescriptionKey: "Can't convert NSDate into NSString"])
        }
        
        return string
    }
    
  
}