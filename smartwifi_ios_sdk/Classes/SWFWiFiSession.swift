//
//  SWFWiFiSession.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 17.08.2021.
//

import Foundation

public protocol SWFWiFiSessionDelegate {
    
    func willInitializing(session: SWFWiFiSession)

    func willRequestConfig(session: SWFWiFiSession)
    func didRequestConfig(session: SWFWiFiSession, error: Error?)

    func willConnectToWiFi(session: SWFWiFiSession)
    func didConnectToWiFi(session: SWFWiFiSession, error: Error?)
    
}

enum WiFiSessionStatus {
    case initializing
    case requestConfigs
    case requestConfigsResult(EmptyResult)
    case connecting
    case connectionResult(EmptyResult)
}


public final class SWFWiFiSession {
    
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
                    self.delegate.willInitializing(session: self)
                    
                case .requestConfigs:
                    self.delegate.willRequestConfig(session: self)
                    
                case .requestConfigsResult(let result):
                    switch result {
                    case .success:
                        self.delegate.didRequestConfig(session: self, error: nil)
                    case .failure(let error):
                        self.delegate.didRequestConfig(session: self, error: error)
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

    public init(delegate: SWFWiFiSessionDelegate) {
        self.wifiService = SWFServiceImpl.shared
        self.delegate = delegate
    }
    
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

    public func startSession() throws {
        
        guard isWiFiOn() else {
            throw SWFServiceError.needCheckOnWiFiModule
        }
        
        getConfig(completion: { [weak self] (result) in
            if result == .success {
                self?.startConnection()
            }
        })
    }
    
    public func cancelSession() {
        wifiService.stopSession()
    }
    
    // MARK: - Private Methods
    
    private func getConfig(completion: @escaping (EmptyResult) -> Void) {
        
        status = .requestConfigs
        
        wifiService.configured(
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
        status = .connecting
        
        wifiService.startSession(completion: { [weak self] (result) in
            self?.status = .connectionResult(result)
        })
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

