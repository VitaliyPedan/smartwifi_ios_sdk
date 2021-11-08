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
        teamId: String,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    )
    
    func connect(
        domainName: String,
        hotspotSettings: HotspotSettings,
        teamId: String,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    )
    
    func disconnect(ssid: SSID, completion: @escaping (WiFiDisconnectResult) -> Void)
    func disconnect(domainName: String, completion: @escaping (WiFiDisconnectResult) -> Void)
    func removeConnections()
    
    func checkForAlreadyAssociated(config: SWFPasspointConfig) -> Bool
    func checkForAlreadyAssociated(config: SWFWpa2EnterpriseConfig) -> Bool
    func checkForAlreadyAssociated(config: SWFWpa2Config) -> Bool

}

final class WiFiConfigurationServiceImpl: WiFiConfigurationService {
    
    // MARK: - Properties

    private let tryConnectCount: Int = 6

    // MARK: - Public methods

    func connect(
        ssid: SSID,
        password: String,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    ) {
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        applyAndConnect(hotspotConfig, applyCompletion: applyResult, connectionCompletion: connectionResult)
    }
    
    func connect(
        ssid: SSID,
        hotspotSettings: HotspotSettings,
        teamId: String,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    ) {
        let eapSettings = hotspotSettings.hotspotEAPSettings(teamId: teamId)
        let hotspotConfig = NEHotspotConfiguration(ssid: ssid, eapSettings: eapSettings)
        applyAndConnect(hotspotConfig, applyCompletion: applyResult, connectionCompletion: connectionResult)
    }
    
    func connect(
        domainName: String,
        hotspotSettings: HotspotSettings,
        teamId: String,
        applyResult: @escaping (EmptyResult) -> Void,
        connectionResult: @escaping (EmptyResult) -> Void
    ) {
        let hs20Settings = NEHotspotHS20Settings(domainName: domainName, roamingEnabled: false)
        hs20Settings.naiRealmNames = [domainName]
        
        let eapSettings = hotspotSettings.hotspotEAPSettings(teamId: teamId)
        let hotspotConfig = NEHotspotConfiguration(hs20Settings: hs20Settings, eapSettings: eapSettings)
        applyAndConnect(hotspotConfig, applyCompletion: applyResult, connectionCompletion: connectionResult)
    }
    
    func disconnect(ssid: SSID, completion: @escaping (WiFiDisconnectResult) -> Void) {
        NEHotspotConfigurationManager.shared.getConfiguredSSIDs { (ssids) in
            guard ssids.contains(ssid) else { return completion(.failure(.notConnected)) }
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
            completion(.success)
        }
    }
    
    func disconnect(domainName: String, completion: @escaping (WiFiDisconnectResult) -> Void) {
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

    func checkForAlreadyAssociated(config: SWFPasspointConfig) -> Bool {
        return false
    }

    func checkForAlreadyAssociated(config: SWFWpa2EnterpriseConfig) -> Bool {
        let networkSsid = currentWifiInfo()
        return networkSsid == config.wpa2EnterpriseMethod.ssid
    }

    func checkForAlreadyAssociated(config: SWFWpa2Config) -> Bool {
        let networkSsid = currentWifiInfo()
        return networkSsid == config.wpa2Method.ssid
    }

    // MARK: - Private methods

    private func applyAndConnect(
        _ hotspotConfig: NEHotspotConfiguration,
        applyCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        apply(hotspotConfig, completion: { [weak self] (result) in
            applyCompletion(result)
            
            if result == .success {
                self?.checkConnection(hotspotConfig, tryNumber: 0, completion: connectionCompletion)
            }
        })
    }

    // MARK: - Help methods

    private func apply(
        _ hotspotConfig: NEHotspotConfiguration,
        completion: @escaping (EmptyResult) -> Void
    ) {
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { (error) in
            
            if let error = error {
                return completion(.failure(error))
            } else {
                return completion(.success)
            }
        }
    }

    private func checkConnection(
        _ hotspotConfig: NEHotspotConfiguration,
        tryNumber: Int,
        completion: @escaping (EmptyResult) -> Void
    ) {
        
        func checkNetworkName(_ ssid: String?) {
            
            if ssid == hotspotConfig.ssid {
                return completion(.success)
                
            } else if hotspotConfig.ssid.isEmpty { //passpoint
                return completion(.success)
                
            } else {
                DispatchQueue.global(
                    qos: .utility
                ).asyncAfter(
                    deadline: .now() + 2
                ) {
                    self.checkConnection(hotspotConfig, tryNumber: tryNumber + 1, completion: completion)
                }
            }
        }
        
        if #available(iOS 14.0, *) {
            
            NEHotspotNetwork.fetchCurrent { [weak self] (network) in
                
                guard let self = self, tryNumber < self.tryConnectCount else {
                    let error = SWFAPIError.unableToJoinNetwork(domain: "wifi connetion ios > 14.0")
                    return completion(.failure(error))
                }
                
                checkNetworkName(network?.ssid)
            }
            
        } else {
            
            guard tryNumber < tryConnectCount else {
                let error = SWFAPIError.unableToJoinNetwork(domain: "wifi connetion ios < 14.0")
                return completion(.failure(error))
            }

            let networkSsid = currentWifiInfo()
            checkNetworkName(networkSsid)
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
                // print("BSSID: \(interfaceData["BSSID"]), SSID: \(interfaceData["SSID"]), SSIDDATA: \(interfaceData["SSIDDATA"])")
                return interfaceData["SSID"] as? String
            } else {
                return nil
            }
        }
        
        return nil
    }
        
}

struct HotspotSettings {
    
    let username: String
    let password: String
    let trustedServerNames: [String]
    let caCertificate: String
    let eapType: Int
    let nonEapInnerMethod: String
    
    func hotspotEAPSettings(teamId: String) -> NEHotspotEAPSettings {
        let settings = NEHotspotEAPSettings()
        settings.username = username
        settings.password = password
        
        if eapType != 0 {
            settings.supportedEAPTypes = [NSNumber(value: eapType)]
        } else {
            settings.supportedEAPTypes = [NSNumber(value: NEHotspotEAPSettings.EAPType.EAPTTLS.rawValue)]
        }
        
        if let authenticationType = authenticationType() {
            settings.ttlsInnerAuthenticationType = authenticationType
        }
        settings.trustedServerNames = trustedServerNames
        
        settings.isTLSClientCertificateRequired = true
        
        if !caCertificate.isEmpty {
            
            if let certificateData = Data(base64Encoded: caCertificate),
               let certificate = storeCertData(certificateData, teamId: teamId)
            {
                settings.setTrustedServerCertificates([certificate])
            }
            
        } else {
            
            if let url = URL(string: "https://smartregion.moscow/lab/passpoint/lerca.der"),
               let certificateData = try? Data(contentsOf: url),
               let certificate = storeCertData(certificateData, teamId: teamId)
            {
                settings.setTrustedServerCertificates([certificate])
            }
        }
        
        return settings
    }
    
    func storeCertData(_ certData: Data, teamId: String) -> SecCertificate? {
        let documentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = documentDirURL.appendingPathComponent("lerca").appendingPathExtension("der")
        
        if let certificateData = try? Data(contentsOf: fileURL) as CFData,
           let certificate = SecCertificateCreateWithData(nil, certificateData)
        {
            return certificate
            
        } else {
            
            try? certData.write(to: fileURL)
            
            if let certificateData = try? Data(contentsOf: fileURL) as CFData,
               let certificate = SecCertificateCreateWithData(nil, certificateData)
            {
                if addCertIntoKeychain(certificate: certificate, teamId: teamId) {
                    return certificate
                    
                } else {
                    try? FileManager.default.removeItem(at: fileURL)
                    return certificate //try set cert without storing into keychain
                }
                
            } else {
                return nil
            }
        }
    }
    
    func addCertIntoKeychain(certificate: SecCertificate, teamId: String) -> Bool {
        var keychainQueryDictionary = [String : Any]()
        
        let accessGroup = teamId + ".com.apple.networkextensionsharing"
        keychainQueryDictionary = [kSecClass as String : kSecClassCertificate,
                                   kSecValueRef as String : certificate,
                                   kSecAttrAccessGroup as String: accessGroup,
                                   kSecAttrLabel as String: "CaCertificate"]
        
        let summary = SecCertificateCopySubjectSummary(certificate)! as String
        print("Cert summary: \(summary)")
        
        let _ = SecItemDelete(keychainQueryDictionary as CFDictionary)
        let status = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    func authenticationType() -> NEHotspotEAPSettings.TTLSInnerAuthenticationType? {
        
        if nonEapInnerMethod == "PAP" {
            return .eapttlsInnerAuthenticationPAP
        } else if nonEapInnerMethod == "CHAP" {
            return .eapttlsInnerAuthenticationCHAP
        } else if nonEapInnerMethod == "MS-CHAP" {
            return .eapttlsInnerAuthenticationMSCHAP
        } else if nonEapInnerMethod == "MS-CHAP-V2" {
            return .eapttlsInnerAuthenticationMSCHAPv2
        } else if nonEapInnerMethod == "EAP" {
            return .eapttlsInnerAuthenticationEAP
        } else {
            return nil
        }
    }
}
