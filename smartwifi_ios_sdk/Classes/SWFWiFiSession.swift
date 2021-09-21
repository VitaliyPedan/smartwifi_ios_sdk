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
    
}

enum WiFiSessionStatus {
    case initializing
    case requestConfigs
    case requestConfigsResult(EmptyResult)
    case applyConfigs
    case applyConfigsResult(EmptyResult)
    case connecting
    case connectionResult(EmptyResult)
}


public final class SWFWiFiSession {
    
    // MARK: - Properties

    private let wifiService: SWFService
    
    private var delegate: SWFWiFiSessionDelegate
    
    private var status: WiFiSessionStatus = .initializing {
        didSet {
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                switch self.status {
                case .initializing:
                    break
                case .requestConfigs:
                    self.delegate.willRequestConfig(session: self)
                    
                case .requestConfigsResult(let result):
                    switch result {
                    case .success:
                        self.delegate.didRequestConfig(session: self, error: nil)
                    case .failure(let error):
                        self.delegate.didRequestConfig(session: self, error: error)
                    }
                
                case .applyConfigs:
                    self.delegate.willApplyConfig(session: self)
                    
                case .applyConfigsResult(let result):
                    switch result {
                    case .success:
                        self.delegate.didApplyConfig(session: self, error: nil)
                    case .failure(let error):
                        self.delegate.didApplyConfig(session: self, error: error)
                    }

                case .connecting:
                    self.delegate.willConnectToWiFi(session: self)
                    
                case .connectionResult(let result):
                    switch result {
                    case .success:
                        self.delegate.didConnectToWiFi(session: self, error: nil)
                    case .failure(let error):
                        self.delegate.didConnectToWiFi(session: self, error: error)
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
        wifiService.stopSession()
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
            self?.status = .connecting
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

