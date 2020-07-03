//
//  SceneDelegate.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-06-30.
//

import UIKit

class LMSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var appContext: LMAppContext!
    
    var mainViewController: LMMainViewController?
    var cameraViewController: LMCameraViewController?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: scene)
        window.makeKeyAndVisible()
        self.window = window
        
        do {
            try appContext = LMAppContext()
//            throw NSError(domain: "domian", code: 123, userInfo: nil)
        } catch (let error) {
            let alert = LMAlertViewViewController.getInstance(icon: UIImage(systemName: "xmark.octagon"), color: .systemRed, title: "Error when reading data", message: "\(error.localizedDescription)", buttons: [LMAlertViewViewController.Button.init(title: "Retry", onTap: {
                self.scene(scene, willConnectTo: session, options: connectionOptions)
            })])
            window.rootViewController = alert
            return
        }
        
        mainViewController = LMMainViewController.getInstance(appContext: appContext)
        cameraViewController = LMCameraViewController.getInstance()
        
        window.rootViewController = mainViewController
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceDidRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
    }
    
    @objc func deviceDidRotated() {
        if UIDevice.current.orientation.isLandscape, !(window?.rootViewController is LMCameraViewController) {
            window?.rootViewController = cameraViewController
        }
        if UIDevice.current.orientation.isPortrait, !(window?.rootViewController is LMMainViewController) {
            window?.rootViewController = mainViewController
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
        (UIApplication.shared.delegate as? LMAppDelegate)?.saveContext()
    }
}

