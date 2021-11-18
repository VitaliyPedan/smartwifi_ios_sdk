//
//  BundleExtension.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 19.11.2021.
//

import Foundation

extension Bundle {

    static var module: Bundle {
        let bundle = Bundle(for: SWFWiFiSession.self)
        
        guard let path = bundle.resourcePath else { return .main }
        return Bundle(path: path.appending("/smartwifi_ios_sdk.bundle")) ?? .main
    }

}
