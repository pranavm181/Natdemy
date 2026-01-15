import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let screenRecordingChannelName = "com.natdemy.learning/screen_recording"
  private var screenRecordingBlocked = true
  private var screenShieldView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    setupScreenRecordingChannel()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScreenCaptureChange),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    // Ensure the shield state matches the initial configuration.
    handleScreenCaptureChange()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
  }

  private func setupScreenRecordingChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }

    let channel = FlutterMethodChannel(
      name: screenRecordingChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setScreenRecordingBlocked" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let blocked = arguments["blocked"] as? Bool
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected 'blocked' bool argument", details: nil))
        return
      }

      self?.setScreenRecordingBlocked(blocked)
      result(nil)
    }
  }

  private func setScreenRecordingBlocked(_ blocked: Bool) {
    screenRecordingBlocked = blocked
    DispatchQueue.main.async { [weak self] in
      self?.handleScreenCaptureChange()
    }
  }

  @objc private func handleScreenCaptureChange() {
    guard screenRecordingBlocked else {
      removeScreenShield()
      return
    }

    if UIScreen.main.isCaptured {
      showScreenShield()
    } else {
      removeScreenShield()
    }
  }

  private func showScreenShield() {
    guard screenShieldView == nil, let window = self.window else { return }

    let shield = UIView(frame: window.bounds)
    shield.translatesAutoresizingMaskIntoConstraints = false
    shield.backgroundColor = UIColor.black

    let blurEffect = UIBlurEffect(style: .systemChromeMaterialDark)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    shield.addSubview(blurView)

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "Screen recording is disabled for security."
    label.textColor = .white
    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)

    shield.addSubview(label)
    window.addSubview(shield)

    NSLayoutConstraint.activate([
      shield.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      shield.trailingAnchor.constraint(equalTo: window.trailingAnchor),
      shield.topAnchor.constraint(equalTo: window.topAnchor),
      shield.bottomAnchor.constraint(equalTo: window.bottomAnchor),

      blurView.leadingAnchor.constraint(equalTo: shield.leadingAnchor),
      blurView.trailingAnchor.constraint(equalTo: shield.trailingAnchor),
      blurView.topAnchor.constraint(equalTo: shield.topAnchor),
      blurView.bottomAnchor.constraint(equalTo: shield.bottomAnchor),

      label.centerXAnchor.constraint(equalTo: shield.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: shield.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: shield.leadingAnchor, constant: 24),
      label.trailingAnchor.constraint(lessThanOrEqualTo: shield.trailingAnchor, constant: -24)
    ])

    screenShieldView = shield
  }

  private func removeScreenShield() {
    screenShieldView?.removeFromSuperview()
    screenShieldView = nil
  }
}
