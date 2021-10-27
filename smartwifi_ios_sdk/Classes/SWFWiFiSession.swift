//
//  SWFWiFiSession.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 17.08.2021.
//

import Foundation

public protocol SWFWiFiSessionDelegate {
    
    func willRequestConfigs(session: SWFWiFiSession)
    func didRequestConfigs(session: SWFWiFiSession, error: Error?)

    func willApplyConfig(session: SWFWiFiSession)
    func didApplyConfig(type: SWFConfigType?, session: SWFWiFiSession, error: Error?)

    func willConnectToWiFi(via configType: SWFConfigType?, session: SWFWiFiSession)
    func didConnectToWiFi(via configType: SWFConfigType?, session: SWFWiFiSession, error: Error?)
    
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


public final class SWFWiFiSession {
    
    // MARK: - Properties

    private let wifiService: SWFService
    
    private var delegate: SWFWiFiSessionDelegate
    
    private var teamId: String
    private var priority: Int = 0

    private let concurrentContactQueue = DispatchQueue(label: "com.test.contacts", attributes: .concurrent)

    private var status: WiFiSessionStatus = .initializing {
        didSet {
            switch self.status {
            case .initializing:
                break
            case .requestConfigs:
                if Thread.isMainThread {
                    self.delegate.willRequestConfigs(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willRequestConfigs(session: self)
                    }
                }
                
            case .requestConfigsResult(let result):
                switch result {
                case .success:
                    if Thread.isMainThread {
                        self.delegate.didRequestConfigs(session: self, error: nil)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didRequestConfigs(session: self, error: nil)
                        }
                    }

                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didRequestConfigs(session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didRequestConfigs(session: self, error: error)
                        }
                    }
                }
            
            case .applyConfig:
                if Thread.isMainThread {
                    self.delegate.willApplyConfig(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willApplyConfig(session: self)
                    }
                }
                
            case .applyConfigResult(let type, let result):
                switch result {
                case .success:
                    if Thread.isMainThread {
                        self.delegate.didApplyConfig(type: type, session: self, error: nil)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didApplyConfig(type: type, session: self, error: nil)
                        }
                    }

                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didApplyConfig(type: type, session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didApplyConfig(type: type, session: self, error: error)
                        }
                    }
                }

            case .connecting(let configType):
                if Thread.isMainThread {
                    self.delegate.willConnectToWiFi(via: configType, session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willConnectToWiFi(via: configType, session: self)
                    }
                }
                
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
    
    private(set) var apiKey: String = ""
    private(set) var userId: String = ""
    private(set) var channelId: String = ""
    private(set) var projectId: String = ""
    private(set) var apiDomain: String = ""

    // MARK: - Init

    public init(teamId: String, delegate: SWFWiFiSessionDelegate) {
        self.wifiService = SWFServiceImpl.shared
        self.delegate = delegate
        self.teamId = teamId
    }
    
    // MARK: - Public Methods

    public func createSession(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String
    ) {
        status = .initializing
        
        self.apiKey = apiKey
        self.userId = userId
        self.channelId = channelId
        self.projectId = projectId
        self.apiDomain = apiDomain
    }

    public func getSessionConfig(completion: @escaping (EmptyResult) -> Void) {
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
    
    private func getConfig(completion: @escaping (EmptyResult) -> Void) {
        status = .requestConfigs
        
        guard isWiFiOn() else {
            status = .requestConfigsResult(.failure(SWFServiceError.needCheckOnWiFiModule))
            return
        }

        wifiService.configure(
            apiKey: apiKey,
            userId: userId,
            channelId: channelId,
            projectId: projectId,
            apiDomain: apiDomain
        ) { [weak self] (result) in
            
            self?.status = .requestConfigsResult(result)
            completion(result)
        }
    }
    
    private func startConnection() {
        status = .applyConfig
        
        guard isWiFiOn() else {
            status = .applyConfigResult(nil, .failure(SWFServiceError.needCheckOnWiFiModule))
            return
        }

        wifiService.startSession(
            teamId: teamId,
            priority: priority
        ) { [weak self] (configType, result)  in
            
            self?.status = .applyConfigResult(configType, result)

            if result == .success {
                self?.status = .connecting(configType)
            }

        } connectionCompletion: { [weak self] (configType, result) in
            self?.status = .connectionResult(configType, result)
            
            if result == .success {
                self?.priority = 0
            } else {
                self?.priority += 1
                self?.startConnection()
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

