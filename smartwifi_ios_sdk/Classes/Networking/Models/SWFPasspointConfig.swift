//
//  SWFPasspointMethod.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

public struct SWFPasspointConfig: SWFConfigPriorityProtocol, SWFConfigTypeProtocol, Codable {
    
    let passpointMethod: SWFPasspointMethod
    public var priority: Int = -1
    
    public var type: SWFConfigType {
        .passpoint
    }
    
    private enum CodingKeys: String, CodingKey {
        case passpointMethod = "passpoint_method"
    }

}

public struct SWFPasspointMethod: Codable {
    let username: String
    let password: String
    let fqdn: String
    let eapType: String
    let nonEapInnerMethod: String
    let friendlyName: String
    let realm: String
    let caCertificate: String
    
    private enum CodingKeys: String, CodingKey {
        case username
        case password
        case fqdn
        case eapType
        case nonEapInnerMethod
        case friendlyName
        case realm
        case caCertificate
    }

}
