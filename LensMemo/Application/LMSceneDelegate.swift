//
//  SceneDelegate.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-06-30.
//

import UIKit

class LMSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var appContext: LMAppContext?
    
    var rootView: RootView = .automatic {
        didSet {
            if rootView == .camera {
                window?.rootViewController = appContext?.cameraViewController
            }
            if rootView == .notebook {
                window?.rootViewController = appContext?.mainViewController
            }
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: scene)
        window.makeKeyAndVisible()
        self.window = window
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.toggleCamerView), name: NSNotification.Name(rawValue: "toggleCamerView"), object: nil)
        
        do {
            try LMAppContext.getInstance { result in
                switch result {
                case let .success(appContext):
                    self.appContext = appContext
                    self.appLaunchWith(appContext: appContext)
                case let .failure(error):
                    let alertData = LMAlertViewViewController.Data(
                        allowDismiss: false,
                        icon: UIImage(systemName: "xmark.octagon"),
                        color: .systemRed,
                        title: "Error",
                        messages: ["App couldn't launch", "Error code: \((error as NSError).code)", "Error description: \(error.localizedDescription)"] + (error as NSError).userInfo.compactMap { info in "\(info.key): \(info.value)"},
                        primaryButton: LMAlertViewViewController.Button.init(title: "Retry", onTap: {
                            self.scene(scene, willConnectTo: session, options: connectionOptions)
                        }))
                    let alert = LMAlertViewViewController.getInstance(data: alertData)
                    window.rootViewController = alert
                    return
                }
            }
        } catch (let error) {
            let alertData = LMAlertViewViewController.Data(
                allowDismiss: false,
                icon: UIImage(systemName: "xmark.octagon"),
                color: .systemRed,
                title: "Error",
                messages: ["App couldn't launch", "Error code: \((error as NSError).code)", "Error description: \(error.localizedDescription)"],
                primaryButton: LMAlertViewViewController.Button.init(title: "Retry", onTap: {
                    self.scene(scene, willConnectTo: session, options: connectionOptions)
                }))
            let alert = LMAlertViewViewController.getInstance(data: alertData)
            window.rootViewController = alert
            return
        }
    }
    
    func appLaunchWith(appContext: LMAppContext) {
        self.appContext = appContext
        window?.rootViewController = appContext.mainViewController
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDidRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        LMDownloadService.shared.startTimer()
        
        #if targetEnvironment(macCatalyst)
        rootView = .notebook
        #else
        rootView = UIDevice.current.userInterfaceIdiom == .pad ? .notebook : .automatic
        #endif
    }
    
    @objc func deviceDidRotated() {
        guard UIDevice.current.orientation != .unknown else {
            return 
        }
        
//        if rootView == .automatic {
//            appContext?.orientation = UIDevice.current.orientation
//            if UIDevice.current.orientation.isLandscape, !(window?.rootViewController is LMCameraViewController) {
//                window?.rootViewController = appContext?.cameraViewController
//            }
//            if UIDevice.current.orientation.isPortrait, !(window?.rootViewController is LMMainViewController) {
//                window?.rootViewController = appContext?.mainViewController
//            }
//        }
    }
    
    @objc func toggleCamerView() {
        if window?.rootViewController == appContext?.cameraViewController {
            window?.rootViewController = appContext?.mainViewController
        } else {
            window?.rootViewController = appContext?.cameraViewController
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        try? appContext?.storage.saveContext()
    }
}

extension LMSceneDelegate {
    enum RootView {
        case automatic
        case camera
        case notebook
    }
}
