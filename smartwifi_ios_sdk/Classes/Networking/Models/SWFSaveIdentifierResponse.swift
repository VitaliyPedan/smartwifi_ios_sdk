//
//  SWFSaveIdentifierResponse.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

public struct SWFSaveIdentifierResponse: Codable {
    
    let result: String
    
    private enum CodingKeys: String, CodingKey {
        case result
    }

}
