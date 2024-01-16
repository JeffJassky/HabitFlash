//
//  PomodoroTimerView.swift
//  ReMindful
//
//  Created by Jeff Jassky on 1/16/24.
//

import SwiftUI

struct PomodoroTimerView: View {
    @EnvironmentObject var pomodoroManager: PomodoroManager
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading) {
            Text("Pomodoro Timer").font(.title).padding()
            Divider()
            
            VStack(alignment: .leading) {
                switch pomodoroManager.timerState {
                case .running, .paused:
                    
                    Text("\(pomodoroManager.timeRemainingReadable)")
                    if pomodoroManager.timerState == .paused{
                        Button("Start") {
                            pomodoroManager.startTimer()
                        }
                    }else{
                        Button("Pause") {
                            pomodoroManager.pauseTimer()
                        }
                    }
                    Button("Stop") {
                        pomodoroManager.stopTimer()
                    }
                case .stopped:
                    Picker("Duration", selection: $settings.pomodoroDuration) {
                        ForEach([5, 10, 15, 25, 30, 45, 60], id: \.self) {
                            Text("\($0) minutes")
                        }
                    }.frame(width: 180)
                    HStack{
                        Toggle("Show countdown", isOn: $settings.pomodoroCountdownDisplay)
                        if settings.pomodoroCountdownDisplay{
                            Picker("every", selection: $settings.pomodoroCountdownDisplayFrequency) {
                                ForEach([1, 5, 10], id: \.self) {
                                    Text("\($0) minutes")
                                }
                            }.frame(width: 150)
                        }
                    }
                    Button("Start") {
                        pomodoroManager.startTimer()
                    }
                }
            }.padding();
        }
    }
}

struct PomodoroTimerView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var previews: some View {
        PomodoroTimerView()
            .environmentObject(settingsManager)
            .environmentObject(PomodoroManager(settings: settingsManager))
    }
}
