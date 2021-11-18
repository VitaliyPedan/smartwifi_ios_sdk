//
//  StringExtension.swift
//  smartwifi_ios_sdk
//
//  Created by Vitaliy Pedan on 19.11.2021.
//

import Foundation

extension String {

    var localized: String {
        let lang = Bundle.main.preferredLocalizations.first ?? "en"
        
        guard let path = Bundle.module.path(forResource: lang, ofType: "lproj") else { return self }
        guard let bundle = Bundle(path: path) else { return self }
        
        return NSLocalizedString(self, tableName: "SWFLocalizable", bundle: bundle, value: "", comment: "")
    }

}
