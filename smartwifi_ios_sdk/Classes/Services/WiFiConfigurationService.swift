//
//  WiFiConfigurationService.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import NetworkExtension
import SystemConfiguration.CaptiveNetwork

enum WiFiDisconnectResult {
    case success
    case failure(WiFiDisconnectError)
}

enum WiFiDisconnectError: Error {
    case notConnected
}

protocol WiFiConfigurationService {
    
    typealias SSID = String
    
    func connect(
        ssid: SSID,
        password: String,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    )

    func connect(
        ssid: SSID,
        hotspotSettings: HotspotSettings,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    )

    func connect(
        domainName: String,
        hotspotSettings: HotspotSettings,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    )
    
    func disconnect(ssid: SSID, _ completion: @escaping (WiFiDisconnectResult) -> Void)
    func disconnect(domainName: String, _ completion: @escaping (WiFiDisconnectResult) -> Void)
    func removeConnections()
}

final class WiFiConfigurationServiceImpl: WiFiConfigurationService {
    
    private func apply(
        _ hotspotConfig: NEHotspotConfiguration,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    ) {
//        NEHotspotConfigurationManager.shared.getConfiguredSSIDs { (wifiList) in
//            wifiList.forEach { NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: $0) }
//            // ... from here you can use your usual approach to autoconnect to your network
//        }
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { (error) in
            
            if let error = error {
                return applyResult(.failure(error))
                
            } else {
                
                DispatchQueue.global(
                    qos: .utility
                ).asyncAfter(
                    deadline: .now() + 5
                ) {
                    if #available(iOS 14.0, *) {
                        NEHotspotNetwork.fetchCurrent { network in
                            if network?.ssid == hotspotConfig.ssid {
                                return connectionResult(.success)
                            } else {
                                let error = SWFAPIError.unableToJoinNetwork(domain: "wifi connetion")
                                return connectionResult(.failure(error))
                            }
                        }
                    } else {
                        let networkSsid = self.currentWifiInfo()
                        if networkSsid == hotspotConfig.ssid {
                            return connectionResult(.success)
                        } else {
                            let error = SWFAPIError.unableToJoinNetwork(domain: "wifi connetion")
                            return connectionResult(.failure(error))
                        }
                    }
                }
                
                return applyResult(.success)
            }
        }
    }

    private func currentWifiInfo() -> String? {
        
        guard let interface = CNCopySupportedInterfaces() else {
            return nil
        }
        
        for i in 0..<CFArrayGetCount(interface) {
            let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interface, i)
            let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
            if let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString),
                let interfaceData = unsafeInterfaceData as? [String : AnyObject]
            {
                // connected wifi
//                print("BSSID: \(interfaceData["BSSID"]), SSID: \(interfaceData["SSID"]), SSIDDATA: \(interfaceData["SSIDDATA"])")
                return interfaceData["SSID"] as? String
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    func connect(
        ssid: SSID,
        password: String,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    ) {
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        apply(hotspotConfig, applyResult: applyResult, connectionResult: connectionResult)
    }
    
    func connect(
        ssid: SSID,
        hotspotSettings: HotspotSettings,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    ) {
        let eapSettings = hotspotSettings.hotspotEAPSettings()
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, eapSettings: eapSettings)
        apply(hotspotConfig, applyResult: applyResult, connectionResult: connectionResult)
    }
    
    func connect(
        domainName: String,
        hotspotSettings: HotspotSettings,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    ) {
        let hs20Settings = NEHotspotHS20Settings(domainName: domainName, roamingEnabled: false)
        hs20Settings.naiRealmNames = [domainName]
        
        let eapSettings = hotspotSettings.hotspotEAPSettings()
        let hotspotConfig = NEHotspotConfiguration(hs20Settings: hs20Settings, eapSettings: eapSettings)
        apply(hotspotConfig, applyResult: applyResult, connectionResult: connectionResult)
    }

    func disconnect(ssid: SSID, _ completion: @escaping (WiFiDisconnectResult) -> Void) {
        NEHotspotConfigurationManager.shared.getConfiguredSSIDs { (ssids) in
            guard ssids.contains(ssid) else { return completion(.failure(.notConnected)) }
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
            completion(.success)
        }
    }
    
    func disconnect(domainName: String, _ completion: @escaping (WiFiDisconnectResult) -> Void) {
        NEHotspotConfigurationManager.shared.getConfiguredSSIDs { (domainNames) in
            guard domainNames.contains(domainName) else { return completion(.failure(.notConnected)) }
            NEHotspotConfigurationManager.shared.removeConfiguration(forHS20DomainName: domainName)
            completion(.success)
        }
    }
    
    func removeConnections() {
        NEHotspotConfigurationManager.shared.getConfiguredSSIDs { (ssids) in
            ssids.forEach { NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: $0) }
        }
    }
    
}

struct HotspotSettings {
    
    let username: String
    let password: String
    let trustedServerNames: [String]
    let caCertificate: String
    let eapType: Int

    func hotspotEAPSettings() -> NEHotspotEAPSettings {
        let settings = NEHotspotEAPSettings()
        settings.username = username
        settings.password = password
        
        if eapType != 0 {
            settings.supportedEAPTypes = [NSNumber(value: eapType)]
        } else {
            settings.supportedEAPTypes = [NSNumber(value: NEHotspotEAPSettings.EAPType.EAPTTLS.rawValue)]
        }
        
        settings.ttlsInnerAuthenticationType = NEHotspotEAPSettings.TTLSInnerAuthenticationType.eapttlsInnerAuthenticationMSCHAPv2
        settings.trustedServerNames = trustedServerNames
        
        if caCertificate.count > 0 {
            settings.setTrustedServerCertificates([caCertificate])
            
        } else {
            if let url = URL(string: "https://smartregion.moscow/lab/passpoint/lerca.der"),
               let certificateData = try? Data(contentsOf: url),
               let certificate = SecCertificateCreateWithData(nil, certificateData as CFData)
            {
                settings.setTrustedServerCertificates([certificate])
            } else {
                
            }
        }
        
        return settings
    }
}
