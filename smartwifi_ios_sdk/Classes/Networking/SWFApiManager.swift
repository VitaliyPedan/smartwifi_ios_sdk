//
//  SmartWiFiAPIManager.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import Foundation

typealias APIManagerRequestCallback = ((Result<Data, Error>) -> Void)

final class SWFApiManager {
    
    // MARK: - Properties

    private let urlSession: URLSession

    // MARK: - Init

    init() {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.httpShouldUsePipelining = true
        
        urlSession = URLSession(configuration: config)
    }
    
    deinit {
        urlSession.finishTasksAndInvalidate()
    }

    // MARK: - Send methods

    func sendRequest(urlRequest: URLRequest, data: Data?, completion: @escaping APIManagerRequestCallback) {
        
        let task = urlSession.uploadTask(with: urlRequest, from: data) { (data2, respons, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data2 = data2 {
                completion(.success(data2))
            } else {
                let error = SWFSessionError.errorWith(text: "Unexpected urlSession error")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func sendRequest(urlRequest: URLRequest, completion: @escaping APIManagerRequestCallback) {
        
        let task = urlSession.dataTask(with: urlRequest) { (data, respons, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            } else {
                let error = SWFSessionError.errorWith(text: "Unexpected urlSession error")
                completion(.failure(error))
            }
        }
        task.resume()
    }

}
