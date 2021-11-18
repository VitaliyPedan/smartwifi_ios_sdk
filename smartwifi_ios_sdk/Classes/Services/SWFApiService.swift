//
//  SmartWifiApiService.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import UIKit

protocol SWFApiService {
    
    func register(
        userId: String,
        phoneNumber: String,
        _ completion: @escaping VoidCompletion
    )
    
    func register(
        userId: String,
        channelId: String,
        projectId: String,
        _ completion: @escaping APIManagerRequestCallback
    )
    
    func saveIdentifier(
        with urlString: String,
        completion: @escaping ResultCompletion<SWFSaveIdentifierResponse>
    )
    
    func fullWifiAccess(
        time: Int,
        comment: String,
        pass: String,
        downBw: String,
        upBw: String,
        completion: @escaping ResultCompletion<SWFSaveIdentifierResponse>
    )

    func getWiFiSettings(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String,
        completion: @escaping ResultCompletion<SWFWiFiConfigs>
    )
}

final class SWFApiServiceImpl: SWFApiService {
    
    private let apiManager: SWFApiManager
    
    init(apiManager: SWFApiManager) {
        self.apiManager = apiManager
    }
    
}

extension SWFApiServiceImpl {
    
    private struct SmartWiFiRegistrationRequest {

        private var headers: [String: String] {
            [
                "Content-Type": "application/json",
                "X-API-KEY": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwaWQiOiIxIiwic3ViIjoiZGM4ZDI4NGUtOWU3Mi00NmExLTk5YTctNDRhZmM2NjAzZjk5IiwiaWF0IjoxNjIxODc4MjY3LCJzY29wZXMiOlsicmVnaXN0cmF0aW9uX2dldF93aWZpX3NldHRpbmdzIl19.yfWqqg_zg_TjH0tyIWkU_8agcSSemCDOYBA4bqApOhi8Ygji5lC5Yf3-tU2kt-zT"
            ]
        }

        private let method: String = "GET"
        
        private let userId: String
        private let channelId: String
        private let projectId: String

        init(
            userId: String,
            channelId: String,
            projectId: String
        ) {
            self.userId = userId
            self.channelId = channelId
            self.projectId = projectId
        }

        func urlRequest() -> URLRequest? {
            
            let urlString = "https://wifi-reg.smartcityinterface.com/user_id=\(userId)&project_id=\(projectId)&channel_id=\(channelId)"
            
            guard let requestUrl = URL(string: urlString) else {
                return nil
            }
            
            var request = URLRequest(url: requestUrl)
            request.httpMethod = method
            request.allHTTPHeaderFields = headers
            
            return request
        }
    }
    
    func register(
        userId: String,
        channelId: String,
        projectId: String,
        _ completion: @escaping APIManagerRequestCallback
    ) {
        let request = SmartWiFiRegistrationRequest(
            userId: userId,
            channelId: channelId,
            projectId: projectId
        )
        
        if let urlRequest = request.urlRequest() {
            apiManager.sendRequest(urlRequest: urlRequest) { result in
                completion(result)
            }
        }
    }
    
}

extension SWFApiServiceImpl {
    
    private struct SmartWiFiRegistrationRequestOld {

        private var headers: [String: String] {
            [
                "Content-Type": "application/json",
                "X-API-KEY": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwaWQiOiIxNyIsInN1YiI6Im1vYmlsZV9hcHAiLCJpYXQiOjE1OTg5NzEyNTYsInNjb3BlcyI6WyJyZWdpc3RyYXRpb24iLCJzZXJ2aWNlX3ByZXJlZ2lzdHJhdGlvbiJdLCJndWlkIjoiMWJiNDU2YjAtOTY3My00ZDRlLTgyNWUtMzk3MDQyYjVkMmMzIn0.wre6hwRlBOR3DKArVuglFx-CpCXIwbBDJaOAhQc877IIYohp8-8fKvAizVdri_1w"
            ]
        }

        private let urlString: String = "https://api.smartregion.online/project/17/channel/45/registrate"
        private let method: String = "POST"
        private let userId: String
        private let phoneNumber: String
        
        init(userId: String, phoneNumber: String) {
            self.userId = userId
            self.phoneNumber = phoneNumber
        }
        
        func urlRequest() -> URLRequest? {
            
            guard let requestUrl = URL(string: urlString) else {
                return nil
            }
            
            var request = URLRequest(url: requestUrl)
            request.httpMethod = method
            request.allHTTPHeaderFields = headers
            request.httpBody = try? JSONSerialization.data(withJSONObject: [
                "user_id": userId,
                "phone_number": phoneNumber
            ])

            return request
        }

    }
    
    func register(userId: String, phoneNumber: String, _ completion: @escaping VoidCompletion) {
        
        let request = SmartWiFiRegistrationRequestOld(
            userId: userId,
            phoneNumber: phoneNumber
        )
        
        if let urlRequest = request.urlRequest() {
            let body = "Hello Cruel World!".data(using: .utf8)
            apiManager.sendRequest(urlRequest: urlRequest, data: body) { result in
                switch result {
                case .success(_): completion()
                case .failure(_): break
                }
            }
        }
        
    }
    
}

extension SWFApiServiceImpl {
    
    private struct SmartWiFiSaveIdentifierRequest {

        private var headers: [String: String] {
            [
                "Content-Type": "application/json",
                "X-API-KEY": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwaWQiOiIxIiwic3ViIjoiZGM4ZDI4NGUtOWU3Mi00NmExLTk5YTctNDRhZmM2NjAzZjk5IiwiaWF0IjoxNjIxODc4MjY3LCJzY29wZXMiOlsicmVnaXN0cmF0aW9uX2dldF93aWZpX3NldHRpbmdzIl19.yfWqqg_zg_TjH0tyIWkU_8agcSSemCDOYBA4bqApOhi8Ygji5lC5Yf3-tU2kt-zT"
            ]
        }

        private let urlString: String
        private let method: String = "GET"

        init(urlString: String) {
            self.urlString = urlString
        }

        func urlRequest() -> URLRequest? {
            guard let requestUrl = URL(string: urlString) else {
                return nil
            }
            
            var request = URLRequest(url: requestUrl)
            request.httpMethod = method
            request.allHTTPHeaderFields = headers
            
            return request
        }
    }
    
    func saveIdentifier(with urlString: String, completion: @escaping ResultCompletion<SWFSaveIdentifierResponse>) {
        
        let request = SmartWiFiSaveIdentifierRequest(urlString: urlString)
        
        if let urlRequest = request.urlRequest() {
            apiManager.sendRequest(urlRequest: urlRequest) { result in
                switch result {
                case .success(let data):
                    
                    guard let saveIdentifierResponse = try? JSONDecoder().decode(SWFSaveIdentifierResponse.self, from: data) else {
                        completion(.failure(.mappingModelFailure(data: data)))
                        return
                    }
                    completion(.success(saveIdentifierResponse))
                    
                case .failure(let error):
                    completion(.failure(.saveIdentifierRequestFailure(serverError: error)))
                }
            }
        }
    }
    
}


extension SWFApiServiceImpl {
    
    private struct FullWifiAccessRequest {

        private var headers: [String: String] {
            [
                "Content-Type": "application/json",
                "X-API-KEY": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwaWQiOiIxIiwic3ViIjoiZGM4ZDI4NGUtOWU3Mi00NmExLTk5YTctNDRhZmM2NjAzZjk5IiwiaWF0IjoxNjIxODc4MjY3LCJzY29wZXMiOlsicmVnaXN0cmF0aW9uX2dldF93aWZpX3NldHRpbmdzIl19.yfWqqg_zg_TjH0tyIWkU_8agcSSemCDOYBA4bqApOhi8Ygji5lC5Yf3-tU2kt-zT"
            ]
        }

        private let method: String = "GET"
        
        private let time: Int
        private let comment: String
        private let pass: String
        private let downBw: String
        private let upBw: String

        init(
            time: Int,
            comment: String,
            pass: String,
            downBw: String,
            upBw: String
        ) {
            self.time = time
            self.comment = comment
            self.pass = pass
            self.downBw = downBw
            self.upBw = upBw
        }

        func urlRequest() -> URLRequest? {
            
            let urlString = "https://smartwf.ru:40443/open/full/?time=\(time)&comment=\(comment)&pass=\(pass)&down_bw=\(downBw)&up_bw=\(upBw)"
            
            guard let requestUrl = URL(string: urlString) else {
                return nil
            }
            
            var request = URLRequest(url: requestUrl)
            request.httpMethod = method
            
            return request
        }
    }
    
    func fullWifiAccess(
        time: Int,
        comment: String,
        pass: String,
        downBw: String,
        upBw: String,
        completion: @escaping ResultCompletion<SWFSaveIdentifierResponse>
    ) {
        let request = FullWifiAccessRequest(
            time: time,
            comment: comment,
            pass: pass,
            downBw: downBw,
            upBw: upBw
        )
        
        if let urlRequest = request.urlRequest() {
            apiManager.sendRequest(urlRequest: urlRequest) { result in
                switch result {
                case .success(let data):
                    
                    guard let saveIdentifierResponse = try? JSONDecoder().decode(SWFSaveIdentifierResponse.self, from: data) else {
                        completion(.failure(.mappingModelFailure(data: data)))
                        return
                    }
                    completion(.success(saveIdentifierResponse))
                    
                case .failure(let error):
                    completion(.failure(.fullWifiAccessRequestFailure(serverError: error)))
                }
            }
        }
    }
    
}


extension SWFApiServiceImpl {
    
    private struct SmartWiFiSettingsRequest {

        private var headers: [String: String] {
            [
                "Content-Type": "application/json",
                "X-API-KEY": apiKey
            ]
        }

        private let method: String = "POST"
        
        private let apiKey: String
        private let userId: String
        private let channelId: String
        private let projectId: String
        private let apiDomain: String

        init(
            apiKey: String,
            userId: String,
            channelId: String,
            projectId: String,
            apiDomain: String
        ) {
            self.apiKey = apiKey
            self.userId = userId
            self.channelId = channelId
            self.projectId = projectId
            self.apiDomain = apiDomain
        }
        
        func urlRequest() -> URLRequest? {
            //https://api.smartregion.online - apiDomain
            let urlString: String = "\(apiDomain)/project/\(projectId)/channel/\(channelId)/get_wifi_settings"
            
            guard let requestUrl = URL(string: urlString) else {
                return nil
            }
            
            var request = URLRequest(url: requestUrl)
            request.httpMethod = method
            request.allHTTPHeaderFields = headers
            
            let iosVersionComponents: [String] = UIDevice.current.systemVersion.components(separatedBy: ".")
            
            let iosVersion: String = iosVersionComponents.prefix(2).joined(separator: ".")
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: [
                "user_id": userId,
                "user_field": ["platform": UIDevice.current.systemName,
                               "platform_version": iosVersion,
                               "model": UIDevice.current.model]
            ])
            return request
        }
    }
    
    func getWiFiSettings(
        apiKey: String,
        userId: String,
        channelId: String,
        projectId: String,
        apiDomain: String,
        completion: @escaping ResultCompletion<SWFWiFiConfigs>
    ) {
        let request = SmartWiFiSettingsRequest(
            apiKey: apiKey,
            userId: userId,
            channelId: channelId,
            projectId: projectId,
            apiDomain: apiDomain
        )
        
        guard let urlRequest = request.urlRequest() else {
            return
        }
        
        apiManager.sendRequest(urlRequest: urlRequest, data: nil) { result in
            
            switch result {
            case .success(let data):
                
                if let configs = try? JSONDecoder().decode(SWFWiFiConfigs.self, from: data) {
                    completion(.success(configs))
                    
//                } else if let configError = try? JSONDecoder().decode(ConfigError.self, from: data) {
//                    completion(.failure(SWFSessionError.configError(domain: #function, configError: configError)))
                    
                } else {
                    completion(.failure(.mappingModelFailure(data: data)))
                }
                
            case .failure(let error):
                completion(.failure(.getWiFiSettingsRequestFailure(serverError: error)))
            }
        }
    }
    
}
