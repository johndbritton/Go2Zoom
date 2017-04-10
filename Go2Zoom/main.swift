//
//  main.swift
//  Go2Zoom
//
//  Created by John Britton on 4/9/17.
//  Copyright © 2017 John Britton. All rights reserved.
//

import EventKit

let eventStore = EKEventStore()

switch EKEventStore.authorizationStatus(for: .event) {
case .authorized: break
case .denied: break
case .notDetermined:
    eventStore.requestAccess(to: .event) {
        (granted: Bool, error: Error?) -> Void in
        if granted {
            //access
        } else {
            print("Access denied")
        }
    }
default: break
}

let startDate = Date(timeIntervalSinceNow: -1 * 15 * 60)
let endDate = Date(timeIntervalSinceNow: 15 * 60)

let eventsPredicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)

let events = eventStore.events(matching: eventsPredicate)

let zoomPattern = "https://\\w+\\.zoom\\.us/(s|j|my)/\\w+"

var zoomEvents = [EKEvent:String]()

for event in events {
    if !event.isAllDay {
        let text = "\(event.title) \(event.location) \(event.url) \(event.notes)"
        
        if let range = text.range(of: zoomPattern, options: .regularExpression) {
            zoomEvents[event] = text[range]
        }
    }
}

if let event = zoomEvents.first {
    let urlString = event.value
    if (urlString.range(of: "/my/") != nil) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared().open(url)
        }
    } else {
        if let meetingIdRange = urlString.range(of: "\\d{9}", options: .regularExpression) {
            let meetingId = urlString[meetingIdRange]
            
            if let domain = urlString.range(of: "https://\\w+\\.zoom\\.us", options: .regularExpression) {
                let zoomMtg = "\(urlString[domain].replacingOccurrences(of: "https://", with: "zoommtg://"))/join?action=join&confno=\(meetingId)"
                if let url = URL(string: zoomMtg) {
                    NSWorkspace.shared().open(url)
                }
            }
        }
    }
}
