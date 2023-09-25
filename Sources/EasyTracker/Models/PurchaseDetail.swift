//
//  File.swift
//  
//
//  Created by Yevhenii Korsun on 22.09.2023.
//

import Foundation

struct PurchaseDetail: DictionaryConvertable {
    let appBundleId: String?
    let appUserId: String?
    let productId: String?
    let transactionId: String?
    let token: String?
    let priceInPurchasedCurrency: String?
    let currency: String?
    let purchasedAtMs: String?
    let expirationAtMs: String?
    let withTrial: Bool?
}

struct AllPurchaseDetail: DictionaryConvertable {
    let purchases: [PurchaseDetail]
}
