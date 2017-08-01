import Foundation
import UIKit
import SnapKit

public class InfoOverlay {
    public private(set) static var instance = InfoOverlay()
    private var window: UIWindow!
    private var view: UIView!
    private var label: UILabel!

    private init() {
        DispatchQueue.main.async {
            self.createWindow()
            self.createView()
        }
    }

    public static var visible: Bool = false {
        didSet {
            self.instance.visible = visible
        }
    }

    public var visible: Bool = false {
        didSet {
            self.view?.isHidden = !visible
        }
    }


    public static var additionalText: String = "" {
        didSet {
            self.instance.label.text = self.instance.stringForLabel()
        }
    }

    private func stringForLabel() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let debug: String
        #if DEBUG
            debug = "D"
        #else
            debug = ""
        #endif
        return InfoOverlay.additionalText+" "+version+debug
    }

    private func createWindow() {
        let window = UIWindow()
        self.window = window

        window.windowLevel = UIWindowLevelAlert+1
        window.isHidden = false
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = false
    }

    private func createView() {
        self.view = UIView()
        view.isHidden = !self.visible
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false

        self.label = UILabel()
        label.text = self.stringForLabel()
        label.font = label.font.withSize(5)
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        self.window.addSubview(view)

        view.snp.makeConstraints {
            make in
            make.leading.top.equalTo(0)
            make.edges.equalTo(label)
        }
    }
}
