//
//  SWFWiFiConfig.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

public struct SWFWiFiConfig<Config: Codable>: Codable {
    
    let uid: String
    let traceId: String
    let wifiConfigs: [String: Config]
    
    var wifiConfig: Config? {
        wifiConfigs["0"]
    }
    
    private enum CodingKeys: String, CodingKey {
        case uid
        case traceId = "trace_id"
        case wifiConfigs = "wifi_configs"
    }

}
