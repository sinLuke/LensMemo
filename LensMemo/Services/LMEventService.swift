//
//  LMEventService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-24.
//

import EventKit
import UIKit

class LMEventService {
    static let shared = LMEventService()
    weak var appContext: LMAppContext?
    var store = EKEventStore()
    
    private init() {}
    
    private func requestAccess(completion: @escaping () -> (), errorCompletion: @escaping (Error?) -> ()) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let error = error {
                errorCompletion(error)
            }
            if granted {
                completion()
            } else {
                errorCompletion(nil)
            }
        }
    }
    
    func createReminder(for note: LMNote, appContext: LMAppContext) {
        requestAccess(completion: {
            DispatchQueue.main.async {
                guard let uuidString = note.id?.uuidString else { return }
                let content = UNMutableNotificationContent()
                content.title = "Weekly Staff Meeting"
                content.body = "Every Tuesday at 2pm"
                
                var dateComponents = DateComponents()
                dateComponents.calendar = Calendar.current
                
                dateComponents.year = 2020  // Tuesday
                dateComponents.month = 8  // Tuesday
                dateComponents.day = 25  // Tuesday
                dateComponents.hour = 0    // 14:00 hours
                dateComponents.minute = 48
                
                // Create the trigger as a repeating event.
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents, repeats: true)
                
                let request = UNNotificationRequest(identifier: uuidString,
                                                    content: content, trigger: trigger)
                
                // Schedule the request with the system.
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.add(request) { (error) in
                    if let error = error {
                        appContext.mainViewController.present(LMAlertViewViewController.getInstance(error: error), animated: true, completion: nil)
                    }
                }
            }
            
        }) { (error) in
            DispatchQueue.main.async {
                appContext.mainViewController.present(LMAlertViewViewController.getInstance(error: error ?? NSError(domain: "unknown error", code: 0, userInfo: nil)), animated: true, completion: nil)
            }
            
        }
        
    }
}
