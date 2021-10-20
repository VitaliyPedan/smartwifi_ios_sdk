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
        teamId: String,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    )
    func stopSession(completion: @escaping (EmptyResult) -> Void)
    
//    func connectWiFiPasspoint(completion: @escaping (EmptyResult) -> Void)
//    func connectWiFiWAP2Enterprise(completion: @escaping (EmptyResult) -> Void)
//    func connectWiFiWAP2(completion: @escaping (EmptyResult) -> Void)
    
}

private extension SWFServiceImpl {
    
    struct LocalConstants {
        
        static var saveIdentifierWaitingConnectionDelay: TimeInterval { 3 }
        static var saveIdentifierWaitingConnectionTryCount: Int { 5 }

        static var saveIdentifierFailureDelay: TimeInterval { 5 }
        static var saveIdentifierFailureTryCount: Int { 5 }

        static var registrationTryCount: Int { 10 }
        static var registrationTryDelay: TimeInterval { 5 }

    }

}

public final class SWFServiceImpl: SWFService {
    
    private let smartWifiApiService: SWFApiService
    private let wifiConfigurationService: WiFiConfigurationService
    
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
        teamId: String,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        
        guard let configKey = configKey else {
            let error = SWFAPIError.errorWith(text: "Need to configure session")
            applyConfigCompletion(.failure(error))
            return
        }
        
        let storage: UserDefaultsManagerType = UserDefaultsManager.shared
        
        guard let configs: SWFWiFiConfigs = try? storage.getDecodable(by: .dynamicKey(configKey)) else {
            let error = SWFAPIError.emptyConfigMethod(domain: "getWiFiSettings")
            applyConfigCompletion(.failure(error))
            return
        }
        
        acceptConfigs(
            configs,
            teamId: teamId,
            priority: 0,
            error: nil,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }
    
    private func acceptConfigs(
        _ configs: SWFWiFiConfigs,
        teamId: String,
        priority: Int,
        error: Error?,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        var _priority = priority
        
        if let passpointConfig = configs.passpointConfig, priority == passpointConfig.priority {
            
            processPasspointConfig(
                passpointConfig,
                teamId: teamId,
                applyConfigCompletion:applyConfigCompletion,
                connectionCompletion: { [weak self] (result) in
                    switch result {
                    case .success:
                        connectionCompletion(.success)
                    case .failure(let error):
                        _priority += 1
                        self?.acceptConfigs(
                            configs,
                            teamId: teamId,
                            priority: _priority,
                            error: error,
                            applyConfigCompletion: applyConfigCompletion,
                            connectionCompletion: connectionCompletion
                        )
                    }
                }
            )
        } else if let wpa2EnterpriseConfig = configs.wpa2EnterpriseConfig, priority == wpa2EnterpriseConfig.priority {
            
            processWAP2EnterpriseConfig(
                wpa2EnterpriseConfig,
                teamId: teamId,
                applyConfigCompletion:applyConfigCompletion,
                connectionCompletion: { [weak self] (result) in
                    switch result {
                    case .success:
                        connectionCompletion(.success)
                    case .failure(let error):
                        _priority += 1
                        self?.acceptConfigs(
                            configs,
                            teamId: teamId,
                            priority: _priority,
                            error: error,
                            applyConfigCompletion: applyConfigCompletion,
                            connectionCompletion: connectionCompletion
                        )
                    }
                }
            )
        } else if let wpa2Config = configs.wpa2Config, priority == wpa2Config.priority {
            
            processWAP2Config(
                wpa2Config,
                applyConfigCompletion:applyConfigCompletion,
                connectionCompletion: { [weak self] (result) in
                    switch result {
                    case .success:
                        connectionCompletion(.success)
                    case .failure(let error):
                        _priority += 1
                        self?.acceptConfigs(
                            configs,
                            teamId: teamId,
                            priority: _priority,
                            error: error,
                            applyConfigCompletion: applyConfigCompletion,
                            connectionCompletion: connectionCompletion
                        )
                    }
                }
            )
        } else {
            let _error = error ?? SWFAPIError.unableToJoinNetwork(domain: "wifi connetion")
            connectionCompletion(.failure(_error))
        }
    }
    
    public func stopSession(completion: @escaping (EmptyResult) -> Void) {
        let storage: UserDefaultsManagerType = UserDefaultsManager.shared
        
        guard let configKey = configKey,
                let configs: SWFWiFiConfigs = try? storage.getDecodable(by: .dynamicKey(configKey))
        else {
            let error = SWFAPIError.emptyConfigMethod(domain: "stopSession")
            completion(.failure(error))
            return
        }

        if let passpointConfig = configs.passpointConfig {
            wifiConfigurationService.disconnect(domainName: passpointConfig.passpointMethod.realm) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        if let wpa2EnterpriseConfig = configs.wpa2EnterpriseConfig {
            wifiConfigurationService.disconnect(ssid: wpa2EnterpriseConfig.wpa2EnterpriseMethod.ssid) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        if let wpa2Config = configs.wpa2Config {
            wifiConfigurationService.disconnect(ssid: wpa2Config.wpa2Method.ssid) { (result) in
                switch result {
                case .success:
                    completion(.success)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        if configs.passpointConfig == nil &&
            configs.wpa2EnterpriseConfig == nil &&
            configs.wpa2Config == nil
        {
            let error = SWFAPIError.emptyConfigMethod(domain: "stopSession")
            completion(.failure(error))
        }
//        storage.removeAll { [weak self] in
//            self?.wifiConfigurationService.removeConnections()
//        }
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
        teamId: String,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {

        let hotspotSettings = HotspotSettings(
            username: method.username,
            password: method.password,
            trustedServerNames: [method.fqdn],
            caCertificate: method.caCertificate,
            eapType: Int(method.eapType) ?? 0,
            nonEapInnerMethod: method.nonEapInnerMethod
        )

        wifiConfigurationService.connect(
            domainName: method.realm,
            hotspotSettings: hotspotSettings,
            teamId: teamId,
            applyResult: applyConfigCompletion,
            connectionResult: connectionCompletion
        )
    }

    func connectToWiFiWap2Enterprise(
        method: SWFWpa2EnterpriseMethod,
        teamId: String,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {

        let hotspotSettings = HotspotSettings(
            username: method.identity,
            password: method.password,
            trustedServerNames: ["hs20.smartregion.moscow"],
            caCertificate: method.caCertificate,
            eapType: 0,
            nonEapInnerMethod: ""
        )

        wifiConfigurationService.connect(
            ssid: method.ssid,
            hotspotSettings: hotspotSettings,
            teamId: teamId,
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
    func saveIdentifier(
        with url: String,
        waitingConnectionTryNumber: Int = 0,
        failureTryNumber: Int = 0,
        completion: @escaping (EmptyResult) -> Void
    ) {
        
        smartWifiApiService.saveIdentifier(with: url) { result in
            
            switch result {
            case .success(let identifierResponse):
                
                if identifierResponse.isSuccess {
                    completion(.success)
                    
                } else {
                    guard waitingConnectionTryNumber < LocalConstants.saveIdentifierWaitingConnectionTryCount else {
                        let error = SWFAPIError.errorWith(text: identifierResponse.details ?? "saveIdentifier error")
                        completion(.failure(error))
                        return
                    }
                    
                    DispatchQueue.global(
                        qos: .utility
                    ).asyncAfter(
                        deadline: .now() + LocalConstants.saveIdentifierWaitingConnectionDelay
                    ) { [weak self] in
                        
                        self?.saveIdentifier(
                            with: url,
                            waitingConnectionTryNumber: waitingConnectionTryNumber + 1,
                            completion: completion
                        )
                    }
                }
                
            case .failure(_):
                
                guard failureTryNumber < LocalConstants.saveIdentifierFailureTryCount else {
                    let error = SWFAPIError.emptyData(domain: "saveIdentifier")
                    completion(.failure(error))
                    return
                }
                
                DispatchQueue.global(
                    qos: .utility
                ).asyncAfter(
                    deadline: .now() + LocalConstants.saveIdentifierFailureDelay
                ) { [weak self] in
                    
                    self?.saveIdentifier(
                        with: url,
                        failureTryNumber: failureTryNumber + 1,
                        completion: completion
                    )
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
            case .success(let configs):
                
                guard let self = self else {
                    let error = SWFAPIError.resourceDoNotExist(domain: "getWiFiSettings")
                    completion(.failure(error))
                    return
                }
                
                do {
                    try self.saveConfigs(configs, key: self.configKey!)
                    
                    if configs.passpointConfig != nil || configs.wpa2EnterpriseConfig != nil || configs.wpa2Config != nil {
                        completion(.success)
                    } else {
                        let error = SWFAPIError.emptyData(domain: "getWiFiSettings")
                        completion(.failure(error))
                    }
                    
                } catch {
                    let error = SWFAPIError.savingData(domain: "getWiFiSettings")
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func saveConfigs(_ config: SWFWiFiConfigs, key: String) throws {
        try UserDefaultsManager.shared.storeEncodable(data: config, key: .dynamicKey(key))
    }
    
    func processPasspointConfig(
        _ config: SWFPasspointConfig,
        teamId: String,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        self.connectToWiFiPasspoint(
            method: config.passpointMethod,
            teamId: teamId,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }
    
    func processWAP2EnterpriseConfig(
        _ config: SWFWpa2EnterpriseConfig,
        teamId: String,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        self.connectToWiFiWap2Enterprise(
            method: config.wpa2EnterpriseMethod,
            teamId: teamId,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }

    func processWAP2Config(
        _ config: SWFWpa2Config,
        applyConfigCompletion: @escaping (EmptyResult) -> Void,
        connectionCompletion: @escaping (EmptyResult) -> Void
    ) {
        self.connectToWiFiWap2(
            method: config.wpa2Method,
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
                        self.saveIdentifier(
                            with: config.wpa2Method.ccUrl,
                            completion: connectionCompletion
                        )
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
