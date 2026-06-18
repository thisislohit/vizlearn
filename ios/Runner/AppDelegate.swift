import Flutter
import UIKit
import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

// WiFi Helper class for iOS native WiFi operations
@objc class WifiHelper: NSObject {

    static let shared = WifiHelper()

    override init() {
        super.init()
    }

    // Get current WiFi SSID (if available)
    @objc func getCurrentSSID() -> String? {
        if #available(iOS 14.0, *) {
            // iOS 14+ requires special entitlements and user permission
            // This may return nil even if connected
            return nil
        } else {
            // iOS 13 and below
            guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
                return nil
            }

            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                   let ssid = info[kCNNetworkInfoKeySSID as String] as? String {
                    return ssid
                }
            }
            return nil
        }
    }

    // Check if WiFi is enabled
    @objc func isWifiEnabled() -> Bool {
        // On iOS, we can't directly check WiFi state, but we can try to get SSID
        // If we can't get SSID, it doesn't necessarily mean WiFi is off
        return getCurrentSSID() != nil
    }

    // Connect to WiFi network using NEHotspotConfiguration
    @objc func connectToWiFi(ssid: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        configuration.joinOnce = false // Keep connection after app closes

        NEHotspotConfigurationManager.shared.apply(configuration) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    let errorCode = (error as NSError).code
                    var errorMessage: String

                    switch errorCode {
                    case NEHotspotConfigurationError.alreadyAssociated.rawValue:
                        errorMessage = "Already connected to this network"
                        completion(true, nil) // Already connected is success
                    case NEHotspotConfigurationError.userDenied.rawValue:
                        errorMessage = "User denied the connection request"
                        completion(false, errorMessage)
                    case NEHotspotConfigurationError.invalidSSID.rawValue:
                        errorMessage = "Invalid SSID"
                        completion(false, errorMessage)
                    case NEHotspotConfigurationError.invalidWPAPassphrase.rawValue:
                        errorMessage = "Invalid password"
                        completion(false, errorMessage)
                    case NEHotspotConfigurationError.internal.rawValue:
                        errorMessage = "Internal error occurred"
                        completion(false, errorMessage)
                    default:
                        errorMessage = error.localizedDescription
                        completion(false, errorMessage)
                    }
                } else {
                    // Successfully connected
                    completion(true, nil)
                }
            }
        }
    }

    // Scan for XLZ networks by trying common patterns
    // Returns list of found networks
    @objc func scanForXLZNetworks(password: String, onFound: @escaping (String) -> Void, completion: @escaping ([String], Bool, String?) -> Void) {
        // Generate common XLZ SSID patterns to try (prioritize most common first)
        var patternsToTry: [String] = []

        // Most common patterns first
        patternsToTry.append(contentsOf: [
            "XLZ",
            "XLZ-0000", "XLZ-0001", "XLZ-0002", "XLZ-0003",
            "XLZ-1234", "XLZ-1000", "XLZ-2000", "XLZ-3000"
        ])

        // Then try more numeric patterns (but limit to prevent too many prompts)
        for i in 4..<50 {
            patternsToTry.append(String(format: "XLZ-%04d", i))
        }

        // Additional common patterns
        patternsToTry.append(contentsOf: [
            "XLZ-DEVICE", "XLZ-HOLOGRAM", "XLZ-TEST"
        ])

        var foundNetworks: [String] = []
        var attemptIndex = 0
        let maxAttempts = 30 // Reduced to prevent too many prompts
        var hasConnected = false
        var userCancelled = false

        // First, thoroughly check if already connected to an XLZ network
        func checkCurrentConnection() -> Bool {
            if let currentSSID = getCurrentSSID(),
               currentSSID.uppercased().contains("XLZ") {
                foundNetworks.append(currentSSID)
                onFound(currentSSID)
                completion(foundNetworks, true, currentSSID)
                return true
            }
            return false
        }

        // Check current connection first
        if checkCurrentConnection() {
            return
        }

        func tryNextPattern() {
            // Before trying next, check if we're now connected (user might have connected manually)
            if checkCurrentConnection() {
                return
            }

            guard attemptIndex < patternsToTry.count && attemptIndex < maxAttempts && !userCancelled else {
                // Final check - maybe user connected manually while we were trying
                if let currentSSID = getCurrentSSID(),
                   currentSSID.uppercased().contains("XLZ") {
                    foundNetworks.append(currentSSID)
                    onFound(currentSSID)
                    completion(foundNetworks, true, currentSSID)
                    return
                }

                if foundNetworks.isEmpty {
                    completion([], false, "Could not find any XLZ network. Make sure the device is powered on and broadcasting WiFi. You can also connect manually in iOS Settings.")
                } else {
                    // Found networks but didn't connect - return them anyway
                    completion(foundNetworks, false, "Found networks but connection failed. Try connecting to \(foundNetworks.first ?? "network") manually in Settings.")
                }
                return
            }

            let ssid = patternsToTry[attemptIndex]
            attemptIndex += 1

            // Try to connect to this SSID
            let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
            configuration.joinOnce = false

            NEHotspotConfigurationManager.shared.apply(configuration) { [weak self] error in
                DispatchQueue.main.async {
                    // Check if we're now connected (even if there was an error)
                    if let currentSSID = self?.getCurrentSSID(),
                       currentSSID.uppercased().contains("XLZ") {
                        if !foundNetworks.contains(currentSSID) {
                            foundNetworks.append(currentSSID)
                            onFound(currentSSID)
                        }
                        if !hasConnected {
                            hasConnected = true
                            completion(foundNetworks, true, currentSSID)
                            return
                        }
                    }

                    if let error = error {
                        let errorCode = (error as NSError).code

                        // If already associated, this network exists!
                        if errorCode == NEHotspotConfigurationError.alreadyAssociated.rawValue {
                            if !foundNetworks.contains(ssid) {
                                foundNetworks.append(ssid)
                                onFound(ssid)
                            }
                            if !hasConnected {
                                hasConnected = true
                                completion(foundNetworks, true, ssid)
                                return
                            }
                        }

                        // If user denied, stop trying (user cancelled)
                        if errorCode == NEHotspotConfigurationError.userDenied.rawValue {
                            userCancelled = true
                            completion(foundNetworks, false, "Connection cancelled. Please approve the WiFi connection prompt or connect manually in Settings.")
                            return
                        }

                        // For invalid SSID or network not found, try next quickly
                        // For wrong password, also try next (might be different network)
                        // Add small delay to avoid overwhelming the system
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            tryNextPattern()
                        }
                    } else {
                        // Successfully connected!
                        if !foundNetworks.contains(ssid) {
                            foundNetworks.append(ssid)
                            onFound(ssid)
                        }
                        if !hasConnected {
                            hasConnected = true
                            // Wait a moment to verify connection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                // Double-check we're still connected
                                if let currentSSID = self?.getCurrentSSID(),
                                   currentSSID.uppercased().contains("XLZ") {
                                    completion(foundNetworks, true, currentSSID)
                                } else {
                                    completion(foundNetworks, true, ssid)
                                }
                            }
                            return
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                tryNextPattern()
                            }
                        }
                    }
                }
            }
        }

        // Start with a small delay to let system settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tryNextPattern()
        }
    }

    // Try to connect to XLZ networks (common patterns) - simplified version
    @objc func scanAndConnectToXLZNetworks(password: String, completion: @escaping (Bool, String?) -> Void) {
        var foundSSID: String?
        var connectionSuccess = false

        scanForXLZNetworks(password: password, onFound: { ssid in
            foundSSID = ssid
        }) { foundNetworks, connected, errorMessage in
            if connected, let ssid = foundSSID {
                completion(true, ssid)
            } else if !foundNetworks.isEmpty {
                // Found networks but connection didn't complete
                completion(true, foundNetworks.first)
            } else {
                completion(false, errorMessage)
            }
        }
    }

    // Remove WiFi configuration
    // Note: iOS doesn't allow programmatic removal of WiFi configurations
    // Users must remove them manually in Settings
    @objc func removeWiFiConfiguration(ssid: String, completion: @escaping (Bool) -> Void) {
        // iOS doesn't support removing WiFi configurations programmatically
        // Return true to indicate "handled" (even though nothing happens)
        DispatchQueue.main.async {
            completion(true)
        }
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // Register WiFi helper platform channel
    let wifiChannel = FlutterMethodChannel(
      name: "com.vizlearn.wifi_helper",
      binaryMessenger: controller.binaryMessenger
    )

    wifiChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      let wifiHelper = WifiHelper.shared

      switch call.method {
      case "getCurrentSSID":
        if let ssid = wifiHelper.getCurrentSSID() {
          result(ssid)
        } else {
          result(nil)
        }

      case "isWifiEnabled":
        result(wifiHelper.isWifiEnabled())

      case "connectToWiFi":
        guard let args = call.arguments as? [String: Any],
              let ssid = args["ssid"] as? String,
              let password = args["password"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing ssid or password", details: nil))
          return
        }

        wifiHelper.connectToWiFi(ssid: ssid, password: password) { success, error in
          if success {
            result(["success": true, "ssid": ssid])
          } else {
            result(FlutterError(code: "CONNECTION_FAILED", message: error ?? "Unknown error", details: nil))
          }
        }

      case "scanForXLZNetworks":
        guard let args = call.arguments as? [String: Any],
              let password = args["password"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing password", details: nil))
          return
        }

        wifiHelper.scanForXLZNetworks(password: password, onFound: { ssid in
          // Network found - this callback is called for each found network
          // We'll collect them in the completion handler
        }) { foundNetworks, connected, errorMessage in
          if connected, let connectedSSID = foundNetworks.first {
            result(["success": true, "ssid": connectedSSID, "foundNetworks": foundNetworks])
          } else if !foundNetworks.isEmpty {
            result(["success": false, "ssid": foundNetworks.first ?? "", "foundNetworks": foundNetworks, "message": errorMessage ?? ""])
          } else {
            result(FlutterError(code: "CONNECTION_FAILED", message: errorMessage ?? "Could not find XLZ networks", details: nil))
          }
        }

      case "scanAndConnectToXLZNetworks":
        guard let args = call.arguments as? [String: Any],
              let password = args["password"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing password", details: nil))
          return
        }

        wifiHelper.scanAndConnectToXLZNetworks(password: password) { success, ssid in
          if success {
            result(["success": true, "ssid": ssid ?? ""])
          } else {
            result(FlutterError(code: "CONNECTION_FAILED", message: ssid ?? "Could not connect", details: nil))
          }
        }

      case "removeWiFiConfiguration":
        guard let args = call.arguments as? [String: Any],
              let ssid = args["ssid"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing ssid", details: nil))
          return
        }

        wifiHelper.removeWiFiConfiguration(ssid: ssid) { success in
          result(success)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}