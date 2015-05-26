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


import UIKit

class ViewController: UIViewController {

    var restClient = TyphoonRestClient()
    
    
    func setupRestClient() {
       
        let connection = TRCConnectionAFNetworking(baseUrl: NSURL(string:"http://www.redmine.org"))
        let loggerConnection = TRCConnectionLogger(connection: connection)
        restClient.connection = loggerConnection
        
        restClient.registerObjectMapper(TRCObjectMapperIssue(), forTag: "{issue}")
        restClient.registerValueTransformer(TRCValueTransformerDateISO8601(), forTag: "{date_iso8601}")
    }
    
    func testApi() {
        
        let request = RequestToGetIssue()
        request.issue_id = 1
        
        restClient.sendRequest(request, completion: { (result, error) -> Void in
            println("Result: \(result), Error: \(error)")
        })
    }
    
    override func viewDidLoad() {
        setupRestClient()
        testApi()
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

