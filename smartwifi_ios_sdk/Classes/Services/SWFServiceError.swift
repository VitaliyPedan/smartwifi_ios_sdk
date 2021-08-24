//
//  SWFServiceError.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 24.08.2021.
//

import Foundation

/**
 Описывает возможные ошибки при работе с SWFService
 */
/// - Tag: WiFiConfiguratorError
public enum SWFServiceError: Error, LocalizedError {
    /// Может возникнуть при вызове функций, идущих логически после setup функции (requestConfirmation, confirmCode, trustedLogin, authorize)
    case confirmationTypeNotSelected
    /// Невозможно найти данные для подключения к WiFi (не пройден authorize шаг)
    case cantFindCredentials
    /// Телефон не может быть найден. Не был вызван requestConfirmation метод, перед методом resend()
    case phoneNotSelected
    /// Невозможно найти ViewController для отображения UI SDK
    case cantFindRootVC
    
    // Step errors
    /// SDK не сконфигурирована (appId и appToken не указаны)
    case needConfigure
    /// SDK не настроена (метод [setup](x-source-tag://setup) не был вызван)
    case needSetup
    /// SDK не прошла авторизацию ([код не подтвержден](x-source-tag://confirmCode) / [trustedLogin](x-source-tag://trustedLogin) не выполнен)
    case needAuth
    
    /// Необходимо перейти в настройки системы и включить wifi модуль
    case needCheckOnWiFiModule

    public var errorDescription: String? {
        switch self {
        case .cantFindCredentials: return "Can't find credentials. Please complete authorize step"
        case .needConfigure: return "You should configure SDK before using"
        case .needSetup: return "You should setup SDK to fetch credentials before continue login flow"
        case .needAuth: return "You should authorize before fetching profile"
        case .needCheckOnWiFiModule: return "You should check on wifi module before connecting"
        default: return nil
        }
    }
}
