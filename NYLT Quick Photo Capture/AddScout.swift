//
//  AddScout.swift
//  NYLT Quick Photo Capture
//
//  Created by Aroon Narayanan on 1/1/20.
//  Copyright © 2020 Atlanta Area Council NYLT. All rights reserved.
//

import SwiftUI

struct AddScout: View {
    var body: some View {
        VStack() {
                Text("First Name")
                Text("Last Name")
            Spacer()
            Button("Add Scout") {}
        }.padding()
    }
}

struct AddScout_Previews: PreviewProvider {
    static var previews: some View {
        AddScout()
    }
}
