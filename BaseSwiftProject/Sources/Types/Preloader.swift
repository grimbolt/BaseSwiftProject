//
//  Preloader.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 13.01.2017.
//
//

import UIKit

public enum PreloaderType {
    case fullscreen
    case small
}

struct SimplePreloader {
    var label: String
    var type: PreloaderType
}

class Preloader {
    fileprivate static let lock = NSLock()
    
    fileprivate static let animationSpeed = 0.25
    fileprivate static let fullscreenPreloader: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        view.alpha = 0
        view.isUserInteractionEnabled = true
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        view.addSubview(indicator)
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6)
        return view
    }()
    
    fileprivate static let smallPreloader: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.alpha = 0
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        indicator.center = view.center
        view.addSubview(indicator)
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6)
        return view
    }()
    
    fileprivate static var labels = [SimplePreloader]()
}

private func getPreloaderView(_ type: PreloaderType) -> UIView {
    var preloaderView: UIView
    switch type {
    case .fullscreen:
        preloaderView = Preloader.fullscreenPreloader
    case .small:
        preloaderView = Preloader.smallPreloader
    }
    
    return preloaderView
}

public func showPreloader(_ label: String?, type: PreloaderType) {
    Preloader.lock.lock()
    
    guard let label = label else {
        Preloader.lock.unlock()
        return
    }

    Preloader.labels.append(SimplePreloader(label: label, type: type))

    if type == .small && Preloader.labels.contains(where: { $0.type == .fullscreen }) {
        Preloader.lock.unlock()
        return
    }

    DispatchQueue.main.async() {
        let preloaderView = getPreloaderView(type)
        if let indicator = preloaderView.subviews.first as? UIActivityIndicatorView {
            switch type {
            case .fullscreen:
                preloaderView.frame = UIScreen.main.bounds
                indicator.center = preloaderView.center
            case .small:
                preloaderView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            }
            indicator.startAnimating()
            
            let window = UIApplication.shared.keyWindow!
            
            preloaderView.removeFromSuperview()
            window.addSubview(preloaderView)
            
            UIView.animate(withDuration: Preloader.animationSpeed, animations: {
                preloaderView.alpha = 1
            }, completion: { complete in
            })
        }
    }
    Preloader.lock.unlock()
}

public func hidePreloader(_ label: String?, type: PreloaderType) {
    Preloader.lock.lock()

    guard let label = label else {
        Preloader.lock.unlock()
        return
    }
    Preloader.labels = Preloader.labels.filter({ !($0.label == label && $0.type == type) })
    
    if Preloader.labels.count == 0 {
        DispatchQueue.main.async() {
            let preloaderView = getPreloaderView(type)
            UIView.animate(withDuration: Preloader.animationSpeed, animations: {
                preloaderView.alpha = 0
            }, completion: { complete in
                preloaderView.removeFromSuperview()
            })
        }
    }
    Preloader.lock.unlock()
}
