//
//  SWFServerError.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 07.02.2022.
//

import Foundation

public struct SWFServerError: Codable {
    let detail: String
    let status: Int
    let title: String
}
