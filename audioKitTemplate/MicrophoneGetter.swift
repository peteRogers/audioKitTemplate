//
//  MicrophoneGetter.swift
//  audioKitTemplate
//
//  Created by Peter Rogers on 22/11/2023.
//

import Foundation
import AudioKit
import AudioKitEX
import AudioKitUI
import AudioToolbox
import SoundpipeAudioKit
import SwiftUI
import Controls

struct MicrophoneData {
	var pitch: Float = 0.0
	var amplitude: Float = 0.0
	var currentVolume: Float = 0.0
}

class MicrophoneConductor: ObservableObject, HasAudioEngine {
	@Published var data = MicrophoneData()
	let engine = AudioEngine()
	let initialDevice: Device
	let mic: AudioEngine.InputNode
	let tappableNodeA: Fader
	let silence: Fader
	var tracker: PitchTap!
	var player = AudioPlayer()
	var mixer:Mixer!
	
	init() {
		print("init")
		print(Settings.ioBufferDuration)
		Settings.ioBufferDuration = 0.0001
		guard let input = engine.input else { fatalError() }
		guard let device = engine.inputDevice else { fatalError() }
		initialDevice = device
		mic = input
		tappableNodeA = Fader(mic)
		
		silence = Fader(tappableNodeA, gain: 0)
		loadPlayer()
		mixer = Mixer(player, silence)
		engine.output = mixer
		tracker = PitchTap(mic) { pitch, amp in
			DispatchQueue.main.async {
				self.update(pitch[0], amp[0])
			}
		}
		tracker.start()
		try? engine.start()
		
		player.play()
		player.volume = 0.2
	}
	
	func loadPlayer(){
		let url = Bundle.main.url(forResource: "waterClipped", withExtension: "aif")!
				do {
					try player.load(url: url, buffered: false)
					player.isLooping = true
					//player.isBuffered = true
				} catch {
					Log(error.localizedDescription, type: .error)
				}
	}
	
	func update(_ pitch: AUValue, _ amp: AUValue) {
		data.pitch = pitch
		data.amplitude = amp * 1.4
		//data
		if(data.amplitude > (data.currentVolume + 0.02)){
			data.currentVolume += 0.01
			
		}else if(data.amplitude < (data.currentVolume - 0.02)){
			data.currentVolume -= 0.005
		}
		
		if(data.currentVolume > 1){
			data.currentVolume = 1
		}else if(data.currentVolume < 0){
			data.currentVolume = 0
		}
		player.volume = data.currentVolume + 0.01
	}
}

struct MicrophoneView: View {
	@StateObject var conductor = MicrophoneConductor()
	
	var body: some View {
		VStack {
			HStack {
				Text("Frequency")
				Spacer()
				//Text("\(conductor.data.pitch, specifier: "%0.01f")")
			}.padding()
			
			HStack {
				Text("Amplitude")
				Spacer()
				//Text("\(conductor.data.amplitude, specifier: "%0.01f")")
			}.padding()
			//				HStack{
			//					Spacer()
			//					SmallKnob(value: self.$conductor.data.amplitude, range: 0 ... 3).padding(20)
			//					SmallKnob(value: self.$conductor.data.pitch, range: 0 ... 200).padding(20)
			//					Spacer()
			//
			//				}
			InputDevicePicker(device: conductor.initialDevice)
			NodeOutputView(conductor.tappableNodeA).clipped()
			
			
		}
		
		.onAppear {
			print("appeared")
			//conductor.start()
			conductor.player.play()
		}
		.onDisappear {
			print("stopped")
			conductor.stop()
		}
	}
}

struct InputDevicePicker: View {
	@State var device: Device
	
	var body: some View {
		Picker("Input: \(device.deviceID)", selection: $device) {
			ForEach(getDevices(), id: \.self) {
				Text($0.deviceID)
			}
		}
		.pickerStyle(MenuPickerStyle())
		.onChange(of: device, perform: setInputDevice)
	}
	
	func getDevices() -> [Device] {
		AudioEngine.inputDevices.compactMap { $0 }
	}
	
	func setInputDevice(to device: Device) {
		do {
			try AudioEngine.setInputDevice(device)
		} catch let err {
			print(err)
		}
	}
}

