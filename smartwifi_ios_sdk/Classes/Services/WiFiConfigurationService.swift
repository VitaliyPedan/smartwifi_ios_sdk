//
//  WiFiConfigurationService.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import NetworkExtension

enum WiFiDisconnectResult {
    case success
    case failure(WiFiDisconnectError)
}

enum WiFiDisconnectError: Error {
    case notConnected
}

protocol WiFiConfigurationService {
    
    typealias SSID = String
    
    func connect(ssid: SSID, password: String, result: @escaping (EmptyResult) -> Void)
    func connect(ssid: SSID, hotspotSettings: HotspotSettings, result: @escaping (EmptyResult) -> Void)
    func connect(domainName: String, hotspotSettings: HotspotSettings, result: @escaping (EmptyResult) -> Void)

    func disconnect(ssid: SSID, _ completion: @escaping (WiFiDisconnectResult) -> Void)
    func disconnect(domainName: String, _ completion: @escaping (WiFiDisconnectResult) -> Void)
    func removeConnections()
}

final class WiFiConfigurationServiceImpl: WiFiConfigurationService {
    
    private func apply(
        _ hotspotConfig: NEHotspotConfiguration,
        result: @escaping (EmptyResult) -> Void
    ) {
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { (error) in
            if let error = error {
                return result(.failure(error))
            } else {
                return result(.success)
            }
        }
    }

    func connect(
        ssid: SSID,
        password: String,
        result: @escaping (EmptyResult) -> Void
    ) {
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        apply(hotspotConfig, result: result)
    }
    
    func connect(
        ssid: SSID,
        hotspotSettings: HotspotSettings,
        result: @escaping (EmptyResult) -> Void
    ) {
        let eapSettings = hotspotSettings.hotspotEAPSettings()
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, eapSettings: eapSettings)
        apply(hotspotConfig, result: result)
    }
    
    func connect(
        domainName: String,
        hotspotSettings: HotspotSettings,
        result: @escaping (EmptyResult) -> Void
    ) {
        let hs20Settings = NEHotspotHS20Settings(domainName: domainName, roamingEnabled: false)
        hs20Settings.naiRealmNames = [domainName]
        
        let eapSettings = hotspotSettings.hotspotEAPSettings()
        let hotspotConfig = NEHotspotConfiguration(hs20Settings: hs20Settings, eapSettings: eapSettings)
        apply(hotspotConfig, result: result)
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
