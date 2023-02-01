//
//  AudioPlayer.swift
//  audioKitTemplate
//
//  Created by Peter Rogers on 23/01/2023.
//

import Foundation
import AVFoundation

import SwiftUI
import AudioKit
import Controls
import SoundpipeAudioKit
import AudioToolbox
import AudioKitEX


struct AudioPlayerData {
    var reverbValue: AUValue = 0
    var wahValue: AUValue = 0
    
}

class AudioPlayerConductor: ObservableObject, MIDIListener{
    let engine = AudioEngine()
    let midi = MIDI()
    var player = AudioPlayer()
   
   
    var mixer:Mixer!
    var wah: AutoWah!
   
     
    var reverb: Reverb!
    
    init() {
      
        loadPlayer()
        midi.addListener(self)
        midi.openInput()
       
        wah = AutoWah(player)
        wah.wah = 0
        wah.amplitude = 1
    
        reverb = Reverb(wah)
        reverb.loadFactoryPreset(.cathedral)
        engine.output = reverb
        try? engine.start()
        player.play()
    }
    
    func loadPlayer(){
        let url = Bundle.main.url(forResource: "drums", withExtension: "wav")!
                do {
                    try player.load(url: url, buffered: true)
                    player.isLooping = true
                    player.isBuffered = true
                } catch {
                    Log(error.localizedDescription, type: .error)
                }
                
        
    }
    
    
    @Published var data = AudioPlayerData() {
        didSet {
            wah.wah = data.wahValue
            reverb.dryWetMix = data.reverbValue

        }
    }
    
    func receivedMIDINoteOn(noteNumber: AudioKit.MIDINoteNumber, velocity: AudioKit.MIDIVelocity, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDINoteOff(noteNumber: AudioKit.MIDINoteNumber, velocity: AudioKit.MIDIVelocity, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIController(_ controller: AudioKit.MIDIByte, value: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        DispatchQueue.main.async {
            print("\(controller) : \(channel)")
            print(channel)
            if controller == 16 {
                if(channel == 1){
                    self.data.wahValue = Float(value) / 127.0
                }
                if(channel == 0){
                    self.data.reverbValue = Float(value-64) / 1270.0
                }
//            }else if controller == 17 {
//                self.data.frequencyIndex = Float(value) / 127.0 * 21 - 1
//            }else if controller == 18 {
//                self.data.pulseWidth = Float(value) / 127.0
//            }else if controller == 19 {
//                self.cutoff = Float(value) / 127.0 * 19980 + 20
           }
        }
    }
    func receivedMIDIAftertouch(noteNumber: AudioKit.MIDINoteNumber, pressure: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(_ pressure: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIPitchWheel(_ pitchWheelValue: AudioKit.MIDIWord, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        DispatchQueue.main.async {
            print("\(pitchWheelValue) : \(channel)")
            //print(channel)
            
                if(channel == 0){
                    self.data.wahValue = Float(pitchWheelValue) / 16383
                }
//                if(channel == 0){
//                    self.data.delay = Float(value-64) / 1270.0
//                }
//            }else if controller == 17 {
//                self.data.frequencyIndex = Float(value) / 127.0 * 21 - 1
//            }else if controller == 18 {
//                self.data.pulseWidth = Float(value) / 127.0
//            }else if controller == 19 {
//                self.cutoff = Float(value) / 127.0 * 19980 + 20
           }
        }
    
    
    func receivedMIDIProgramChange(_ program: AudioKit.MIDIByte, channel: AudioKit.MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISystemCommand(_ data: [AudioKit.MIDIByte], portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISetupChange() {}
    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {}
    func receivedMIDINotification(notification: MIDINotification) {}
}
    
struct AudioPlayerConsole: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var conductor = AudioPlayerConductor()
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.blue.opacity(0.95), .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    SmallKnob(value: self.$conductor.data.wahValue, range: 0 ... 1).padding(20)
                    SmallKnob(value: self.$conductor.data.reverbValue, range: 0 ... 1).padding(20)
                }
               
            }.frame(maxWidth: 500, maxHeight: 500).padding(20)
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if(!conductor.engine.avEngine.isRunning) {
                    try? conductor.engine.start()
                    conductor.midi.openInput()
                }
            } else if newPhase == .background {
                
                conductor.engine.stop()
                conductor.midi.closeAllInputs()
            }
        }.onDisappear() {
          
            conductor.engine.stop()
            conductor.midi.closeAllInputs()
        }
    }
}
struct AudioPlayerConsole_Previews: PreviewProvider {static var previews: some View {AudioPlayerConsole()}}


