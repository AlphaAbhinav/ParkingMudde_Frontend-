import Flutter
import UIKit
import PushKit
import CallKit
import AVFoundation
import WebRTC
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var calls: ParkingMuddeCalls?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
   
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "ParkingMuddeCalls") {
      calls = ParkingMuddeCalls(messenger: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter,
      didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    if calls?.handleAlertAction(response, completion: completionHandler) == true { return }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}

// Kept in this existing target source so no manual Xcode source-file step is needed.
final class ParkingMuddeCalls: NSObject, PKPushRegistryDelegate, CXProviderDelegate {
  private let channel: FlutterMethodChannel
  private let provider: CXProvider
  private var registry: PKPushRegistry!
  private var callData: [String: Any]?
  private var callUUID: UUID?
  private var answerAction: CXAnswerCallAction?
  private var answered = false
  private var flutterReady = false
  private var pendingAnswer: [String: Any]?
  private var pollTimer: Timer?
  private var answerTimer: Timer?
  private var polling = false
  private var token: String?
  private let defaults = UserDefaults.standard

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.parkingmudde.app/calls", binaryMessenger: messenger)
    let configuration = CXProviderConfiguration(localizedName: "Parking Mudde")
    configuration.supportsVideo = false
    configuration.maximumCallGroups = 1
    configuration.maximumCallsPerCallGroup = 1
    configuration.supportedHandleTypes = [.generic]
    configuration.includesCallsInRecents = false
    provider = CXProvider(configuration: configuration)
    super.init()
    provider.setDelegate(self, queue: .main)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      let arguments = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "configure":
        if let backend = arguments["backend_url"] as? String,
           let url = URL(string: backend), url.scheme == "https" {
          self.defaults.set(backend.trimmingCharacters(in: CharacterSet(charactersIn: "/")), forKey: "calls_backend")
        }
        self.defaults.set(arguments["enabled"] as? Bool ?? false, forKey: "calls_enabled")
        self.flutterReady = true
        if let pending = self.pendingAnswer {
          self.pendingAnswer = nil
          self.channel.invokeMethod("answer", arguments: pending)
        }
        result(self.tokenInfo())
      case "getToken": result(self.tokenInfo())
      case "answerReady":
        if arguments["call_id"] as? String == self.callData?["call_id"] as? String {
          self.answerTimer?.invalidate()
          self.answerAction?.fulfill()
          self.answerAction = nil
        }
        result(nil)
      case "end":
        if arguments["call_id"] as? String == self.callData?["call_id"] as? String {
          self.finish(reason: .remoteEnded)
        }
        result(nil)
      case "signOut":
        self.defaults.set(false, forKey: "calls_enabled")
        if self.callData != nil {
          self.request("end", body: ["reason": "signed_out"]) { _ in }
          self.finish(reason: .remoteEnded)
        }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    registry = PKPushRegistry(queue: .main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    let view = UNNotificationAction(identifier: "view_alert", title: "View alert", options: [.foreground])
    let onWay = UNNotificationAction(identifier: "on_the_way", title: "I'm on the way", options: [.authenticationRequired])
    let acknowledge = UNNotificationAction(identifier: "acknowledge", title: "Acknowledge", options: [.authenticationRequired])
    UNUserNotificationCenter.current().setNotificationCategories([
      UNNotificationCategory(identifier: "vehicle_report", actions: [onWay, view], intentIdentifiers: [], options: []),
      UNNotificationCategory(identifier: "vehicle_alert", actions: [acknowledge, view], intentIdentifiers: [], options: [])
    ])
  }

  func handleAlertAction(_ response: UNNotificationResponse, completion: @escaping () -> Void) -> Bool {
    guard ["on_the_way", "acknowledge"].contains(response.actionIdentifier) else { return false }
    let info = response.notification.request.content.userInfo
    guard defaults.bool(forKey: "calls_enabled"),
          let backend = defaults.string(forKey: "calls_backend"),
          let token = info["action_token"] as? String,
          let rawID = info["notification_id"], let id = Int(String(describing: rawID)),
          let url = URL(string: "\(backend)/v1/notifications/\(id)/acknowledge") else {
      completion(); return true
    }
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    // This short-lived token is bound by the server to this recipient and alert.
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    URLSession.shared.dataTask(with: request) { _, responseData, _ in
      let success = (responseData as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
      if success {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
      } else {
        let content = UNMutableNotificationContent()
        content.title = "Please open Parking Mudde"
        content.body = "Your acknowledgement could not be sent. Open the app to try again."
        content.sound = .default
        content.userInfo = info
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "ack_failed_\(id)", content: content, trigger: nil))
      }
      completion()
    }.resume()
    return true
  }

  private func tokenInfo() -> [String: Any] {
    #if DEBUG
    let sandbox = true
    #else
    let sandbox = false
    #endif
    return ["token": token ?? "", "sandbox": sandbox]
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
    token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    if flutterReady { channel.invokeMethod("token", arguments: tokenInfo()) }
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    token = nil
    if flutterReady { channel.invokeMethod("token", arguments: tokenInfo()) }
  }

  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType, completion: @escaping () -> Void) {
    var data: [String: Any] = [:]
    payload.dictionaryPayload.forEach { key, value in
      if let key = key as? String { data[key] = value }
    }
    let id = (data["call_id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .generic, value: "Parking Mudde reporter")
    update.localizedCallerName = data["caller_label"] as? String ?? "Parking Mudde reporter"
    update.hasVideo = false
    update.supportsHolding = false
    update.supportsGrouping = false
    update.supportsUngrouping = false
    update.supportsDTMF = false
    let valid = data["call_token"] as? String != nil &&
      (data["call_id"] as? String).flatMap(UUID.init(uuidString:)) != nil
    // Always report promptly, including when Flutter has not finished starting.
    provider.reportNewIncomingCall(with: id, update: update) { [weak self] error in
      DispatchQueue.main.async {
        defer { completion() }
        guard let self = self, error == nil else { return }
        guard valid, self.callUUID == nil, self.defaults.bool(forKey: "calls_enabled") else {
          self.provider.reportCall(with: id, endedAt: Date(), reason: .failed)
          return
        }
        self.callUUID = id
        self.callData = data
        self.answered = false
        RTCAudioSession.sharedInstance().useManualAudio = true
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        self.pollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
          self?.checkStatus()
        }
        self.checkStatus()
      }
    }
  }

  private func request(_ action: String?, body: [String: Any]? = nil,
                       completion: @escaping ([String: Any]?) -> Void) {
    guard let data = callData, let id = data["call_id"] as? String,
          let token = data["call_token"] as? String,
          let backend = defaults.string(forKey: "calls_backend"),
          let url = URL(string: "\(backend)/v1/calls/\(id)" + (action.map { "/\($0)" } ?? "")) else {
      completion(nil); return
    }
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.setValue(token, forHTTPHeaderField: "X-Call-Token")
    if action != nil {
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try? JSONSerialization.data(withJSONObject: body ?? [:])
    }
    URLSession.shared.dataTask(with: request) { bytes, response, _ in
      let ok = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
      let json = bytes.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
      DispatchQueue.main.async { completion(ok ? json : nil) }
    }.resume()
  }

  private func checkStatus() {
    guard !polling, let id = callUUID else { return }
    polling = true
    request(nil) { [weak self] response in
      guard let self = self else { return }
      self.polling = false
      guard self.callUUID == id else { return }
      if let status = response?["status"] as? String,
         ["ENDED", "REJECTED", "MISSED", "FAILED"].contains(status) {
        self.finish(reason: status == "MISSED" ? .unanswered : .remoteEnded)
      } else if !self.answered, let expiry = self.callData?["expires_at"] as? String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: expiry) ?? ISO8601DateFormatter().date(from: expiry)
        if let date = date, date < Date() { self.finish(reason: .unanswered) }
      }
    }
  }

  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    guard action.callUUID == callUUID else { action.fail(); return }
    answerAction = action
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
    } catch { action.fail(); finish(reason: .failed); return }
    request("accept") { [weak self] response in
      guard let self = self, self.callUUID == action.callUUID else { action.fail(); return }
      guard response?["status"] as? String == "ACCEPTED", let data = self.callData else {
        action.fail(); self.finish(reason: .failed); return
      }
      self.answered = true
      self.answerTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
        guard let self = self, self.answerAction != nil else { return }
        self.request("end", body: ["reason": "connection_timeout"]) { _ in }
        self.finish(reason: .failed)
      }
      if self.flutterReady { self.channel.invokeMethod("answer", arguments: data) }
      else { self.pendingAnswer = data }
    }
  }

  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    guard action.callUUID == callUUID else { action.fulfill(); return }
    request(answered ? "end" : "reject", body: ["reason": answered ? "hangup" : "declined"]) { _ in }
    action.fulfill()
    finish(reason: .remoteEnded)
  }

  func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
    channel.invokeMethod("mute", arguments: ["muted": action.isMuted])
    action.fulfill()
  }

  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
  }

  func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().isAudioEnabled = false
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
  }

  func providerDidReset(_ provider: CXProvider) {
    request("end", body: ["reason": "system_reset"]) { _ in }
    finish(reason: .failed)
  }

  private func finish(reason: CXCallEndedReason) {
    let data = callData
    if let id = callUUID { provider.reportCall(with: id, endedAt: Date(), reason: reason) }
    answerAction?.fail()
    answerAction = nil
    answerTimer?.invalidate()
    pollTimer?.invalidate()
    callUUID = nil
    callData = nil
    pendingAnswer = nil
    answered = false
    RTCAudioSession.sharedInstance().isAudioEnabled = false
    RTCAudioSession.sharedInstance().useManualAudio = false
    if let data = data, flutterReady { channel.invokeMethod("ended", arguments: data) }
  }
}
