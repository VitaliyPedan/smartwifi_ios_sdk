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
        case .mappingModelFailure: return "mapping_object_data_error".swfLocalized
        case .savingDataFailure: return "saving_data_error".swfLocalized
        case .objectDoNotExist: return "session_object_is_corrupted".swfLocalized
        case .wifiModuleSwitchOff: return "wifi_module_switch_off".swfLocalized
        case .sessionIsNotConfigured: return "session_is_not_configured".swfLocalized
        case .configsNotSaved: return "no_configs_in_cache_memory".swfLocalized
        case .emptyConfigs: return "empty_response_configs_data".swfLocalized
        case .configHasNoPriority: return "priority_is_incorrect".swfLocalized
        case .saveIdentifierFailure(let responceDescription): return responceDescription ?? "can_not_find_wifi_network".swfLocalized
        case .unableToJoinNetwork: return "unable_to_join_the_network".swfLocalized
        case .saveIdentifierRequestFailure(let serverError): return serverError.localizedDescription
        case .fullWifiAccessRequestFailure(let serverError): return serverError.localizedDescription
        case .getWiFiSettingsRequestFailure(let serverError): return serverError.localizedDescription
        case .notConnectedPreviously: return "not_connected_previously".swfLocalized
        case .unknownError: return "unknown_error".swfLocalized
        case .noInternetConnection: return "no_internet_connection".swfLocalized
            /// - NEHotspotConfigurationError
        case .invalid: return "configuration_is_invalid".swfLocalized
        case .invalidSSID: return "ssid_string_is_invalid".swfLocalized
        case .invalidWPAPassphrase: return "wpa_wpa2_personal_passphrase_is_invalid".swfLocalized
        case .invalidWEPPassphrase: return "wep_passphrase_is_invalid".swfLocalized
        case .invalidEAPSettings: return "invalid_eap_settings".swfLocalized
        case .invalidHS20Settings: return "invalid_hotspot_2_0_settings".swfLocalized
        case .invalidHS20DomainName: return "hotspot_2_0_domain_name_is_invalid".swfLocalized
        case .userDenied: return "failed_to_get_user_approval".swfLocalized
        case .`internal`: return "internal_error".swfLocalized
        case .pending: return "previous_request_is_pending".swfLocalized
        case .systemConfiguration: return "application_cannot_modify_system_configuration".swfLocalized
        case .joinOnceNotSupported: return "joinOnce_option_is_not_support".swfLocalized
        case .alreadyAssociated: return "already_associated".swfLocalized
        case .applicationIsNotInForeground: return "application_is_not_in_foreground".swfLocalized
        case .invalidSSIDPrefix: return "ssid_prefix_string_is_invalid".swfLocalized
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

private extension String {

    var swfLocalized: String {
        let lang = Bundle.main.preferredLocalizations.first ?? "en"
        
        guard let path = Bundle.module.path(forResource: lang, ofType: "lproj") else { return self }
        guard let bundle = Bundle(path: path) else { return self }
        
        return NSLocalizedString(self, tableName: "SWFLocalizable", bundle: bundle, value: "", comment: "")
    }

}

private extension Bundle {

    static var module: Bundle {
        let bundle = Bundle(for: SWFWiFiSession.self)
        
        guard let path = bundle.resourcePath else { return .main }
        return Bundle(path: path.appending("/smartwifi_ios_sdk.bundle")) ?? .main
    }

}
