//
//  UserDefaultsManager.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import Foundation

/**
 Коллекция ошибок при работе с UserDefaultsManager
 */
enum SWFUserDefaultsError: Error, LocalizedError {
    case encodingError(message: String)
    case decodingError(message: String)
    case notFound
}

/**
 Коллекция ключей для работы с UserDefaultsManager
 */
enum SWFUserDefaultsKey {
    static var allCases: [SWFUserDefaultsKey] {
        return [
            .userId,
            .host,
            .passpointConfiguration,
            .wap2EnterpriseConfiguration,
            .wap2Configuration,
            .dynamicKey("")]
    }
    
    case userId
    case host
    
    case passpointConfiguration
    case wap2EnterpriseConfiguration
    case wap2Configuration
    
    case dynamicKey(String)
    
    var value: String {
        switch self {
        case .userId:
            return "userId"
        case .host:
            return "host"
        case .passpointConfiguration:
            return "passpointConfiguration"
        case .wap2EnterpriseConfiguration:
            return "wap2EnterpriseConfiguration"
        case .wap2Configuration:
            return "wap2Configuration"
            
        case .dynamicKey(let dynamicKey):
            return dynamicKey
        }
    }
}

/**
 Протокол, описывающий класс для работы с UserDefaults по предопреленным ключам
 */
protocol SWFUserDefaultsManagerType {
    func storeEncodable<T: Encodable>(data: T?, key: SWFUserDefaultsKey) throws
    func getDecodable<T: Decodable>(by key: SWFUserDefaultsKey) throws -> T
    
    func store(string: String, key: SWFUserDefaultsKey)
    func getString(by key: SWFUserDefaultsKey) -> String?
    
    func store(int: Int, key: SWFUserDefaultsKey)
    func getInt(by key: SWFUserDefaultsKey) -> Int?
    
    func store(date: Date, key: SWFUserDefaultsKey)
    func getDate(key: SWFUserDefaultsKey) -> Date?
    
    func store(bool: Bool, key: SWFUserDefaultsKey)
    func getBool(by key: SWFUserDefaultsKey) -> Bool
    
    func removeAll(completion: @escaping () -> ())
}

/**
 Класс для работы с UserDefaults по предопреленным ключам
 */
class SWFUserDefaultsManager {
    static let shared = SWFUserDefaultsManager()
    
    private let container = UserDefaults.standard
}

// MARK: - UserDefaultsManagerType
extension SWFUserDefaultsManager: SWFUserDefaultsManagerType {
    // MARK: - Codable
    /**
     Сохраняет Encodable модель в UserDefaults по указонному ключу.
     
     - throws:
     Ошибка типа 'UserDefaultsError'
     
     - parameters:
        - model: Модель для сохранения в UserDefaults.
        - key: Ключ, по которому будет сохранена модель
     
     - Important
        Выполняется синхронно
    */
    func storeEncodable<T: Encodable>(data: T?, key: SWFUserDefaultsKey) throws {
        do {
            let encodedData = try JSONEncoder().encode(data)
            container.setValue(encodedData, forKey: key.value)
        } catch {
            throw SWFUserDefaultsError.encodingError(message: error.localizedDescription)
        }
    }
    
    /**
     Получает Decodable модель из UserDefaults по указанному ключу.
     
     - throws:
     Ошибка типа 'UserDefaultsError'
     
     - parameters:
        - key: Ключ, по которому будет запрашиваться модель
     
     - returns:
        - Generic тип, который описывает к кокому типу приводить Data, хранящуюся указанному по ключу
     
     - Important:
        Выполняется синхронно
    */
    func getDecodable<T: Decodable>(by key: SWFUserDefaultsKey) throws -> T {
        guard let data = container.data(forKey: key.value) else {
            throw SWFUserDefaultsError.notFound
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw SWFUserDefaultsError.decodingError(message: error.localizedDescription)
        }
    }
    
    // MARK: - String
    /**
     Сохраняет строку по указонному ключу
     
     - parameters:
        - string: Строка для сохранения по ключу
        - key: Ключ, по которому будет сохранена строка
     */
    func store(string: String, key: SWFUserDefaultsKey) {
        container.set(string, forKey: key.value)
    }
    
    /**
     Получает строку по указонному ключу
     
     - parameters:
        - key: Ключ, по которому будет получена строка
     
     - returns:
        - Строка, хранящаяся по указонному ключу. Возвращает nil, если строка по указанному ключу существует
     */
    func getString(by key: SWFUserDefaultsKey) -> String? {
        container.string(forKey: key.value)
    }
    
    /**
     Сохраняет целое число по указонному ключу
     
     - parameters:
        - string: Число для сохранения по ключу
        - key: Ключ, по которому будет получено число строка
     */
    func store(int: Int, key: SWFUserDefaultsKey) {
        container.set(int, forKey: key.value)
    }
    
    /**
     Получает целове число по указонному ключу
     
     - parameters:
        - key: Ключ, по которому будет получена строка
     
     - returns:
        - Число, хранящееся по указонному ключу. Возвращает nil, если числа по указанному ключу существует
     */
    func getInt(by key: SWFUserDefaultsKey) -> Int? {
        container.integer(forKey: key.value)
    }
    
    func store(date: Date, key: SWFUserDefaultsKey) {
        container.set(date, forKey: key.value)
    }
    
    func getDate(key: SWFUserDefaultsKey) -> Date? {
        container.object(forKey: key.value) as? Date
    }
    
    func store(bool: Bool, key: SWFUserDefaultsKey) {
        container.set(bool, forKey: key.value)
    }
    
    func getBool(by key: SWFUserDefaultsKey) -> Bool {
        container.bool(forKey: key.value)
    }
    
    /**
    Удаляет  значения по динамическому ключу
     
     - parameters:
        - completion: @escaping замыкание, которое выполнится после очистки базы
        - key: ключ по которому будет удалено значение
     
     - Important: Выполняется асинхронно
     */
    func removeValues(by keys: [String], completion: @escaping () -> ()) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            keys.forEach { key in
                let _key = SWFUserDefaultsKey.dynamicKey(key)
                self.container.removeObject(forKey: _key.value)
            }
            
            completion()
        }
    }
    
    /**
    Удаляет все значения по всем ключам кроме динамических
     
     - parameters:
        - completion: @escaping замыкание, которое выполнится после очистки базы
     
     - Important: Выполняется асинхронно
     */
    func removeAll(completion: @escaping () -> ()) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            SWFUserDefaultsKey.allCases.forEach { key in
                self.container.removeObject(forKey: key.value)
            }
            
            completion()
        }
    }

}
