//
//  SmartWiFiService.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import Foundation

public protocol SWFService {

    var needToSaveWAP2Identifier: Bool { get set }
    
    func configure(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String,
        completion: @escaping EmptyCompletion
    )
    
    func startSession(
        teamId: String,
        priority: Int,
        applyConfigCompletion: @escaping (SWFConfigType?, EmptyResult) -> Void,
        connectionCompletion: @escaping (SWFConfigType?, EmptyResult) -> Void
    )
    func stopSession(completion: @escaping EmptyCompletion)
    
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
        completion: @escaping EmptyCompletion
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
        priority: Int,
        applyConfigCompletion: @escaping (SWFConfigType?, EmptyResult) -> Void,
        connectionCompletion: @escaping (SWFConfigType?, EmptyResult) -> Void
    ) {
        guard let configKey = configKey else {
            applyConfigCompletion(nil, .failure(.sessionIsNotConfigured))
            return
        }
        
        let storage: SWFUserDefaultsManagerType = SWFUserDefaultsManager.shared
        
        guard let configs: SWFWiFiConfigs = try? storage.getDecodable(by: .dynamicKey(configKey)) else {
            applyConfigCompletion(nil, .failure(.configsNotSaved))
            return
        }
        
        acceptConfigs(
            configs,
            teamId: teamId,
            priority: priority,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }
    
    private func acceptConfigs(
        _ configs: SWFWiFiConfigs,
        teamId: String,
        priority: Int,
        applyConfigCompletion: @escaping (SWFConfigType?, EmptyResult) -> Void,
        connectionCompletion: @escaping (SWFConfigType?, EmptyResult) -> Void
    ) {
        if let passpointConfig = configs.passpointConfig, priority == passpointConfig.priority {
            processPasspointConfig(
                passpointConfig,
                teamId: teamId,
                applyConfigCompletion: { (result) in
                    applyConfigCompletion(.passpoint, result)
                },
                connectionCompletion: { (result) in
                    connectionCompletion(.passpoint, result)
                }
            )
            
        } else if let wpa2EnterpriseConfig = configs.wpa2EnterpriseConfig, priority == wpa2EnterpriseConfig.priority {
            processWAP2EnterpriseConfig(
                wpa2EnterpriseConfig,
                teamId: teamId,
                applyConfigCompletion: { (result) in
                    applyConfigCompletion(.wpa2Enterprise, result)
                },
                connectionCompletion: { (result) in
                    connectionCompletion(.wpa2Enterprise, result)
                }
            )

        } else if let wpa2Config = configs.wpa2Config, priority == wpa2Config.priority {
            processWAP2Config(
                wpa2Config,
                applyConfigCompletion: { (result) in
                    applyConfigCompletion(.wpa2, result)
                },
                connectionCompletion: { (result) in
                    connectionCompletion(.wpa2, result)
                }
            )

        } else {
            connectionCompletion(nil, .failure(.configHasNoPriority))
        }
    }
    
    public func stopSession(completion: @escaping EmptyCompletion) {
        
        guard let configKey = configKey else {
            completion(.failure(.sessionIsNotConfigured))
            return
        }
        
        let storage: SWFUserDefaultsManagerType = SWFUserDefaultsManager.shared
        
        guard let configs: SWFWiFiConfigs = try? storage.getDecodable(by: .dynamicKey(configKey)) else {
            completion(.failure(.configsNotSaved))
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
            completion(.failure(.emptyConfigs))
        }
    }

}

private extension SWFServiceImpl {
        
    func connectToWiFiPasspoint(
        method: SWFPasspointMethod,
        teamId: String,
        applyConfigCompletion: @escaping EmptyCompletion,
        connectionCompletion: @escaping EmptyCompletion
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
        applyConfigCompletion: @escaping EmptyCompletion,
        connectionCompletion: @escaping EmptyCompletion
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
        applyConfigCompletion: @escaping EmptyCompletion,
        connectionCompletion: @escaping EmptyCompletion
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
        completion: @escaping EmptyCompletion
    ) {
        
        smartWifiApiService.saveIdentifier(with: url) { result in
            
            switch result {
            case .success(let identifierResponse):
                
                if identifierResponse.isSuccess {
                    completion(.success)
                    
                } else {
                    guard waitingConnectionTryNumber < LocalConstants.saveIdentifierWaitingConnectionTryCount else {
                        completion(.failure(.saveIdentifierFailure(responceDescription: identifierResponse.details)))
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
                
            case .failure(let error):
                
                guard failureTryNumber < LocalConstants.saveIdentifierFailureTryCount else {
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
    
    //    3) Запрос на полный доступ к интернету:
    func fullWifiAccess(completion: @escaping EmptyCompletion) {

        smartWifiApiService.fullWifiAccess(
            time: 3600,
            comment: "from_mobile_app",
            pass: "96wImExVQPmJvd46",
            downBw: "1gbit",
            upBw: "1gbit"
        ) { _ in
        }
    }

    func getWiFiSettings(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String,
        completion: @escaping EmptyCompletion
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
                    completion(.failure(.objectDoNotExist))
                    return
                }
                
                do {
                    try self.saveConfigs(configs, key: self.configKey!)
                    
                    if configs.passpointConfig != nil || configs.wpa2EnterpriseConfig != nil || configs.wpa2Config != nil {
                        completion(.success)
                    } else {
                        completion(.failure(.emptyConfigs))
                    }
                    
                } catch {
                    completion(.failure(.savingDataFailure))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func saveConfigs(_ config: SWFWiFiConfigs, key: String) throws {
        try SWFUserDefaultsManager.shared.storeEncodable(data: config, key: .dynamicKey(key))
    }
    
    func processPasspointConfig(
        _ config: SWFPasspointConfig,
        teamId: String,
        applyConfigCompletion: @escaping EmptyCompletion,
        connectionCompletion: @escaping EmptyCompletion
    ) {
        guard !wifiConfigurationService.checkForAlreadyAssociated(config: config) else {
            connectionCompletion(.success)
            return
        }

        connectToWiFiPasspoint(
            method: config.passpointMethod,
            teamId: teamId,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }
    
    func processWAP2EnterpriseConfig(
        _ config: SWFWpa2EnterpriseConfig,
        teamId: String,
        applyConfigCompletion: @escaping EmptyCompletion,
        connectionCompletion: @escaping EmptyCompletion
    ) {
        guard !wifiConfigurationService.checkForAlreadyAssociated(config: config) else {
            connectionCompletion(.success)
            return
        }

        connectToWiFiWap2Enterprise(
            method: config.wpa2EnterpriseMethod,
            teamId: teamId,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: connectionCompletion
        )
    }

    func processWAP2Config(
        _ config: SWFWpa2Config,
        applyConfigCompletion: @escaping EmptyCompletion,
        connectionCompletion: @escaping EmptyCompletion
    ) {
        guard !wifiConfigurationService.checkForAlreadyAssociated(config: config) else {
            connectionCompletion(.success)
            return
        }
        
        connectToWiFiWap2(
            method: config.wpa2Method,
            applyConfigCompletion: applyConfigCompletion,
            connectionCompletion: { [weak self] (result) in
                guard let self = self else {
                    connectionCompletion(.failure(.objectDoNotExist))
                    return
                }

                switch result {
                case .success:
                    if self.needToSaveWAP2Identifier {
                        self.saveIdentifier(with: config.wpa2Method.ccUrl) { [weak self] (result) in
                            switch result {
                            case .success:
                                connectionCompletion(.success)
                                self?.fullWifiAccess(completion: { _ in })
                                
                            case .failure(let error):
                                connectionCompletion(.failure(error))
                            }
                        }
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
