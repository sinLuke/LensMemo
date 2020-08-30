//
//  UserDefaultExtension.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-29.
//

import Foundation

class LMUserDefaults {
    static var hasLaunchedBefore: Bool {
        set {
            UserDefaults().set(newValue, forKey: "hasLaunchedBefore")
        }
        get {
            return UserDefaults().bool(forKey: "hasLaunchedBefore")
        }
    }
    
    static var documentEnhancerEnable: Bool {
        set {
            UserDefaults().set(newValue, forKey: "documentEnhancerEnable")
        }
        get {
            return UserDefaults().bool(forKey: "documentEnhancerEnable")
        }
    }
    
    static var documentEnhancerAmount: Float {
        set {
            UserDefaults().set(newValue, forKey: "documentEnhancerAmount")
        }
        get {
            return UserDefaults().float(forKey: "documentEnhancerAmount")
        }
    }
    
    static var alertWhenDeleteNote: Bool {
        set {
            UserDefaults().set(newValue, forKey: "alertWhenDeleteNote")
        }
        get {
            return UserDefaults().bool(forKey: "alertWhenDeleteNote")
        }
    }
    
    static var alertWhenDeleteNotebook: Bool {
        set {
            UserDefaults().set(newValue, forKey: "alertWhenDeleteNotebook")
        }
        get {
            return UserDefaults().bool(forKey: "alertWhenDeleteNotebook")
        }
    }
    
    static var alertWhenDeleteSticker: Bool {
        set {
            UserDefaults().set(newValue, forKey: "alertWhenDeleteSticker")
        }
        get {
            return UserDefaults().bool(forKey: "alertWhenDeleteSticker")
        }
    }
    
    static var uploadInMobileInternet: Bool {
        set {
            UserDefaults().set(newValue, forKey: "uploadInMobileInternet")
        }
        get {
            return UserDefaults().bool(forKey: "uploadInMobileInternet")
        }
    }
    
    static var downloadInMobileInternet: Bool {
        set {
            UserDefaults().set(newValue, forKey: "downloadInMobileInternet")
        }
        get {
            return UserDefaults().bool(forKey: "downloadInMobileInternet")
        }
    }
    
    static var jpegCompressionQuality: Float {
        set {
            UserDefaults().set(newValue, forKey: "jpegCompressionQuality")
        }
        get {
            return UserDefaults().float(forKey: "jpegCompressionQuality")
        }
    }
    
    static var downloadQualityInMobileInternet: Int {
        set {
            UserDefaults().set(newValue, forKey: "downloadQualityInMobileInternet")
        }
        get {
            return UserDefaults().integer(forKey: "downloadQualityInMobileInternet")
        }
    }
}

