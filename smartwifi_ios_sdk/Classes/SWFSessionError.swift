//
//  SWFAPIError.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import Foundation

struct ErrorDescription {
    static let mappingFailure = "Mapping object data error"
    static let savingData = "Saving data procces error. An error occurred while caching the configs"
    static let objectDoNotExist = "Session object is corrupted"
    static let needSwitchOnWiFiModule = "You should switch on wifi module before connecting"
    static let sessionIsNotConfigured = "Session is not configured. Please configure session before start"
    static let configsNotSaved = "No configs in cache memory"
    static let emptyConfigs = "Empty response configs data"
    static let configHasNoPriority = "Config has no priority or priority is incorrect"
    static let saveIdentifier = "Can not find wifi network"
    static let unableToJoinNetwork = "Unable to Join the Network"
    static let applyConfigError = "Error during apply config"
    
    static let saveIdentifierRequestFailure = "Error during request saveIdentifier"
    static let fullWifiAccessRequestFailure = "Error during request fullWifiAccess"
    static let getWiFiSettingsRequestFailure = "Error during request WiFiSettings"
}

struct ErrorCode {
    static let mappingFailure = 2001
    static let savingData = 2002
    static let objectDoNotExist = 2003
    static let needSwitchOnWiFiModule = 2004
    static let sessionIsNotConfigured = 2005
    static let configsNotSaved = 2006
    static let emptyConfigs = 2007
    static let configHasNoPriority = 2008
    static let saveIdentifier = 2009
    static let unableToJoinNetwork = 2010
    static let applyConfigError = 2011 // code 2011X where X code of NEHotspotConfigurationManager error
    
    static let saveIdentifierRequestFailure = 2012
    static let fullWifiAccessRequestFailure = 2013
    static let getWiFiSettingsRequestFailure = 2014
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
class SWFSessionError {
    
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

    static func savingData(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.savingData,
            description: ErrorDescription.savingData
        )
    }

    static func objectDoNotExist(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.objectDoNotExist,
            description: ErrorDescription.objectDoNotExist
        )
    }

    static func needSwitchOnWiFiModule(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.needSwitchOnWiFiModule,
            description: ErrorDescription.needSwitchOnWiFiModule
        )
    }

    static func sessionIsNotConfigured(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.sessionIsNotConfigured,
            description: ErrorDescription.sessionIsNotConfigured
        )
    }

    static func configsNotSaved(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.configsNotSaved,
            description: ErrorDescription.configsNotSaved
        )
    }

    static func emptyConfigs(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.emptyConfigs,
            description: ErrorDescription.emptyConfigs
        )
    }

    static func configHasNoPriority(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.configHasNoPriority,
            description: ErrorDescription.configHasNoPriority
        )
    }

    static func saveIdentifier(domain: String, description: String?) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.saveIdentifier,
            description: description ?? ErrorDescription.saveIdentifier
        )
    }

    static func unableToJoinNetwork(domain: String) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.unableToJoinNetwork,
            description: ErrorDescription.unableToJoinNetwork
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

    static func applyConfigError(_ error: Error) -> Error {
        return self.error(
            domain: (error as NSError).domain,
            code: (ErrorCode.applyConfigError * 10) + (error as NSError).code,
            description: error.localizedDescription //?? ErrorDescription.applyConfigError
        )
    }

    static func saveIdentifierRequestFailure(domain: String, description: String?) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.saveIdentifierRequestFailure,
            description: description ?? ErrorDescription.saveIdentifierRequestFailure
        )
    }
    
    static func fullWifiAccessRequestFailure(domain: String, description: String?) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.fullWifiAccessRequestFailure,
            description: description ?? ErrorDescription.fullWifiAccessRequestFailure
        )
    }
    
    static func getWiFiSettingsRequestFailure(domain: String, description: String?) -> Error {
        return self.error(
            domain: domain,
            code: ErrorCode.getWiFiSettingsRequestFailure,
            description: description ?? ErrorDescription.getWiFiSettingsRequestFailure
        )
    }
    
    static func errorWith(text: String) -> Error {
        return self.error(domain: "Unknown error", code: 1999, description: text)
    }
    
    // MARK: - Commons
    
    static func error(
        domain: String,
        code: Int,
        description: String,
        additionalInfo: String = ""
    ) -> Error {
        
        let userInfo = [NSLocalizedDescriptionKey : description,
                        ErrorKey.additionalInfo : additionalInfo]
        let error = NSError(domain: domain, code: code, userInfo: userInfo)
        return error
    }
    
}
