//
//  SWFWiFiSession.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 17.08.2021.
//

import Foundation

public protocol SWFWiFiSessionDelegate {
    
    func willRequestConfig(session: SWFWiFiSession)
    func didRequestConfig(session: SWFWiFiSession, error: Error?)

    func willApplyConfig(session: SWFWiFiSession)
    func didApplyConfig(session: SWFWiFiSession, error: Error?)

    func willConnectToWiFi(session: SWFWiFiSession)
    func didConnectToWiFi(session: SWFWiFiSession, error: Error?)
    
    func didStopWiFi(session: SWFWiFiSession)
}

enum WiFiSessionStatus {
    case initializing
    case requestConfigs
    case requestConfigsResult(EmptyResult)
    case applyConfigs
    case applyConfigsResult(EmptyResult)
    case connecting
    case connectionResult(EmptyResult)
    case cancel
}


public final class SWFWiFiSession {
    
    // MARK: - Properties

    private let wifiService: SWFService
    
    private var delegate: SWFWiFiSessionDelegate
    
    private let concurrentContactQueue = DispatchQueue(label: "com.test.contacts", attributes: .concurrent)

    private var status: WiFiSessionStatus = .initializing {
        didSet {
            switch self.status {
            case .initializing:
                break
            case .requestConfigs:
                if Thread.isMainThread {
                    self.delegate.willRequestConfig(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willRequestConfig(session: self)
                    }
                }
                
            case .requestConfigsResult(let result):
                switch result {
                case .success:
                    if Thread.isMainThread {
                        self.delegate.didRequestConfig(session: self, error: nil)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didRequestConfig(session: self, error: nil)
                        }
                    }

                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didRequestConfig(session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didRequestConfig(session: self, error: error)
                        }
                    }
                }
            
            case .applyConfigs:
                if Thread.isMainThread {
                    self.delegate.willApplyConfig(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willApplyConfig(session: self)
                    }
                }
                
            case .applyConfigsResult(let result):
                switch result {
                case .success:
                    if Thread.isMainThread {
                        self.delegate.didApplyConfig(session: self, error: nil)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didApplyConfig(session: self, error: nil)
                        }
                    }

                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didApplyConfig(session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didApplyConfig(session: self, error: error)
                        }
                    }
                }

            case .connecting:
                if Thread.isMainThread {
                    self.delegate.willConnectToWiFi(session: self)
                } else {
                    DispatchQueue.main.sync { [weak self] in
                        guard let self = self else { return }
                        self.delegate.willConnectToWiFi(session: self)
                    }
                }
                
            case .connectionResult(let result):
                switch result {
                case .success:
                    if Thread.isMainThread {
                        self.delegate.didConnectToWiFi(session: self, error: nil)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didConnectToWiFi(session: self, error: nil)
                        }
                    }

                case .failure(let error):
                    if Thread.isMainThread {
                        self.delegate.didConnectToWiFi(session: self, error: error)
                    } else {
                        DispatchQueue.main.sync { [weak self] in
                            guard let self = self else { return }
                            self.delegate.didConnectToWiFi(session: self, error: error)
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

    public init(delegate: SWFWiFiSessionDelegate) {
        self.wifiService = SWFServiceImpl.shared
        self.delegate = delegate
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
        status = .applyConfigs
        
        guard isWiFiOn() else {
            status = .applyConfigsResult(.failure(SWFServiceError.needCheckOnWiFiModule))
            return
        }

        wifiService.startSession { [weak self] (result) in
            self?.status = .applyConfigsResult(result)

            if result == .success {
                self?.status = .connecting
            }

        } connectionCompletion: { [weak self] (result) in
            self?.status = .connectionResult(result)
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

