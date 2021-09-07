//
//  SmartWiFiAPIManager.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import Foundation

typealias APIManagerRequestCallback = ((Result<Data, Error>) -> Void)

final class SWFApiManager {
    
    func sendRequest(urlRequest: URLRequest, data: Data?, completion: @escaping APIManagerRequestCallback) {
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.uploadTask(with: urlRequest, from: data) { (data2, respons, error) in
            if let error = error {
                completion(.failure(error))
            } else if let data2 = data2 {
                completion(.success(data2))
            } else {
//                completion(.failure(nil))
            }
        }
        task.resume()
    }
    
}
