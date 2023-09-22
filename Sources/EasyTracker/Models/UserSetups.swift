//
//  File.swift
//  
//
//  Created by Yevhenii Korsun on 22.09.2023.
//

import Foundation

struct UserSetups: DictionaryConvertable {
    let appBundleId: String
    let appUserId: String
    let idfa: String
    let vendorId: String
    let appVersion: String
    let appstoreId: String
    let iosVersion: String
    let device: String
    let locale: String
    let countryCode: String
}
