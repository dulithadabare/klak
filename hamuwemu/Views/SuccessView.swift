//
//  SuccessView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/18/21.
//

import SwiftUI

struct SuccessView: View {
    let message = """
 Good job completing all four exercises!\n
 Remember tomorrow's another day.\n
 So eat well and get some rest
"""
    
    var body: some View {
        ZStack {
            VStack{
                Image(systemName:"hand.raised.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 75.0, height: 75.0)
                    .foregroundColor(.purple)
                Text(NSLocalizedString("High Five!", comment: "congratulate success")
)
                    .font(.title)
                    .fontWeight(.heavy)
    //            Text(message)
    //                .font(.subheadline)
    //                .foregroundColor(.gray)
    //                .multilineTextAlignment(.center)
                Text("Good job completing all four exercises!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Remember tomorrow's another day.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("So eat well and get some rest.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            VStack {
                Spacer()
                Button("Continue"){}
                    .padding()
            }
        }
    }
}

struct SuccessView_Previews: PreviewProvider {
    static var previews: some View {
        SuccessView()
    }
}
