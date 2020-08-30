//
//  LMAppDelegate.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-06-30.
//

import UIKit
import CoreData
import CloudKit

var isFirstLaunch = false

@UIApplicationMain
class LMAppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if !LMUserDefaults.hasLaunchedBefore {
            appFirstLaunch()
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        // Request permission from user to send notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
            if authorized {
                DispatchQueue.main.async(execute: {
                    application.registerForRemoteNotifications()
                })
            }
        })
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func appFirstLaunch() {
        LMUserDefaults.hasLaunchedBefore = true
        LMUserDefaults.documentEnhancerEnable = true
        LMUserDefaults.documentEnhancerAmount = 5.0
        LMUserDefaults.alertWhenDeleteNote = true
        LMUserDefaults.alertWhenDeleteNotebook = true
        LMUserDefaults.alertWhenDeleteSticker = true
        LMUserDefaults.uploadInMobileInternet = true
        LMUserDefaults.downloadInMobileInternet = true
        LMUserDefaults.jpegCompressionQuality = 0.8
        LMUserDefaults.downloadQualityInMobileInternet = 3

        isFirstLaunch = true
    }
    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        let notification = CKNotification.init(fromRemoteNotificationDictionary: userInfo)
//        notification?.alertBody
//        let content = UNMutableNotificationContent()
//        content.title = "From background 2"
//        content.body = "Every Tuesday at 2pm"
//
//        var dateComponents = DateComponents()
//        dateComponents.calendar = Calendar.current
//
//        dateComponents.year = 2020  // Tuesday
//        dateComponents.month = 8  // Tuesday
//        dateComponents.day = 25  // Tuesday
//        dateComponents.hour = 2    // 14:00 hours
//        dateComponents.minute = 8
//
//        // Create the trigger as a repeating event.
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
//
//        let request = UNNotificationRequest(identifier: UUID().uuidString,
//                                            content: content, trigger: trigger)
//
//        // Schedule the request with the system.
//        let notificationCenter = UNUserNotificationCenter.current()
//        notificationCenter.add(request) { (error) in
//            if let error = error {
//                print("error")
//            } else {
//                completionHandler(.noData)
//            }
//        }
//    }
    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        
//        // Create a subscription to the 'Notifications' Record Type in CloudKit
//        // User will receive a push notification when a new record is created in CloudKit
//        // Read more on https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/SubscribingtoRecordChanges/SubscribingtoRecordChanges.html
//        
//        // The predicate lets you define condition of the subscription, eg: only be notified of change if the newly created notification start with "A"
//        // the TRUEPREDICATE means any new Notifications record created will be notified
//        let subscription = CKQuerySubscription(recordType: "CD_LMNote", predicate: NSPredicate(format: "TRUEPREDICATE"), options: .firesOnRecordCreation
//        )
//        
//        // Here we customize the notification message
//        let info = CKSubscription.NotificationInfo()
//        
//        // this will use the 'title' field in the Record type 'notifications' as the title of the push notification
//        info.titleLocalizationKey = "%1$@"
//        info.titleLocalizationArgs = ["CD_name"]
//        info.shouldSendContentAvailable = true
//        
//        // if you want to use multiple field combined for the title of push notification
//        // info.titleLocalizationKey = "%1$@ %2$@" // if want to add more, the format will be "%3$@", "%4$@" and so on
//        // info.titleLocalizationArgs = ["title", "subtitle"]
//        
//        // this will use the 'content' field in the Record type 'notifications' as the content of the push notification
//        info.alertLocalizationKey = "%1$@ 1"
//        info.alertLocalizationArgs = ["CD_message"]
//        
//        // increment the red number count on the top right corner of app icon
//        info.shouldBadge = true
//        
//        // use system default notification sound
//        info.soundName = "default"
//        
//        subscription.notificationInfo = info
//        
//        // Save the subscription to Public Database in Cloudkit
//        CKContainer.default().publicCloudDatabase.save(subscription, completionHandler: { subscription, error in
//            if let error = error {
//                print("error \(error)")
//            } else {
//                return
//            }
//        })
//        
//    }
}

extension LMAppDelegate: UNUserNotificationCenterDelegate {
    // This function will be called when the app receive notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // show the notification alert (banner), and with sound
        completionHandler([.alert, .sound])
    }
    
    // This function will be called right after user tap on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // tell the app that we have finished processing the user’s action (eg: tap on notification banner) / response
        completionHandler()
    }
}
