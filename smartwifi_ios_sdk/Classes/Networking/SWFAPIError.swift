//
//  SWFAPIError.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

struct ErrorDescription {
    static let emptyData = "Empty response data"
    static let mappingFailure = "Mapping data error"
    static let resourceDoNotExist = "Resource do not exist"
    static let savingData = "Saving data procces error"
    static let restoreSavedData = "Restore saved data error"
    static let emptyConfigMethod = "Empty config method"
    static let unableToJoinNetwork = "Unable to Join the Network"
}

struct ErrorCode {
    static let emptyData = 0
    static let mappingFailure = 1
    static let resourceDoNotExist = 2
    static let savingData = 3
    static let restoreSavedData = 4
    static let emptyConfigMethod = 5
    static let unableToJoinNetwork = 6
}

struct ErrorKey {
    static let additionalInfo = "AdditionalInfo"
}

struct ConfigError: Codable {
    let detail: String
    let status: Int
    let title: String
}

// MARK: TECHDEBT: this class is usless. We can split it into variables or struct, smthng
class SWFAPIError {
    
    static func emptyConfigMethod(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.emptyConfigMethod,
            description: ErrorDescription.emptyConfigMethod
        )
    }

    static func restoreSavedData(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.restoreSavedData,
            description: ErrorDescription.restoreSavedData
        )
    }

    static func savingData(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.savingData,
            description: ErrorDescription.savingData
        )
    }

    static func resourceDoNotExist(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.resourceDoNotExist,
            description: ErrorDescription.resourceDoNotExist
        )
    }

    static func emptyData(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.emptyData,
            description: ErrorDescription.emptyData
        )
    }
    
    static func mappingFailure(domain: String, data: Data) -> Error {
        let dataDescription = String(decoding: data, as: UTF8.self)
        
        return self.error(
            domain: domain,
            code: ErrorCode.mappingFailure,
            description: ErrorDescription.mappingFailure,
            additionalInfo: dataDescription
        )
    }
    
    static func mappingFailure(domain: String, json: [String : Any]) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.mappingFailure,
            description: ErrorDescription.mappingFailure,
            additionalInfo: json.description
        )
    }
    
    static func configError(domain: String, configError: ConfigError) -> Error {
        return self.error(
            domain: domain,
            code: configError.status,
            description: configError.title,
            additionalInfo: configError.detail
        )
    }

    static func unableToJoinNetwork(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.unableToJoinNetwork,
            description: ErrorDescription.unableToJoinNetwork
        )
    }

    // MARK: TECHDEBT: temporary solution before error handling would be more advanced
    static func unknownError() -> Error {
        return self.error(domain: "Unknown error", code: 999, description: "Unknown error appeared")
    }
    
    static func errorWith(text: String) -> Error {
        return self.error(domain: "Unknown error", code: 999, description: text)
    }
    
    // MARK: - Commons
    
    static func error(domain: String, code: Int, description: String, additionalInfo: String = "") -> Error {
        let userInfo = [NSLocalizedDescriptionKey : description,
                        ErrorKey.additionalInfo : additionalInfo]
        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        return error
    }
}
