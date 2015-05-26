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

class RequestToGetIssue: NSObject, TRCRequest {
    
    var issue_id = 0
    
    func method() -> String! {
        return TRCRequestMethodGet
    }
    
    func path() -> String! {
        return "issues/{issue_id}.json"
    }
    
    func pathParameters() -> [NSObject : AnyObject]! {
        return ["issue_id": issue_id]
    }
    
    func responseProcessedFromBody(bodyObject: AnyObject!, headers responseHeaders: [NSObject : AnyObject]!, status statusCode: TRCHttpStatusCode, error parseError: NSErrorPointer) -> AnyObject! {
        return bodyObject["issue"]
    }
    
}