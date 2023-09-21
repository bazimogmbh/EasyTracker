import Foundation
import AppTrackingTransparency
import AdSupport
import Network
import StoreKit
import SwiftyStoreKit

#if canImport(UIKit)
import UIKit

protocol TrackServiceProtocol {
    static func configure(with appstoreId: String)
    static func trackPurchase(_ details: PurchaseDetails)
    static func updatePurchases(of products: Set<SKProduct>)
}

enum DefaultsKey: String {
    case appUserId
    case isFirstRun
}

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

struct PurchaseDetail: DictionaryConvertable {
    let appUserId: String
    let productId: String
    let transactionId: String
    let token: String
    let priceInPurchasedCurrency: String
    let currency: String
    let purchasedAtMs: String
    let expirationAtMs: String
    let environment: String
    let type: String
}

struct AllPurchaseDetail: DictionaryConvertable {
    let purchases: [PurchaseDetail]
}

public enum EasyTracker: TrackServiceProtocol {
    enum TrackerEndpoint: String {
        case configure, trackPurchase, trackAllPurchases
    }
    
    private static let appUserId: String = getUserId()
    private static var idfa: String = ""
    private static var vendorId: String = ""

    public static func configure(with appstoreId: String) {
       NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil
        ) { _ in
            ATTrackingManager.requestTrackingAuthorization { status in
                sendData()
            }
        }

        func sendData() {
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            self.idfa = idfa

            let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? ""
            self.vendorId = vendorId

            let appBundleId = Bundle.main.bundleIdentifier ?? ""
            let appVersion = Bundle.main.appVersion
            let device = UIDevice.current.modelName
            let iosVersion = UIDevice.current.systemVersion

            let locale = Locale.current.identifier
            let countryCode: String = Locale.current.countryCode
            
            let userSetups = UserSetups(appBundleId: appBundleId,
                                        appUserId: self.appUserId,
                                        idfa: idfa,
                                        vendorId: vendorId,
                                        appVersion: appVersion,
                                        appstoreId: appstoreId,
                                        iosVersion: iosVersion,
                                        device: device,
                                        locale: locale,
                                        countryCode: countryCode
            )

            send(userSetups, to: .configure)
        }
    }

    public static func trackPurchase(_ details: PurchaseDetails) {
        var token = ""
        
        if let url = Bundle.main.appStoreReceiptURL,
           let data = try? Data(contentsOf: url) {
            token = data.base64EncodedString()
  
        }
        
        let productId = details.product.productIdentifier
        let transactionId = details.transaction.transactionIdentifier ?? ""
        let priceInPurchasedCurrency = details.product.price.stringValue
        let currency = details.product.priceLocale.currencyCode ?? ""
        let purchasedAtMs = String(details.originalPurchaseDate.milliseconds)
        let expirationAtMs = String(details.originalPurchaseDate.milliseconds + (details.product.subscriptionPeriod?.milliseconds ?? 0))
        let environment = "NOT SET"
        let type = "NOT SET"
        
        let purchaseDetail = PurchaseDetail(appUserId: self.appUserId,
                       productId: productId,
                       transactionId: transactionId,
                       token: token,
                       priceInPurchasedCurrency: priceInPurchasedCurrency,
                       currency: currency,
                       purchasedAtMs: purchasedAtMs,
                       expirationAtMs: expirationAtMs,
                       environment: environment,
                       type: type
        )

        send(purchaseDetail, to: .trackPurchase)
    }
    
    public static func updatePurchases(of products: Set<SKProduct>) {
        let isFirstRun: Bool = getFromDefaults(.isFirstRun) ?? true
        print("!@ANALITIC Old Purchases prepeare: \(isFirstRun)")
//        if isFirstRun {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { // need to restorePurchases work correct
                print("!@ANALITIC Old Purchases start")
                
                SwiftyStoreKit.restorePurchases { results in
                    saveInDefaults(false, by: .isFirstRun)
                    print("!@ANALITIC Old Purchases \(results.restoredPurchases)")
                    
                    let allPurchaseDetail = AllPurchaseDetail(purchases: results.restoredPurchases.map { purchase in
                        let product = product(by: purchase.productId)
                        
                        return PurchaseDetail(appUserId: self.appUserId,
                                              productId: purchase.productId,
                                              transactionId: purchase.originalTransaction?.transactionIdentifier ?? "",
                                              token: "NOT SET",
                                              priceInPurchasedCurrency: product?.price.stringValue ?? "",
                                              currency: product?.priceLocale.currencyCode ?? "",
                                              purchasedAtMs: String(purchase.originalPurchaseDate.milliseconds),
                                              expirationAtMs: String(purchase.originalPurchaseDate.milliseconds + ( product?.subscriptionPeriod?.milliseconds ?? 0)),
                                              environment: "NOT SET",
                                              type: "NOT SET"
                        )
                    }
                    )
                    
                    send(allPurchaseDetail, to: .trackAllPurchases)
                }
            }
//        }
        
        func product(by productId: String) -> SKProduct? {
            products.first(where: { $0.productIdentifier == productId })
        }
    }
}

// MARK: - Helpers

extension EasyTracker {
    static private func send<T: DictionaryConvertable>(_ data: T, to endpoint: TrackerEndpoint) {
        let dictionary = data.toDictionary()
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
           let string = String(data: jsonData, encoding: .utf8) {

            print("ANALITIC \(endpoint.rawValue):\n\(string.utf8)")
        }
    }
    
    static private func getUserId() -> String {
        if let appUserId: String = getFromDefaults(.appUserId) {
           return appUserId
        } else {
            let appUserId = "\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
            self.saveInDefaults(appUserId, by: .appUserId)
            self.saveInDefaults(true, by: .isFirstRun)
            return appUserId
        }
    }

    static private func saveInDefaults(_ value: Any?, by key: DefaultsKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static private func getFromDefaults<T>(_ key: DefaultsKey) -> T? {
        return UserDefaults.standard.value(forKey: key.rawValue) as? T
    }
}

fileprivate extension Date {
    var milliseconds: Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
}

fileprivate extension SKProductSubscriptionPeriod {
    var milliseconds: Int64 {
        let milisecondsInDay: Double = 24 * 60 * 60 * 1000
        var result: Double = 0
        
        switch self.unit {
        case .day:
            result = TimeInterval(self.numberOfUnits) * milisecondsInDay
        case .week:
            result = TimeInterval(self.numberOfUnits) * 7 * milisecondsInDay
        case .month:
            result = TimeInterval(self.numberOfUnits) * 30 * milisecondsInDay
        case .year:
            result = TimeInterval(self.numberOfUnits) * 365 * milisecondsInDay
        @unknown default:
            result = 0
        }
        
        return Int64(result)
    }
}

fileprivate extension UIDevice {
    var modelName: String {
#if targetEnvironment(simulator)
        let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]!
#else
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
#endif
        return identifier
    }
}

fileprivate extension Bundle {
    var displayName: String {
        object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Could not determine the application name"
    }

    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Could not determine the application build number"
    }

    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Could not determine the application version"
    }
}

fileprivate extension Locale {
    var countryCode: String {
        if #available(iOS 16, *) {
            return self.language.region?.identifier ?? ""
        } else {
            return self.regionCode  ?? ""
        }
    }
}

#endif

protocol DictionaryConvertable: DictionaryDecodable {
    func toDictionary() -> [String: Any]
}

protocol DictionaryDecodable: Decodable {
    static func decode(from dictionary: [AnyHashable: Any]) throws -> Self
}

extension DictionaryDecodable {
    static func decode(from dictionary: [AnyHashable: Any]) throws -> Self {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let decoder = JSONDecoder()
        let object = try decoder.decode(Self.self, from: jsonData)
        return object
    }
}

protocol EnumConvertable {
    init?(rawValue: String)
    var rawValue: String { get }
}

extension DictionaryConvertable {
    func toDictionary() -> [String: Any] {
        let reflect = Mirror(reflecting: self)
        let children = reflect.children
        let dictionary = toAnyHashable(elements: children)
        return dictionary
    }
    
    func toAnyHashable(elements: AnyCollection<Mirror.Child>) -> [String : Any] {
        var dictionary: [String : Any] = [:]
        for element in elements {
            if let camelCaseKey = element.label {
               let key = convertCamelCaseToSnakeCase(camelCaseKey)

                if let collectionValidHashable = element.value as? [AnyHashable] {
                    dictionary[key] = collectionValidHashable
                }
                
                if let validHashable = element.value as? AnyHashable {
                    dictionary[key] = validHashable
                }
                
                if let convertor = element.value as? DictionaryConvertable {
                    dictionary[key] = convertor.toDictionary()
                }
                
                if let convertorList = element.value as? [DictionaryConvertable] {
                    dictionary[key] = convertorList.map({ e in
                       return e.toDictionary()
                    })
                }
                
                if let validEnum = element.value as? EnumConvertable {
                    dictionary[key] = validEnum.rawValue
                }
            }
        }
        return dictionary
        
        func convertCamelCaseToSnakeCase(_ input: String) -> String {
            return input.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1_$2", options: .regularExpression, range: nil).lowercased()
        }
    }
}
