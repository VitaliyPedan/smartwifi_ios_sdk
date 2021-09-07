//
//  Constants.swift
//  smartwifi-ios-sdk
//
//  Created by Vitaliy Pedan on 11.08.2021.
//

import Foundation

public enum Result3<T,D,F> {
    case success(T,D,F)
    case failure(Error)
}

public enum EmptyResult {
    case success
    case failure(Error)
}

public func == (lhs: EmptyResult, rhs: EmptyResult) -> Bool {
    switch (lhs, rhs) {
    case (.success, .success):
        return true
    case (.failure, .failure):
        return true
    default: return false
    }
}

public func mainThreadResultCompletion<T>(_ completion: @escaping ResultCompletion<T>) -> ResultCompletion<T> {
    return { result in
        DispatchQueue.main.async {
            completion(result)
        }
    }
}

public typealias ConfigsResultCompletion<T,D,F> = (Result3<T,D,F>) -> Void

public typealias ResultCompletion<T> = (Result<T,Error>) -> Void
public typealias VoidCompletion  = () -> Void
public typealias EmptyCompletion = (EmptyResult) -> Void
public typealias IntHandler = (Int) -> Void
