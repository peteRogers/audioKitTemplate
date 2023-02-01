//
//  ContentView.swift
//  audioKitTemplate
//
//  Created by Peter Rogers on 23/01/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
          
            AudioPlayerConsole()
            
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
