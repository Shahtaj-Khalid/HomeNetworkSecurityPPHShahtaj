//
//  SNMPController.swift
//  ShahtajNetSecTest
//
//  Created by Shahtaj Khalid on 8/3/18.
//  Copyright © 2018 Shahtaj Khalid. All rights reserved.
//

import Foundation

class SNMPController {
    private var snmp: XISMobile_SNMP_PP?

// Import the Mobile SNMP++ header file(s)

    class func sharedController() -> SNMPController {
    var sharedController: SNMPController? = nil
      var onceToken: Int?  = nil
    if (onceToken == 0) {
        /* TODO: move below code to a static variable initializer (dispatch_once is deprecated) */
        sharedController = SNMPController()
    }
    onceToken = 1
    return sharedController ?? SNMPController()
    }

    init() {
    
    snmp = XISMobile_SNMP_PP()
    
    }

    deinit {
    snmp = nil
    }
    
    func sysDescription(_ sysDescrValue: String?, forHost host: String) throws ->  String {
        
     
    var sysDescrValue = sysDescrValue
    var queryError: Error? = nil
    // Let's assume we are querying the standard UDP port for SNMP
    let port = 161//32150
    // We also assume, for this example, SNMP v2c
    let snmpVersion: Int = 2
    // For the readonly community we also use the 'default': public
    let community = "public"
    // Get the result(s) from the SNMP query in a NSDictionary
    
    var decAgentRes = [Any]()
    var result = [AnyHashable: Any]()
     var result101 = [AnyHashable: Any]()
        
        
        result = (try! snmp?.getOid("1.3.6.1.2.1.1.1.0", address: host, snmpVersion: uint(snmpVersion), remotePort: port as NSNumber, withCommunity: community, retry: 1, timeout: 300))!
        print("result for getOid = \(result)")
        
        if queryError == nil && result.count > 0 {
        // Seems we got result, proces it and return it through sysDescrValue
      
        var data = Dictionary<AnyHashable,Any>()
        for (key, obj) in result {
            data[key] =  "\(key), \(obj)"
             print("dataDictionary[key] = ",key,"OBJ = ",obj)
            sysDescrValue = obj as? String
        }
        
        return sysDescrValue!
    }
    else {
        print("queryError = ",queryError)
        
        return sysDescrValue!
    }
}
}
