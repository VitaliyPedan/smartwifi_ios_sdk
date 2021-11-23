//
//  SWFError.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 12.08.2021.
//

import NetworkExtension

/**
 Описывает возможные ошибки при работе с SWFWiFiSession
 */

public enum SWFError: LocalizedError {
    
    /// - Данная ошибка означает – ошибку создания модели данных с data полученной от сервера.
    /// - Возникает при попытке декодировать модель с Data.
    case mappingModelFailure(data: Data?)
    
    /// - Данная ошибка означает - что произошла ошибка при кэшировании конфигураций.
    /// - Возникает при попытке кодировать модель(конфигурацию) в data, для дальнейшего сохранения по ключу.
    case savingDataFailure
    
    /// - Данная ошибка означает, что объект сессии поврежден или выгружен из памяти.
    /// - Может возникнуть при запросе настроек(конфигураций), а также при добавлении/применении конфигурации.
    case objectDoNotExist
    
    /// - Данная ошибка означает, что вы должны включить модуль Wi-Fi перед подключением.
    /// - Она встречается в тех случаях, когда при подключении у пользователя отключен Wi-Fi модуль.
    case wifiModuleSwitchOff
    
    /// - Данная ошибка означает, что сеанс не настроен. Необходимо настроить сеанс перед началом использования.
    /// - Возникает при попытке запустить/остановить сессию, без предварительной настройки.
    case sessionIsNotConfigured
    
    /// - Данная ошибка означает, что нет кэшированных конфигураций для подключения.
    /// - Она встречается в тех случаях, когда запустили метод подключения/отключения, но конфигурации не были успешно сохранены.
    case configsNotSaved
    
    /// - Данная ошибка означает, что список конфигураций для подключения пуст.
    /// - Она встречается в тех случаях, когда с сервера приходят пустые конфигурации. В этом случае необходимо сообщить о проблеме.
    case emptyConfigs
    
    /// - Данная ошибка означает, что полученные конфигурации не имеют приоритета или приоритет не верен
    /// - Она встречается в тех случаях, когда от сервера неправильно приходят параметры для подключения. Возникает при попытке применить конфигурацию.
    case configHasNoPriority
    
    /// - Данная ошибка означает, что не удается найти сеть Wi-Fi при подключении по wpa2 методу.
    /// - Она встречается в тех случаях, когда пользователь находится вне зоны действия Wi-Fi или проблемы с роутером. В этом случае будет системная ошибка и SDK приступит к подключению по следующему по приоритету методу подключения.
    case saveIdentifierFailure(responceDescription: String?)
    
    /// - Данная ошибка означает, что не удается найти сеть Wi-Fi.
    /// - Возникает в случае успешного применения конфигурации, но невозможности подключится к сети. В этом случае будет системная ошибка и SDK приступит к подключению по следующему по приоритету методу подключения.
    /// - Она встречается в тех случаях, когда пользователь находится вне зоны действия Wi-Fi.
    case unableToJoinNetwork

    /// - Данная ошибка означает, ошибку с сервера при запросе saveIdentifier
    case saveIdentifierRequestFailure(serverError: Error)
    
    /// - Данная ошибка означает, ошибку с сервера при запросе fullWifiAccess
    case fullWifiAccessRequestFailure(serverError: Error)
    
    /// - Данная ошибка означает, ошибку с сервера при запросе WiFiSettings
    case getWiFiSettingsRequestFailure(serverError: Error)

    case notConnectedPreviously
    
    /// - Данные ошибки означают,  ошибки при применении конфигурации.
    case invalid
    case invalidSSID
    case invalidWPAPassphrase
    case invalidWEPPassphrase
    case invalidEAPSettings
    case invalidHS20Settings
    case invalidHS20DomainName
    case userDenied
    case `internal`
    case pending
    case systemConfiguration
    case joinOnceNotSupported
    case alreadyAssociated
    case applicationIsNotInForeground
    case invalidSSIDPrefix

    /// - Неизвестная  ошибка
    case unknownError
    
    /// - Нет  интернет соединения
    case noInternetConnection

    
    public var errorDescription: String? {
        switch self {
        case .mappingModelFailure: return localize(errorString: "mapping_object_data_error")
        case .savingDataFailure: return localize(errorString: "saving_data_error")
        case .objectDoNotExist: return localize(errorString: "session_object_is_corrupted")
        case .wifiModuleSwitchOff: return localize(errorString: "wifi_module_switch_off")
        case .sessionIsNotConfigured: return localize(errorString: "session_is_not_configured")
        case .configsNotSaved: return localize(errorString: "no_configs_in_cache_memory")
        case .emptyConfigs: return localize(errorString: "empty_response_configs_data")
        case .configHasNoPriority: return localize(errorString: "priority_is_incorrect")
        case .saveIdentifierFailure(let responceDescription): return responceDescription ?? localize(errorString: "can_not_find_wifi_network")
        case .unableToJoinNetwork: return localize(errorString: "unable_to_join_the_network")
        case .saveIdentifierRequestFailure(let serverError): return serverError.localizedDescription
        case .fullWifiAccessRequestFailure(let serverError): return serverError.localizedDescription
        case .getWiFiSettingsRequestFailure(let serverError): return serverError.localizedDescription
        case .notConnectedPreviously: return localize(errorString: "not_connected_previously")
        case .unknownError: return localize(errorString: "unknown_error")
        case .noInternetConnection: return localize(errorString: "no_internet_connection")
            /// - NEHotspotConfigurationError
        case .invalid: return localize(errorString: "configuration_is_invalid")
        case .invalidSSID: return localize(errorString: "ssid_string_is_invalid")
        case .invalidWPAPassphrase: return localize(errorString: "wpa_wpa2_personal_passphrase_is_invalid")
        case .invalidWEPPassphrase: return localize(errorString: "wep_passphrase_is_invalid")
        case .invalidEAPSettings: return localize(errorString: "invalid_eap_settings")
        case .invalidHS20Settings: return localize(errorString: "invalid_hotspot_2_0_settings")
        case .invalidHS20DomainName: return localize(errorString: "hotspot_2_0_domain_name_is_invalid")
        case .userDenied: return localize(errorString: "failed_to_get_user_approval")
        case .`internal`: return localize(errorString: "internal_error")
        case .pending: return localize(errorString: "previous_request_is_pending")
        case .systemConfiguration: return localize(errorString: "application_cannot_modify_system_configuration")
        case .joinOnceNotSupported: return localize(errorString: "joinOnce_option_is_not_support")
        case .alreadyAssociated: return localize(errorString: "already_associated")
        case .applicationIsNotInForeground: return localize(errorString: "application_is_not_in_foreground")
        case .invalidSSIDPrefix: return localize(errorString: "ssid_prefix_string_is_invalid")
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .mappingModelFailure(let data):
            if let data = data {
                return String(decoding: data, as: UTF8.self)
            } else {
                return ""
            }
        case .savingDataFailure: return ""
        case .objectDoNotExist: return ""
        case .wifiModuleSwitchOff: return ""
        case .sessionIsNotConfigured: return ""
        case .configsNotSaved: return "Возможно отсутствует интернет соединение"
        case .emptyConfigs: return ""
        case .configHasNoPriority: return ""
        case .saveIdentifierFailure: return ""
        case .unableToJoinNetwork: return ""
        case .saveIdentifierRequestFailure(let serverError): return (serverError as NSError).localizedFailureReason
        case .fullWifiAccessRequestFailure(let serverError): return (serverError as NSError).localizedFailureReason
        case .getWiFiSettingsRequestFailure(let serverError): return (serverError as NSError).localizedFailureReason
        case .notConnectedPreviously: return ""
        case .unknownError: return ""
        case .noInternetConnection: return ""
            /// - NEHotspotConfigurationError
        case .invalid: return ""
        case .invalidSSID: return ""
        case .invalidWPAPassphrase: return ""
        case .invalidWEPPassphrase: return ""
        case .invalidEAPSettings: return ""
        case .invalidHS20Settings: return ""
        case .invalidHS20DomainName: return ""
        case .userDenied: return ""
        case .`internal`: return ""
        case .pending: return ""
        case .systemConfiguration: return ""
        case .joinOnceNotSupported: return ""
        case .alreadyAssociated: return ""
        case .applicationIsNotInForeground: return ""
        case .invalidSSIDPrefix: return ""
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .mappingModelFailure: return ""
        case .savingDataFailure: return ""
        case .objectDoNotExist: return ""
        case .wifiModuleSwitchOff: return ""
        case .sessionIsNotConfigured: return ""
        case .configsNotSaved: return "Включите интернет соединение"
        case .emptyConfigs: return ""
        case .configHasNoPriority: return ""
        case .saveIdentifierFailure: return ""
        case .unableToJoinNetwork: return ""
        case .saveIdentifierRequestFailure(let serverError): return (serverError as NSError).localizedRecoverySuggestion
        case .fullWifiAccessRequestFailure(let serverError): return (serverError as NSError).localizedRecoverySuggestion
        case .getWiFiSettingsRequestFailure(let serverError): return (serverError as NSError).localizedRecoverySuggestion
        case .notConnectedPreviously: return ""
        case .unknownError: return ""
        case .noInternetConnection: return ""
            /// - NEHotspotConfigurationError
        case .invalid: return ""
        case .invalidSSID: return ""
        case .invalidWPAPassphrase: return ""
        case .invalidWEPPassphrase: return ""
        case .invalidEAPSettings: return ""
        case .invalidHS20Settings: return ""
        case .invalidHS20DomainName: return ""
        case .userDenied: return ""
        case .`internal`: return ""
        case .pending: return ""
        case .systemConfiguration: return ""
        case .joinOnceNotSupported: return ""
        case .alreadyAssociated: return ""
        case .applicationIsNotInForeground: return ""
        case .invalidSSIDPrefix: return ""
        }
    }

    static func configErrorFrom(hotspotConfigurationError: Error) -> Self {
        
        let nsError = hotspotConfigurationError as NSError
        
        guard let configError = NEHotspotConfigurationError(rawValue: nsError.code) else {
            return .unknownError
        }
        
        switch configError {
        case .invalid: return .invalid
        case .invalidSSID: return .invalidSSID
        case .invalidWPAPassphrase: return .invalidWPAPassphrase
        case .invalidWEPPassphrase: return .invalidWEPPassphrase
        case .invalidEAPSettings: return .invalidEAPSettings
        case .invalidHS20Settings: return .invalidHS20Settings
        case .invalidHS20DomainName: return .invalidHS20DomainName
        case .userDenied: return .userDenied
        case .`internal`: return .`internal`
        case .pending: return .pending
        case .systemConfiguration: return .systemConfiguration
        case .unknown: return .unknownError
        case .joinOnceNotSupported: return .joinOnceNotSupported
        case .alreadyAssociated: return .alreadyAssociated
        case .applicationIsNotInForeground: return .applicationIsNotInForeground
        case .invalidSSIDPrefix: return .invalidSSIDPrefix
        @unknown default:
            return .unknownError
        }
    }
    
}

private extension SWFError {
    
    var moduleBundle: Bundle {
        let bundle = Bundle(for: SWFWiFiSession.self)
        
        guard let path = bundle.resourcePath else { return .main }
        return Bundle(path: path.appending("/smartwifi_ios_sdk.bundle")) ?? .main
    }

    func localize(errorString: String) -> String {
        let lang = Bundle.main.preferredLocalizations.first ?? "en"
        
        guard let path = moduleBundle.path(forResource: lang, ofType: "lproj") else { return errorString }
        guard let bundle = Bundle(path: path) else { return errorString }
        
        return NSLocalizedString(errorString, tableName: "SWFLocalizable", bundle: bundle, value: "", comment: "")
    }
    
}
