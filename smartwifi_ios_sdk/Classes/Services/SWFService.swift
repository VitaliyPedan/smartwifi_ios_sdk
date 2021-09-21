//
//  SmartWiFiService.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import Foundation

//enum WiFiConnectionType {
//    case wap2
//    case wap2Enterprise
//    case passpoint
//}

public protocol SWFService {

    var needToSaveWAP2Identifier: Bool { get set }
    
    func configure(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String,
        completion: @escaping (EmptyResult) -> Void
    )
    
    func startSession(
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    )
    func stopSession()
    
//    func connectWiFiPasspoint(completion: @escaping (EmptyResult) -> Void)
//    func connectWiFiWAP2Enterprise(completion: @escaping (EmptyResult) -> Void)
//    func connectWiFiWAP2(completion: @escaping (EmptyResult) -> Void)
    
}

private extension SWFServiceImpl {
    
    struct LocalConstants {
        
        static var timerDelay: TimeInterval { 2 }
        static var saveIdentifierDelay: TimeInterval { 5 }
        
        static var registrationTryCount: Int { 10 }
        static var registrationTryDelay: TimeInterval { 5 }

    }
    
}

public final class SWFServiceImpl: SWFService {
    
    private let smartWifiApiService: SWFApiService
    private let wifiConfigurationService: WiFiConfigurationService
    
    private var saveIdentifierCounter: Int = 0
    private var registrationCounter: Int = 1

    private var configKey: String?

    public var needToSaveWAP2Identifier: Bool = true
    
    public internal(set) static var shared: SWFService = SWFServiceImpl(
                    smartWifiApiService: SWFApiServiceImpl(apiManager: SWFApiManager()),
                    wifiConfigurationService: WiFiConfigurationServiceImpl()
                )

    internal init(
        smartWifiApiService: SWFApiService,
        wifiConfigurationService: WiFiConfigurationService
    ) {
        self.smartWifiApiService = smartWifiApiService
        self.wifiConfigurationService = wifiConfigurationService
    }
    
    func resetRegistrationCounter() {
        registrationCounter = 1
    }
    
    func increaseRegistrationCounter() {
        registrationCounter += 1
    }
    
    public func configure(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String,
        completion: @escaping (EmptyResult) -> Void
    ) {
        configKey = apiDomain + projectId + channelId
        
        getWiFiSettings(
            apiKey: apiKey,
            userId: userId,
            channelId: channelId,
            projectId: projectId,
            apiDomain: apiDomain,
            completion: completion
        )
    }

    public func startSession(
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        
        guard let configKey = configKey else {
            let error = SWFAPIError.errorWith(text: "Need to configure session")
            applyConfigCompletion(.failure(error))
            return
        }
        
        let storage: UserDefaultsManagerType = UserDefaultsManager.shared
        
        if let passpointConfig: SWFWiFiConfig<SWFPasspointConfig> = try? storage.getDecodable(by: .dynamicKey(configKey)) {
            processPasspointConfig(
                passpointConfig,
                applyConfigCompletion: applyConfigCompletion,
                connectionCompletion: connectionCompletion
            )
            
        } else if let wpa2EnterpriseConfig: SWFWiFiConfig<SWFWpa2EnterpriseConfig> = try? storage.getDecodable(by: .dynamicKey(configKey)) {
            processWAP2EnterpriseConfig(
                wpa2EnterpriseConfig,
                applyConfigCompletion: applyConfigCompletion,
                connectionCompletion: connectionCompletion
            )
            
        } else if let wpa2Config: SWFWiFiConfig<SWFWpa2Config> = try? storage.getDecodable(by: .dynamicKey(configKey)) {
            processWAP2Config(
                wpa2Config,
                applyConfigCompletion: applyConfigCompletion,
                connectionCompletion: connectionCompletion
            )
            
        } else {
            let error = SWFAPIError.emptyConfigMethod(domain: "getWiFiSettings")
            applyConfigCompletion(.failure(error))
        }
    }
    
    public func stopSession() {
        let storage: UserDefaultsManagerType = UserDefaultsManager.shared
        
        storage.removeAll { [weak self] in
            self?.wifiConfigurationService.removeConnections()
        }
    }

//    public func connectWiFiPasspoint(completion: @escaping (EmptyResult) -> Void) {
//
//        let domainName: String = "vm-cbcc.smartregion.local"
//        let username: String = "79267000000"
//        let password: String = "2GhaLdT8Rk"
//
//        let trustedServerName: String = "hs20.smartregion.moscow"
//
//        let passpointMethod = SWFPasspointMethod(
//            username: username,
//            password: password,
//            fqdn: trustedServerName,
//            eapType: "21",
//            nonEapInnerMethod: "MS-CHAP-V2",
//            friendlyName: "SmartWiFi HS20 Operator",
//            realm: domainName,
//            caCertificate: ""
//        )
//
//        self.connectToWiFiPasspoint(method: passpointMethod) { (result) in
//
//            switch result {
//            case .success:
//                completion(.success)
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    public func connectWiFiWAP2Enterprise(completion: @escaping (EmptyResult) -> Void) {
//
//        let ssid: String = "HS20-AP"
//        let username: String = "79267000000"
//        let password: String = "2GhaLdT8Rk"
//
//        let wpa2EnterpriseMethod = SWFWpa2EnterpriseMethod(
//            ssid: ssid,
//            password: password,
//            identity: username,
//            caCertificate: ""
//        )
//
//        self.connectToWiFiWap2Enterprise(method: wpa2EnterpriseMethod) { (result) in
//
//            switch result {
//            case .success:
//                completion(.success)
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    public func connectWiFiWAP2(completion: @escaping (EmptyResult) -> Void) {
//
//        let ssid: String = "Smart UMICO"
//        let password: String = "19130717"
//        let ccUrl: String = "https://wifi-reg.smartcityinterface.com/user_id=pntr54355430-dfbdb43-43t34mmljbdf&project_id=1&channel_id=1"
//
//        let wpa2Method = SWFWpa2Method(
//            ssid: ssid,
//            password: password,
//            ccUrl: ccUrl
//        )
//
//        self.connectToWiFiWap2(method: wpa2Method) { [weak self] (result) in
//            guard let self = self else {
//                return
//            }
//
//            switch result {
//            case .success:
//                if self.needToSaveWAP2Identifier {
//                    self.saveIdentifier(with: wpa2Method.ccUrl, completion: completion)
//                } else {
//                    completion(.success)
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//
//    }

}

private extension SWFServiceImpl {
        
    func connectToWiFiPasspoint(
        method: SWFPasspointMethod,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {

        let hotspotSettings = HotspotSettings(
            username: method.username,
            password: method.password,
            trustedServerNames: [method.fqdn],
            caCertificate: method.caCertificate,
            eapType: Int(method.eapType) ?? 0
        )

        wifiConfigurationService.connect(
            domainName: method.realm,
            hotspotSettings: hotspotSettings,
            applyResult: applyConfigCompletion,
            connectionResult: connectionCompletion
        )
    }

    func connectToWiFiWap2Enterprise(
        method: SWFWpa2EnterpriseMethod,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {

        let hotspotSettings = HotspotSettings(
            username: method.identity,
            password: method.password,
            trustedServerNames: ["hs20.smartregion.moscow"],
            caCertificate: method.caCertificate,
            eapType: 0
        )

        wifiConfigurationService.connect(
            ssid: method.ssid,
            hotspotSettings: hotspotSettings,
            applyResult: applyConfigCompletion,
            connectionResult: connectionCompletion
        )
    }

    func connectToWiFiWap2(
        method: SWFWpa2Method,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {

        wifiConfigurationService.connect(
            ssid: method.ssid,
            password: method.password,
            applyResult: applyConfigCompletion,
            connectionResult: connectionCompletion
        )
    }

}

private extension SWFServiceImpl {
    
    //    1) Запрос на регистрацию в сети:
    func registerUser(
        userId: String,
        channelId: String,
        projectId: String
    ) {
        smartWifiApiService.register(
            userId: userId,
            channelId: channelId,
            projectId: projectId
        ) { [weak self] (result) in
                        
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(_):
                self.resetRegistrationCounter()
                
            case .failure(_):
                
                guard self.registrationCounter <= LocalConstants.registrationTryCount else {
                    return
                }
                DispatchQueue.global(
                    qos: .utility
                ).asyncAfter(
                    deadline: .now() + LocalConstants.registrationTryDelay
                ) { [weak self] in
                    self?.increaseRegistrationCounter()
                    self?.registerUser(userId: userId, channelId: channelId, projectId: projectId)
                }
            }
        }
    }
    
    
//    2) Запрос на сохранение идентификатора:
    func saveIdentifier(with url: String, completion: @escaping (EmptyResult) -> Void) {
        
        saveIdentifierCounter += 1
        let currentSaveIdentifierCounter = saveIdentifierCounter
        
        smartWifiApiService.saveIdentifier(with: url) { result in
            
            switch result {
            case .success(let identifierResponse):
                if identifierResponse.isSuccess {
                    completion(.success)
                } else {
                    let error = SWFAPIError.errorWith(text: identifierResponse.details ?? "unknown error")
                    completion(.failure(error))
                }
                
            case .failure(_):
                guard currentSaveIdentifierCounter < 3 else {
                    let error = SWFAPIError.emptyData(domain: "saveIdentifier")
                    completion(.failure(error))
                    return //{ self?.saveIdentifierCounter = 0 }()
                }
                DispatchQueue.global(
                    qos: .utility
                ).asyncAfter(
                    deadline: .now() + LocalConstants.saveIdentifierDelay
                ) { [weak self] in
                    self?.saveIdentifier(with: url, completion: completion)
                }
            }
        }
        
    }
    
    func getWiFiSettings(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String,
        completion: @escaping (EmptyResult) -> Void
    ) {
        
        smartWifiApiService.getWiFiSettings(
            apiKey: apiKey,
            userId: userId,
            channelId: channelId,
            projectId: projectId,
            apiDomain: apiDomain
        ) { [weak self] (result) in
            
            switch result {
            case .success(let passpointConfig, let wpa2EnterpriseConfig, let wpa2Config):
                
//                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + LocalConstants.timerDelay) {
//                    DispatchQueue.main.async { [weak self] in
//
                        guard let self = self else {
                            let error = SWFAPIError.resourceDoNotExist(domain: "getWiFiSettings")
                            completion(.failure(error))
                            return
                        }

                        do {
                            if let passpointConfig = passpointConfig {
                                try self.saveConfig(passpointConfig, key: self.configKey!)

                            } else if let wpa2EnterpriseConfig = wpa2EnterpriseConfig {
                                try self.saveConfig(wpa2EnterpriseConfig, key: self.configKey!)

                            } else if let wpa2Config = wpa2Config {
                                try self.saveConfig(wpa2Config, key: self.configKey!)
                            }
                    
                            if passpointConfig != nil || wpa2EnterpriseConfig != nil || wpa2Config != nil {
                                completion(.success)
                            } else {
                                let error = SWFAPIError.emptyData(domain: "getWiFiSettings")
                                completion(.failure(error))
                            }
                            
                        } catch {
                            let error = SWFAPIError.savingData(domain: "getWiFiSettings")
                            completion(.failure(error))
                        }
//                    }
//                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
 
    func saveConfig(_ config: SWFWiFiConfig<SWFPasspointConfig>, key: String) throws {
//        try UserDefaultsManager.shared.storeEncodable(data: config, key: .passpointConfiguration)
        try UserDefaultsManager.shared.storeEncodable(data: config, key: .dynamicKey(key))
    }
    
    func saveConfig(_ config: SWFWiFiConfig<SWFWpa2EnterpriseConfig>, key: String) throws {
//        try UserDefaultsManager.shared.storeEncodable(data: config, key: .wap2EnterpriseConfiguration)
        try UserDefaultsManager.shared.storeEncodable(data: config, key: .dynamicKey(key))
    }

    func saveConfig(_ config: SWFWiFiConfig<SWFWpa2Config>, key: String) throws {
//        try UserDefaultsManager.shared.storeEncodable(data: config, key: .wap2Configuration)
        try UserDefaultsManager.shared.storeEncodable(data: config, key: .dynamicKey(key))
    }

    func processPasspointConfig(
        _ config: SWFWiFiConfig<SWFPasspointConfig>,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        guard let passpointMethod = config.wifiConfig?.passpointMethod else {
            let error = SWFAPIError.emptyConfigMethod(domain: "connectToWiFiPasspoint")
            applyConfigCompletion(.failure(error))
            return
        }

        self.connectToWiFiPasspoint(
            method: passpointMethod,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }
    
    func processWAP2EnterpriseConfig(
        _ config: SWFWiFiConfig<SWFWpa2EnterpriseConfig>,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        guard let wpa2EnterpriseMethod = config.wifiConfig?.wpa2EnterpriseMethod else {
            let error = SWFAPIError.emptyConfigMethod(domain: "connectToWiFiWap2Enterprise")
            applyConfigCompletion(.failure(error))
            return
        }
        
        self.connectToWiFiWap2Enterprise(
            method: wpa2EnterpriseMethod,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }

    func processWAP2Config(
        _ config: SWFWiFiConfig<SWFWpa2Config>,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        guard let wpa2Method = config.wifiConfig?.wpa2Method else {
            let error = SWFAPIError.emptyConfigMethod(domain: "connectToWiFiWap2")
            applyConfigCompletion(.failure(error))
            return
        }
        
        self.connectToWiFiWap2(
            method: wpa2Method,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: { [weak self] (result) in
                guard let self = self else {
                    let error = SWFAPIError.resourceDoNotExist(domain: "connectToWiFiWap2")
                    connectionCompletion(.failure(error))
                    return
                }

                switch result {
                case .success:
                    if self.needToSaveWAP2Identifier {
                        self.saveIdentifier(with: wpa2Method.ccUrl, completion: connectionCompletion)
                    } else {
                        connectionCompletion(.success)
                    }
                case .failure(let error):
                    connectionCompletion(.failure(error))
                }
            }
        )
        
    }

}
