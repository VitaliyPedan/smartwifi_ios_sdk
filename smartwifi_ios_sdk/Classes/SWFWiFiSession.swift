//
//  SWFWiFiSession.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 17.08.2021.
//

import Foundation

public protocol SWFWiFiSessionDelegate {
    
    func willCreate(session: SWFWiFiSession)
    func didCreate(session: SWFWiFiSession, error: SWFError?)

    func willConnectToWiFi(session: SWFWiFiSession)
    func didConnectToWiFi(via configType: SWFConfigType?, session: SWFWiFiSession, error: SWFError?)
    
    func didStopWiFi(session: SWFWiFiSession)
}

enum WiFiSessionStatus {
    case initializing
    case requestConfigs
    case requestConfigsResult(EmptyResult)
    case applyConfig
    case applyConfigResult(SWFConfigType?, EmptyResult)
    case connecting(SWFConfigType?)
    case connectionResult(SWFConfigType?, EmptyResult)
    case cancel
}

public struct SWFSessionObject {
    let apiKey: String
    let userId: String
    let payloadId: String?
    let channelId: String
    let projectId: String
    let apiDomain: String
    
    public init(
        apiKey: String,
        userId: String,
        payloadId: String?,
        channelId: String,
        projectId: String,
        apiDomain: String
    ) {
        self.apiKey = apiKey
        self.userId = userId
        self.payloadId = payloadId
        self.channelId = channelId
        self.projectId = projectId
        self.apiDomain = apiDomain
    }
    
}

public final class SWFWiFiSession {
    
    // MARK: - Properties

    private let wifiService: SWFService
    
    private var delegate: SWFWiFiSessionDelegate
    
    private var teamId: String
    private var priority: Int = 0
    private var numbersOfPriorities: Int = 0

    private var status: WiFiSessionStatus = .initializing {
        didSet {
            switch self.status {
            case .initializing:
                break
            case .requestConfigs:
                if Thread.isMainThread {
                    self.delegate.willCreate(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willCreate(session: self)
                    }
                }
                
            case .requestConfigsResult(let result):
                switch result {
                case .success:
                    if Thread.isMainThread {
                        self.delegate.didCreate(session: self, error: nil)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didCreate(session: self, error: nil)
                        }
                    }

                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didCreate(session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didCreate(session: self, error: error)
                        }
                    }
                }
            
            case .applyConfig:
                if Thread.isMainThread {
                    self.delegate.willConnectToWiFi(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willConnectToWiFi(session: self)
                    }
                }
                
            case .applyConfigResult(let type, let result):
                switch result {
                case .success:
                    break
                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didConnectToWiFi(via: type, session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didConnectToWiFi(via: type, session: self, error: error)
                        }
                    }
                }

            case .connecting(_):
                break
            case .connectionResult(let configType, let result):
                switch result {
                case .success:
                    if Thread.isMainThread {
                        self.delegate.didConnectToWiFi(via: configType, session: self, error: nil)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didConnectToWiFi(via: configType, session: self, error: nil)
                        }
                    }

                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didConnectToWiFi(via: configType, session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didConnectToWiFi(via: configType, session: self, error: error)
                        }
                    }
                }
            case .cancel:
                if Thread.isMainThread {
                    self.delegate.didStopWiFi(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.didStopWiFi(session: self)
                    }
                }

            }
        }
    }
    
    private(set) var sessionObject: SWFSessionObject?

    // MARK: - Init

    public init(teamId: String, delegate: SWFWiFiSessionDelegate) {
        self.wifiService = SWFServiceImpl.shared
        self.delegate = delegate
        self.teamId = teamId
    }
    
    // MARK: - Public Methods

    public func createSession(
        sessionObject: SWFSessionObject,
        completion: @escaping EmptyCompletion
    ) {
        status = .initializing
        
        self.sessionObject = sessionObject
        
        getConfig(completion: completion)
    }

    public func startSession() {
        startConnection()
    }
    
    public func cancelSession() {
        wifiService.stopSession() { [weak self] _ in
            self?.status = .cancel
        }
    }
    
    // MARK: - Private Methods
    
    private func getConfig(completion: @escaping EmptyCompletion) {
        status = .requestConfigs
        
        guard isWiFiOn() else {
            status = .requestConfigsResult(.failure(.wifiModuleSwitchOff))
            return
        }

        guard let sessionObject = sessionObject else {
            status = .requestConfigsResult(.failure(.sessionIsNotCreated))
            return
        }
        
        wifiService.configure(sessionObject: sessionObject) { [weak self] (result) in
            
            switch result {
            case .success(let numberOfPriorities):
                self?.numbersOfPriorities = numberOfPriorities
                self?.status = .requestConfigsResult(.success)
                completion(.success)
                
            case .failure(let error):
                
                // try use cashed configs
                let storage: SWFUserDefaultsManagerType = SWFUserDefaultsManager.shared

                guard let configKey = self?.wifiService.configKey,
                        let _: SWFWiFiConfigs = try? storage.getDecodable(by: .dynamicKey(configKey))
                else {
                    self?.status = .requestConfigsResult(.failure(error))
                    completion(.failure(error))
                    return
                }
                //
                
                self?.status = .requestConfigsResult(.success)
                completion(.success)
            }
        }
    }
    
    private func startConnection() {
        
        status = .applyConfig
        
        guard self.isWiFiOn() else {
            status = .applyConfigResult(nil, .failure(.wifiModuleSwitchOff))
            return
        }
        
        self.wifiService.startSession(
            teamId: teamId,
            priority: priority
        ) { [weak self] (configType, result)  in
            
            self?.status = .applyConfigResult(configType, result)
            
            if result == .success {
                self?.status = .connecting(configType)
            } else {
                self?.priority = 0
            }
            
        } connectionCompletion: { [weak self] (configType, result) in
            
            guard let self = self else {
                return
            }
            
            switch result {
            case .success:
                self.status = .connectionResult(configType, result)
                self.priority = 0
                
            case .failure(let error):
                if case .configHasNoPriority = error {
                    self.status = .connectionResult(configType, result)
                    
                } else if self.priority + 1 >= self.numbersOfPriorities {
                    self.status = .connectionResult(configType, result)
                    
                } else {
                    #if DEBUG
                    self.status = .connectionResult(configType, result)
                    #endif

                    self.priority += 1
                    self.startConnection()
                }
            }
        }
    }
    
    private func isWiFiOn() -> Bool {
        
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    if String.init(cString: interface!.ifa_name) == "awdl0" {
                        
                        if((Int32(interface!.ifa_flags) & IFF_UP) == IFF_UP) {
                            return(true)
                        }
                        else {
                            return(false)
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return (false)
    }

}

