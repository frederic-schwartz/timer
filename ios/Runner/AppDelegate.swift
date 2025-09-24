import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let icloudChannelName = "com.online404.timer/icloud_backup"
  private let icloudContainerIdentifier = "iCloud.com.online404.timer"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: icloudChannelName, binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }

        switch call.method {
        case "saveBackup":
          guard
            let arguments = call.arguments as? [String: Any],
            let data = arguments["data"] as? String
          else {
            result(FlutterError(code: "invalid_args", message: "Payload manquant pour la sauvegarde iCloud", details: nil))
            return
          }
          self.saveBackupToICloud(data: data, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveBackupToICloud(data: String, result: FlutterResult) {
    guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: icloudContainerIdentifier) else {
      result(FlutterError(code: "no_container", message: "Impossible d\'accéder au conteneur iCloud.", details: nil))
      return
    }

    let documentsURL = containerURL.appendingPathComponent("Documents")

    do {
      try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)

      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
      formatter.timeZone = TimeZone(secondsFromGMT: 0)

      let timestamp = formatter.string(from: Date())
      let backupURL = documentsURL.appendingPathComponent("timer_backup_\(timestamp).json")
      let latestURL = documentsURL.appendingPathComponent("timer_backup_latest.json")

      try data.write(to: backupURL, atomically: true, encoding: .utf8)
      try data.write(to: latestURL, atomically: true, encoding: .utf8)

      result(nil)
    } catch {
      result(FlutterError(code: "write_error", message: error.localizedDescription, details: nil))
    }
  }
}
