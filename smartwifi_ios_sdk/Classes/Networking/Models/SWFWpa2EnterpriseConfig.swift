//
//  SWFWpa2EnterpriseMethod .swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

public struct SWFWpa2EnterpriseConfig: SWFConfigPriority, Codable {
    
    let wpa2EnterpriseMethod: SWFWpa2EnterpriseMethod
    public var priority: Int = -1
    
    private enum CodingKeys: String, CodingKey {
        case wpa2EnterpriseMethod = "wpa2_enterprise_eap_ttls_method"
    }

}


public struct SWFWpa2EnterpriseMethod: Codable {
    let ssid: String
    let password: String
    let identity: String
    let caCertificate: String
    
    private enum CodingKeys: String, CodingKey {
        case ssid
        case password
        case identity
        case caCertificate
    }

}
