//
//  SecuredStorageManager.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import Foundation

enum SecuredStorageError: Error {
    case cantBeConveted
}

enum SecuredStorageKey: String, CaseIterable {
    case appToken
    case appId
    case identity
    case presetPhone
    
    case credentials
    case authorizationInfo
    
    static var removableKeys: [SecuredStorageKey] {
        [.credentials, .authorizationInfo, .identity]
    }
}

protocol SecuredStorageManagerType {
    @discardableResult
    func save(key: SecuredStorageKey, data: Data) -> OSStatus
    @discardableResult
    func save<T: Encodable>(key: SecuredStorageKey, encodable: T) throws -> OSStatus
    
    func load(key: SecuredStorageKey) -> Data?
    func loadDecodable<T: Decodable>(key: SecuredStorageKey) -> T?
    
    func removeAll(completion: @escaping () -> ())
}

class SecuredStorageManager: SecuredStorageManagerType {
    static let shared = SecuredStorageManager()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    @discardableResult
    func save<T: Encodable>(key: SecuredStorageKey, encodable: T) throws -> OSStatus {
        let data = try encoder.encode(encodable)
        return save(key: key, data: data)
    }
    
    @discardableResult
    func save(key: SecuredStorageKey, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key.rawValue,
            kSecValueData as String   : data
        ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }

    func load(key: SecuredStorageKey) -> Data? {
        var dataTypeRef: AnyObject? = nil
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key.rawValue,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ] as [String : Any]
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    
    func loadDecodable<T: Decodable>(key: SecuredStorageKey) -> T? {
        guard let data = load(key: key) else { return nil }
        
        return try? decoder.decode(T.self, from: data)
    }
    
    func removeAll(completion: @escaping () -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            SecuredStorageKey.removableKeys.forEach { key in
                let query = [
                    kSecClass as String : kSecClassGenericPassword,
                    kSecAttrAccount as String : key.rawValue
                ] as [String : Any]
                
                SecItemDelete(query as CFDictionary)
            }
            
            completion()
        }
    }

    func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)

        let swiftString: String = cfStr as String
        return swiftString
    }
}
