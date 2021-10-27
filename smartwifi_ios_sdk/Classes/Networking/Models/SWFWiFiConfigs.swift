//
//  SWFWiFiConfigs.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

public protocol SWFConfigPriorityProtocol {
    var priority: Int { get set }
}

public enum SWFConfigType {
    case passpoint
    case wpa2Enterprise
    case wpa2
}

public protocol SWFConfigTypeProtocol {
    var type: SWFConfigType { get }
}

public struct SWFWiFiConfigs: Codable {
    
    let uid: String
    let traceId: String
    
    var passpointConfig: SWFPasspointConfig?
    var wpa2EnterpriseConfig: SWFWpa2EnterpriseConfig?
    var wpa2Config: SWFWpa2Config?

    private enum WifiConfigsProirityKeys: String, CodingKey {
        case first = "0"
        case second = "1"
        case third = "2"
    }

    private enum TopLevelKeys: String, CodingKey {
        case uid
        case traceId = "trace_id"
        case wifiConfigs = "wifi_configs"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TopLevelKeys.self)
        
        uid = try container.decode(String.self, forKey: .uid)
        traceId = try container.decode(String.self, forKey: .traceId)
       
        let wifiConfigs = try container.nestedContainer(keyedBy: WifiConfigsProirityKeys.self, forKey: .wifiConfigs)

        passpointConfig = try? wifiConfigs.decodeIfPresent(SWFPasspointConfig.self, forKey: .first)
        passpointConfig?.priority = 0
        if passpointConfig == nil {
            passpointConfig = try? wifiConfigs.decodeIfPresent(SWFPasspointConfig.self, forKey: .second)
            passpointConfig?.priority = 1
        }
        if passpointConfig == nil {
            passpointConfig = try? wifiConfigs.decodeIfPresent(SWFPasspointConfig.self, forKey: .third)
            passpointConfig?.priority = 2
        }
        
        wpa2EnterpriseConfig = try? wifiConfigs.decodeIfPresent(SWFWpa2EnterpriseConfig.self, forKey: .first)
        wpa2EnterpriseConfig?.priority = 0
        if wpa2EnterpriseConfig == nil {
            wpa2EnterpriseConfig = try? wifiConfigs.decodeIfPresent(SWFWpa2EnterpriseConfig.self, forKey: .second)
            wpa2EnterpriseConfig?.priority = 1
        }
        if wpa2EnterpriseConfig == nil {
            wpa2EnterpriseConfig = try? wifiConfigs.decodeIfPresent(SWFWpa2EnterpriseConfig.self, forKey: .third)
            wpa2EnterpriseConfig?.priority = 2
        }
        
        wpa2Config = try? wifiConfigs.decodeIfPresent(SWFWpa2Config.self, forKey: .first)
        wpa2Config?.priority = 0
        if wpa2Config == nil {
            wpa2Config = try? wifiConfigs.decodeIfPresent(SWFWpa2Config.self, forKey: .second)
            wpa2Config?.priority = 1
        }
        if wpa2Config == nil {
            wpa2Config = try? wifiConfigs.decodeIfPresent(SWFWpa2Config.self, forKey: .third)
            wpa2Config?.priority = 2
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: TopLevelKeys.self)
        try container.encode(self.uid, forKey: .uid)
        try container.encode(self.traceId, forKey: .traceId)

        var wifiConfigs = container.nestedContainer(keyedBy: WifiConfigsProirityKeys.self, forKey: .wifiConfigs)

        if self.passpointConfig?.priority == 0 {
            try wifiConfigs.encodeIfPresent(self.passpointConfig, forKey: .first)
        } else if self.passpointConfig?.priority == 1 {
            try wifiConfigs.encodeIfPresent(self.passpointConfig, forKey: .second)
        } else if self.passpointConfig?.priority == 2 {
            try wifiConfigs.encodeIfPresent(self.passpointConfig, forKey: .third)
        }
        
        if self.wpa2EnterpriseConfig?.priority == 0 {
            try wifiConfigs.encodeIfPresent(self.wpa2EnterpriseConfig, forKey: .first)
        } else if self.wpa2EnterpriseConfig?.priority == 1 {
            try wifiConfigs.encodeIfPresent(self.wpa2EnterpriseConfig, forKey: .second)
        } else if self.wpa2EnterpriseConfig?.priority == 2 {
            try wifiConfigs.encodeIfPresent(self.wpa2EnterpriseConfig, forKey: .third)
        }

        if self.wpa2Config?.priority == 0 {
            try wifiConfigs.encodeIfPresent(self.wpa2Config, forKey: .first)
        } else if self.wpa2Config?.priority == 1 {
            try wifiConfigs.encodeIfPresent(self.wpa2Config, forKey: .second)
        } else if self.wpa2Config?.priority == 2 {
            try wifiConfigs.encodeIfPresent(self.wpa2Config, forKey: .third)
        }
    }

}
