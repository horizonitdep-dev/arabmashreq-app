import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    configureShareChannel()
    return didFinish
  }

  private func configureShareChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.arabmashreq.mobile/share",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareText" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let arguments = call.arguments as? [String: Any],
        let text = arguments["text"] as? String,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(FlutterError(
          code: "INVALID_ARGUMENT",
          message: "text is required",
          details: nil
        ))
        return
      }

      var items: [Any] = [text]
      if let subject = arguments["subject"] as? String,
         !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        items.insert(subject, at: 0)
      }

      DispatchQueue.main.async {
        guard let presenter = self?.topViewController() else {
          result(FlutterError(
            code: "NO_VIEW_CONTROLLER",
            message: "Unable to find a view controller for sharing",
            details: nil
          ))
          return
        }

        let activityController = UIActivityViewController(
          activityItems: items,
          applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
          popover.sourceView = presenter.view
          popover.sourceRect = CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 1,
            height: 1
          )
          popover.permittedArrowDirections = []
        }

        presenter.present(activityController, animated: true) {
          result(true)
        }
      }
    }
  }

  private func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let current = base ?? window?.rootViewController
    if let navigation = current as? UINavigationController {
      return topViewController(base: navigation.visibleViewController)
    }
    if let tab = current as? UITabBarController,
       let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = current?.presentedViewController {
      return topViewController(base: presented)
    }
    return current
  }
}
