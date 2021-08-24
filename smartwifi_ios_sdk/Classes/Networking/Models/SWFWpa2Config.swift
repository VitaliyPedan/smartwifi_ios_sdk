//
//  SWFWpa2Method.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

public struct SWFWpa2Config: Codable {
    
    let wpa2Method: SWFWpa2Method
    
    private enum CodingKeys: String, CodingKey {
        case wpa2Method = "wpa2_method"
    }

}

public struct SWFWpa2Method: Codable {
    let ssid: String
    let password: String
    let ccUrl: String
    
    private enum CodingKeys: String, CodingKey {
        case ssid
        case password
        case ccUrl = "cc_url"
    }

}

