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
enum UserDefaultsError: Error, LocalizedError {
    case encodingError(message: String)
    case decodingError(message: String)
    case notFound
}

/**
 Коллекция ключей для работы с UserDefaultsManager
 */
enum UserDefaultsKey {
    static var allCases: [UserDefaultsKey] {
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
protocol UserDefaultsManagerType {
    func storeEncodable<T: Encodable>(data: T?, key: UserDefaultsKey) throws
    func getDecodable<T: Decodable>(by key: UserDefaultsKey) throws -> T
    
    func store(string: String, key: UserDefaultsKey)
    func getString(by key: UserDefaultsKey) -> String?
    
    func store(int: Int, key: UserDefaultsKey)
    func getInt(by key: UserDefaultsKey) -> Int?
    
    func store(date: Date, key: UserDefaultsKey)
    func getDate(key: UserDefaultsKey) -> Date?
    
    func store(bool: Bool, key: UserDefaultsKey)
    func getBool(by key: UserDefaultsKey) -> Bool
    
    func removeAll(completion: @escaping () -> ())
}

/**
 Класс для работы с UserDefaults по предопреленным ключам
 */
class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let container = UserDefaults.standard
}

// MARK: - UserDefaultsManagerType
extension UserDefaultsManager: UserDefaultsManagerType {
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
    func storeEncodable<T: Encodable>(data: T?, key: UserDefaultsKey) throws {
        do {
            let encodedData = try JSONEncoder().encode(data)
            container.setValue(encodedData, forKey: key.value)
        } catch {
            throw UserDefaultsError.encodingError(message: error.localizedDescription)
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
    func getDecodable<T: Decodable>(by key: UserDefaultsKey) throws -> T {
        guard let data = container.data(forKey: key.value) else {
            throw UserDefaultsError.notFound
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw UserDefaultsError.decodingError(message: error.localizedDescription)
        }
    }
    
    // MARK: - String
    /**
     Сохраняет строку по указонному ключу
     
     - parameters:
        - string: Строка для сохранения по ключу
        - key: Ключ, по которому будет сохранена строка
     */
    func store(string: String, key: UserDefaultsKey) {
        container.set(string, forKey: key.value)
    }
    
    /**
     Получает строку по указонному ключу
     
     - parameters:
        - key: Ключ, по которому будет получена строка
     
     - returns:
        - Строка, хранящаяся по указонному ключу. Возвращает nil, если строка по указанному ключу существует
     */
    func getString(by key: UserDefaultsKey) -> String? {
        container.string(forKey: key.value)
    }
    
    /**
     Сохраняет целое число по указонному ключу
     
     - parameters:
        - string: Число для сохранения по ключу
        - key: Ключ, по которому будет получено число строка
     */
    func store(int: Int, key: UserDefaultsKey) {
        container.set(int, forKey: key.value)
    }
    
    /**
     Получает целове число по указонному ключу
     
     - parameters:
        - key: Ключ, по которому будет получена строка
     
     - returns:
        - Число, хранящееся по указонному ключу. Возвращает nil, если числа по указанному ключу существует
     */
    func getInt(by key: UserDefaultsKey) -> Int? {
        container.integer(forKey: key.value)
    }
    
    func store(date: Date, key: UserDefaultsKey) {
        container.set(date, forKey: key.value)
    }
    
    func getDate(key: UserDefaultsKey) -> Date? {
        container.object(forKey: key.value) as? Date
    }
    
    func store(bool: Bool, key: UserDefaultsKey) {
        container.set(bool, forKey: key.value)
    }
    
    func getBool(by key: UserDefaultsKey) -> Bool {
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
                let _key = UserDefaultsKey.dynamicKey(key)
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
            UserDefaultsKey.allCases.forEach { key in
                self.container.removeObject(forKey: key.value)
            }
            
            completion()
        }
    }

}
