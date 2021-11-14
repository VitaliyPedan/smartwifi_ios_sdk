//
//  SWFErrors.swift
//  ertelecomwifi
//
//  Created by Vladislav Erchik on 5.02.21.
//

import Foundation

/**
 Описывает возможные ошибки при работе с SWFWiFiSession
 */

public enum SWFErrors: Error, LocalizedError {
    
    /// - Данная ошибка означает – ошибку создания модели данных с data полученной от сервера.
    /// - Возникает при попытке декодировать модель с Data.
    case mappingFailure //= 2001
    
    /// - Данная ошибка означает - что произошла ошибка при кэшировании конфигураций.
    /// - Возникает при попытке кодировать модель(конфигурацию) в data, для дальнейшего сохранения по ключу.
    case savingData //= 2002
    
    /// - Данная ошибка означает, что объект сессии поврежден или выгружен из памяти.
    /// - Может возникнуть при запросе настроек(конфигураций), а также при добавлении/применении конфигурации.
    case objectDoNotExist //= 2003
    
    /// - Данная ошибка означает, что вы должны включить модуль Wi-Fi перед подключением.
    /// - Она встречается в тех случаях, когда при подключении у пользователя отключен Wi-Fi модуль.
    case needSwitchOnWiFiModule //= 2004
    
    /// - Данная ошибка означает, что сеанс не настроен. Необходимо настроить сеанс перед началом использования.
    /// - Возникает при попытке запустить/остановить сессию, без предварительной настройки.
    case sessionIsNotConfigured //= 2005
    
    /// - Данная ошибка означает, что нет кэшированных конфигураций для подключения.
    /// - Она встречается в тех случаях, когда запустили метод подключения/отключения, но конфигурации не были успешно сохранены.
    case configsNotSaved //= 2006
    
    /// - Данная ошибка означает, что список конфигураций для подключения пуст.
    /// - Она встречается в тех случаях, когда с сервера приходят пустые конфигурации. В этом случае необходимо сообщить о проблеме.
    case emptyConfigs //= 2007
    
    /// - Данная ошибка означает, что полученные конфигурации не имеют приоритета или приоритет не верен
    /// - Она встречается в тех случаях, когда от сервера неправильно приходят параметры для подключения. Возникает при попытке применить конфигурацию.
    case configHasNoPriority //= 2008
    
    /// - Данная ошибка означает, что не удается найти сеть Wi-Fi при подключении по wpa2 методу.
    /// - Она встречается в тех случаях, когда пользователь находится вне зоны действия Wi-Fi или проблемы с роутером. В этом случае будет системная ошибка и SDK приступит к подключению по следующему по приоритету методу подключения.
    case saveIdentifier //= 2009
    
    /// - Данная ошибка означает, что не удается найти сеть Wi-Fi.
    /// - Возникает в случае успешного применения конфигурации, но невозможности подключится к сети. В этом случае будет системная ошибка и SDK приступит к подключению по следующему по приоритету методу подключения.
    /// - Она встречается в тех случаях, когда пользователь находится вне зоны действия Wi-Fi.
    case unableToJoinNetwork //= 2010
    
    /// - Данная ошибка означает, что ошибку при применении конфигурации.
    /// - Данную ошибку возвращает NEHotspotConfigurationManager при вызове метода - apply(_ configuration: NEHotspotConfiguration).
    case applyConfigError(internalCode: Int) //= 2011

    /// - Данная ошибка означает, ошибку с сервера при запросе saveIdentifier
    case saveIdentifierRequestFailure //= 2012
    
    /// - Данная ошибка означает, ошибку с сервера при запросе fullWifiAccess
    case fullWifiAccessRequestFailure //= 2013
    
    /// - Данная ошибка означает, ошибку с сервера при запросе WiFiSettings
    case getWiFiSettingsRequestFailure //= 2014

    
//    /// Может возникнуть при вызове функций, идущих логически после setup функции (requestConfirmation, confirmCode, trustedLogin, authorize)
//    case confirmationTypeNotSelected
//    /// Невозможно найти данные для подключения к WiFi (не пройден authorize шаг)
//    case cantFindCredentials
//    /// Телефон не может быть найден. Не был вызван requestConfirmation метод, перед методом resend()
//    case phoneNotSelected
//    /// Невозможно найти ViewController для отображения UI SDK
//    case cantFindRootVC
//
//    // Step errors
//    /// SDK не сконфигурирована (appId и appToken не указаны)
//    case needConfigure
//    /// SDK не настроена (метод [setup](x-source-tag://setup) не был вызван)
//    case needSetup
//    /// SDK не прошла авторизацию ([код не подтвержден](x-source-tag://confirmCode) / [trustedLogin](x-source-tag://trustedLogin) не выполнен)
//    case needAuth
    
    
    
    public var errorDescription: String? {
        switch self {
        case .mappingFailure: return "Mapping object data error"
        case .savingData: return "Saving data procces error. An error occurred while caching the configs"
        case .objectDoNotExist: return "Session object is corrupted"
        case .needSwitchOnWiFiModule: return "You should switch on wifi module before connecting"
        case .sessionIsNotConfigured: return "Session is not configured. Please configure session before start"
        case .configsNotSaved: return "No configs in cache memory"
        case .emptyConfigs: return "Empty response configs data"
        case .configHasNoPriority: return "Config has no priority or priority is incorrect"
        case .saveIdentifier: return "Can not find wifi network"
        case .unableToJoinNetwork: return "Unable to Join the Network"
        case .applyConfigError: return "Error during apply config"
        case .saveIdentifierRequestFailure: return "Error during request saveIdentifier"
        case .fullWifiAccessRequestFailure: return "Error during request fullWifiAccess"
        case .getWiFiSettingsRequestFailure: return "Error during request WiFiSettings"

//        case .cantFindCredentials: return "Can't find credentials. Please complete authorize step"
//        case .needConfigure: return "You should configure SDK before using"
//        case .needSetup: return "You should setup SDK to fetch credentials before continue login flow"
//        case .needAuth: return "You should authorize before fetching profile"

        default: return nil
        }
    }
    
}
