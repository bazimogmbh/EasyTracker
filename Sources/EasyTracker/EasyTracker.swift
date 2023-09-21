import Foundation
import AppTrackingTransparency
import AdSupport
import Network
import StoreKit
import SwiftyStoreKit

#if canImport(UIKit)
import UIKit

protocol TrackServiceProtocol {
    static func configure()
    static func trackPurchase(of product: SKProduct, with orderId: String?)
    static func updatePurchases(of products: Set<SKProduct>, completion: @escaping () -> [Purchase])
}

enum DefaultsKey: String {
    case userId
    case isFirstRun
}

public enum EasyTracker: TrackServiceProtocol {
    enum TrackingKey: String {
        case userId, idfa, vendorID, appName, appVersion, appBuild, appLocale, country, iosVersion, device, bundleId, trackVersion
        case price, currency, productId, receipt, orderId
    }
    
    enum TrackerEndpoint: String {
        case configure, trackPurchase, trackAllPurchases
    }
    
    private static var userId: String = ""
    private static var idfa: String = ""
    private static var vendorID: String = ""
    
    private static let trackVersion = "0.0.18"

    public static func configure() {
        setupUserId()
        
        let observerToken = NotificationCenter.default.addObserver(
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

            let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? ""
            self.vendorID = vendorID

            let bundleId = Bundle.main.bundleIdentifier ?? ""
            let appBuild = Bundle.main.appBuild
            let appVersion = Bundle.main.appVersion
            let device = UIDevice.current.modelName
            let iosVersion = UIDevice.current.systemVersion

            let locale = Locale.current
            let appLocale = locale.identifier
            let enLocale = Locale(identifier: "en_US")
            var country: String = locale.countryInEnglish

            let data: [String: String] = [
                TrackingKey.bundleId.rawValue: bundleId,
                TrackingKey.userId.rawValue: self.userId,
                TrackingKey.idfa.rawValue: idfa,
                TrackingKey.vendorID.rawValue: vendorID,
                TrackingKey.appVersion.rawValue: appVersion,
                TrackingKey.appBuild.rawValue: appBuild,
                TrackingKey.iosVersion.rawValue: iosVersion,
                TrackingKey.device.rawValue: device,
                TrackingKey.appLocale.rawValue: appLocale,
                TrackingKey.country.rawValue: country,
                TrackingKey.trackVersion.rawValue: trackVersion,
            ]

            send(data, to: .configure)
        }
    }

    public static func trackPurchase(of product: SKProduct, with orderId: String?) {
        var receipt = ""
        
        if let url = Bundle.main.appStoreReceiptURL,
           let data = try? Data(contentsOf: url) {
            receipt = data.base64EncodedString()
  
        }

        let data: [String: String] = [
            TrackingKey.userId.rawValue: self.userId,
            TrackingKey.productId.rawValue: product.productIdentifier,
            TrackingKey.price.rawValue: product.price.stringValue,
            TrackingKey.currency.rawValue: product.priceLocale.currencyCode ?? "",
            TrackingKey.receipt.rawValue: receipt,
            TrackingKey.orderId.rawValue: orderId ?? "",
        ]
        
        send(data, to: .trackPurchase)
    }
    
    public static func updatePurchases(of products: Set<SKProduct>, completion: @escaping () -> [Purchase]) {
        let isFirstRun: Bool = getFromDefaults(.isFirstRun) ?? true
        
        //        if isFirstRun {
        print("!@ANALITIC Old Purchases start")
        completion { results in
            saveInDefaults(false, by: .isFirstRun)
            print("!@ANALITIC Old Purchases \(results.restoredPurchases)")
        }
        //        }
    }
}

// MARK: - Helpers

extension EasyTracker {
    static private func send(_ dictionary: [String: String], to endpoint: TrackerEndpoint) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
           let string = String(data: jsonData, encoding: .utf8) {
            print("ANALITIC \(endpoint.rawValue):\n\(string)")
        }
    }
    
    static private func setupUserId() {
        if let userId: String = getFromDefaults(.userId) {
            self.userId = userId
        } else {
            self.userId = "\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
            self.saveInDefaults(self.userId, by: .userId)
        }
    }

    static private func saveInDefaults(_ value: Any?, by key: DefaultsKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    static private func getFromDefaults<T>(_ key: DefaultsKey) -> T? {
        return UserDefaults.standard.value(forKey: key.rawValue) as? T
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
    var countryInEnglish: String {
        let countryCode = {
            if #available(iOS 16, *) {
                return self.language.region?.identifier
            } else {
                return self.regionCode
            }
        }()
        
        if let countryCode,
           let countryString = Locale(identifier: "en_US").localizedString(forRegionCode: countryCode) {
            return countryString
        }
        
        return ""
    }
}

#endif
