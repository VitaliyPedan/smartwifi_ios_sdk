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
enum UserDefaultsKey: String, CaseIterable {
    case properties
    case confirmationType
    case configurationDate
    case userId
    
    case host
    case basePath
    
    case state
    case configurationType
    
    case passpointConfiguration
    case wap2EnterpriseConfiguration
    case wap2Configuration
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
            container.setValue(encodedData, forKey: key.rawValue)
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
        guard let data = container.data(forKey: key.rawValue) else {
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
        container.set(string, forKey: key.rawValue)
    }
    
    /**
     Получает строку по указонному ключу
     
     - parameters:
        - key: Ключ, по которому будет получена строка
     
     - returns:
        - Строка, хранящаяся по указонному ключу. Возвращает nil, если строка по указанному ключу существует
     */
    func getString(by key: UserDefaultsKey) -> String? {
        container.string(forKey: key.rawValue)
    }
    
    /**
     Сохраняет целое число по указонному ключу
     
     - parameters:
        - string: Число для сохранения по ключу
        - key: Ключ, по которому будет получено число строка
     */
    func store(int: Int, key: UserDefaultsKey) {
        container.set(int, forKey: key.rawValue)
    }
    
    /**
     Получает целове число по указонному ключу
     
     - parameters:
        - key: Ключ, по которому будет получена строка
     
     - returns:
        - Число, хранящееся по указонному ключу. Возвращает nil, если числа по указанному ключу существует
     */
    func getInt(by key: UserDefaultsKey) -> Int? {
        container.integer(forKey: key.rawValue)
    }
    
    func store(date: Date, key: UserDefaultsKey) {
        container.set(date, forKey: key.rawValue)
    }
    
    func getDate(key: UserDefaultsKey) -> Date? {
        container.object(forKey: key.rawValue) as? Date
    }
    
    func store(bool: Bool, key: UserDefaultsKey) {
        container.set(bool, forKey: key.rawValue)
    }
    
    func getBool(by key: UserDefaultsKey) -> Bool {
        container.bool(forKey: key.rawValue)
    }
    
    /**
    Удаляет все значения по всем ключам
     
     - parameters:
        - completion: @escaping замыкание, которое выполнится после очистки базы
     
     - Important: Выполняется асинхронно
     */
    func removeAll(completion: @escaping () -> ()) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            UserDefaultsKey.allCases.forEach { key in
                if key != .configurationType {
                    self.container.removeObject(forKey: key.rawValue)
                }
            }
            
            completion()
        }
    }
}
