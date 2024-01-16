//
//  PomodoroManager.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications
import Combine

class PomodoroManager: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var timeRemainingReadable: String = ""
    @Published var reminderInterval: Int = 0
    @Published var timerState: TimerState = .stopped
    
    var timer: Timer?
    var settings: SettingsManager
    init(settings: SettingsManager) {
        self.settings = settings
    }
    
    enum TimerState {
        case running, paused, stopped
    }

    func startTimer() {
        if(timerState == .stopped){
            timeRemaining = settings.pomodoroDuration * 60
        }
        setReadableTimer();
        timerState = .running
        
        // start counting down
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }

    func pauseTimer() {
        timerState = .paused
        timer?.invalidate()
    }

    func stopTimer() {
        timerState = .stopped
        timer?.invalidate()
        timeRemaining = 0
    }
    
    private func setReadableTimer(){
        
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60

        if minutes > 0 && seconds > 0 {
            // Format for minutes and seconds
            timeRemainingReadable = "\(minutes):\(String(format: "%02d", seconds))"
        } else if minutes > 0 {
            // Format for only minutes
            timeRemainingReadable = "\(minutes) minute" + (minutes > 1 ? "s" : "")
        } else {
            // Format for only seconds
            timeRemainingReadable = "\(seconds) second" + (seconds > 1 ? "s" : "")
        }
    }

    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            setReadableTimer();
            if timeRemaining % (settings.pomodoroCountdownDisplayFrequency * 60) == 0 || timeRemaining < 10 {
                settings.displayMessagePublisher.send("\(timeRemainingReadable) to go")
            }
        } else {
            // Send a final message when the timer ends
            settings.displayMessagePublisher.send("Complete!")
            stopTimer()
        }
    }

}
