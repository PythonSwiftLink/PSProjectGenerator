//
//  ContentView.swift
//  testoutout
//
//  Created by CodeBuilder on 08/10/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}


struct PreviewTest: PreviewProvider {
	
	static var previews: some View {
		ContentView()
	}
	
	
}
//#Preview {
//    ContentView()
//}
