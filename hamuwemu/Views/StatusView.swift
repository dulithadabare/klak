//
//  StatusView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/28/21.
//

import SwiftUI

struct UpdateView: View {
    @EnvironmentObject var status : StatusStore
    @State private var showSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                UpdateCard()
            }
            .navigationTitle("Updates")
            .navigationBarTitleDisplayMode(.large)

        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateView()
            .environmentObject(StatusStore())
    }
}

struct UpdateCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Image(systemName: "number")
                    .font(.title)
                VStack(alignment: .leading) {
                    Text("Dulitha")
                    Text("Channel Name")
                        .font(.subheadline)
                }
                
            }
            Text("Content")
        }
        .frame(
            maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/,
            alignment: .leading
        )
    }
}
