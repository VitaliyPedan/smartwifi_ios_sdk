//
//  SWFSaveIdentifierResponse.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

public struct SWFSaveIdentifierResponse: Codable {
    
    let result: String
    var details: String?
    
    var isSuccess: Bool {
        result.lowercased() == "ok"
    }
    
    private enum CodingKeys: String, CodingKey {
        case result
        case details
    }

    
}
