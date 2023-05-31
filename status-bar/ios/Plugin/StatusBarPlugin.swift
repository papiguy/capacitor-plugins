import Foundation
import Capacitor

/**
 * StatusBar plugin. Requires "View controller-based status bar appearance" to
 * be "YES" in Info.plist
 */
@objc(StatusBarPlugin)
public class StatusBarPlugin: CAPPlugin {
    private var observer: NSObjectProtocol?

    override public func load() {
        observer = NotificationCenter.default.addObserver(forName: Notification.Name.capacitorStatusBarTapped, object: .none, queue: .none) { [weak self] _ in
            self?.bridge?.triggerJSEvent(eventName: "statusTap", target: "window")
        }
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @objc func setStyle(_ call: CAPPluginCall) {
        let options = call.options!

        if let style = options["style"] as? String {
            if style == "DARK" {
                bridge?.statusBarStyle = .lightContent
            } else if style == "LIGHT" {
                bridge?.statusBarStyle = .darkContent
            } else if style == "DEFAULT" {
                bridge?.statusBarStyle = .default
            }
        }

        call.resolve([:])
    }
    
    @objc func setBackgroundColor(_ call: CAPPluginCall) {
        let options = call.options!
        
        if let colorHexStr = options["color"] as? String {
            let color = UIColor.init(colorHexStr)
            if #available(iOS 13.0, *) {
                DispatchQueue.main.async {
                    let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                    let statusBar = UIView(frame: window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
                    statusBar.backgroundColor = color
                    window?.addSubview(statusBar)
                }
            } else {
                DispatchQueue.main.async {
                    if let statusBarView = UIApplication.shared.value(forKey: "statusBar") as? UIView {
                        statusBarView.backgroundColor = color
                    }
                }
            }
        }
      }
    
    func setAnimation(_ call: CAPPluginCall) {
        let animation = call.getString("animation", "FADE")
        if animation == "SLIDE" {
            bridge?.statusBarAnimation = .slide
        } else if animation == "NONE" {
            bridge?.statusBarAnimation = .none
        } else {
            bridge?.statusBarAnimation = .fade
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        setAnimation(call)
        bridge?.statusBarVisible = false
        call.resolve()
    }

    @objc func show(_ call: CAPPluginCall) {
        setAnimation(call)
        bridge?.statusBarVisible = true
        call.resolve()
    }

    @objc func getInfo(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let bridge = self?.bridge else {
                return
            }
            let style: String
            switch bridge.statusBarStyle {
            case .default:
                if bridge.userInterfaceStyle == UIUserInterfaceStyle.dark {
                    style = "DARK"
                } else {
                    style = "LIGHT"
                }
            case .lightContent:
                style = "DARK"
            default:
                style = "LIGHT"
            }

            call.resolve([
                "visible": bridge.statusBarVisible,
                "style": style
            ])
        }
    }

    @objc func setOverlaysWebView(_ call: CAPPluginCall) {
        call.unimplemented()
    }
}

extension UIColor {
  
  convenience init(_ hex: String, alpha: CGFloat = 1.0) {
    var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if cString.hasPrefix("#") { cString.removeFirst() }
    
    if cString.count != 6 {
      self.init("ff0000") // return red color for wrong hex input
      return
    }
    
    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)
    
    self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
              green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
              blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
              alpha: alpha)
  }

}
