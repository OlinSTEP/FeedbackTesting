//
//  HapticManager.swift
//  Haptic Tester
//
//  Created by Paul Ruvolo on 1/31/23.
//

import Foundation
import CoreHaptics

class HapticManager {
    var hapticEngine: CHHapticEngine!
    var hapticPlayer: CHHapticAdvancedPatternPlayer!
    
    init() {
        setupHaptics()
    }
    
    func pauseHaptics() {
        try! hapticPlayer.pause(atTime: 0.0)
    }
    
    func unpauseHaptics() {
        try! hapticPlayer.start(atTime: 0.0)
    }
    
    func setupHaptics() {
        do {
            hapticEngine = try CHHapticEngine()
            hapticEngine.start() { error in
                if error != nil {
                    print("error \(error?.localizedDescription)")
                    return
                }
                let events = [CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
                    CHHapticEventParameter(parameterID: .attackTime, value: 0.1),
                    CHHapticEventParameter(parameterID: .releaseTime, value: 0.2),
                    CHHapticEventParameter(parameterID: .decayTime, value: 0.3) ], relativeTime: 0.1, duration: 0.6)]
                
                do {
                    self.hapticPlayer = try self.hapticEngine.makeAdvancedPlayer(with: CHHapticPattern(events: events, parameters: []))
                } catch {
                    print("HAPTICS ERROR!!!")
                }
            }
        } catch {
            print("Unable to start haptic engine")
        }
    }
    
    func adjustHaptics(description: HapticDescription) {
        try! hapticPlayer?.sendParameters([CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: max(0.0, description.intensity), relativeTime: 0.0), CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: max(0.0, description.sharpness), relativeTime: 0.0), CHHapticDynamicParameter(parameterID: .hapticAttackTimeControl, value: max(0.0, description.attackTime), relativeTime: 0.0), CHHapticDynamicParameter(parameterID: .hapticReleaseTimeControl, value: max(0.0, description.releaseTime), relativeTime: 0.0), CHHapticDynamicParameter(parameterID: .hapticDecayTimeControl, value: max(0.0, description.decayTime), relativeTime: 0.0)], atTime: 0.0)
    }
}
