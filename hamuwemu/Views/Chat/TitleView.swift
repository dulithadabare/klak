//
//  TitleView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-03-03.
//

import SwiftUI

struct TitleView: View {
    @EnvironmentObject var authenticationService: AuthenticationService
    var title: String
    @State private var networkStatus: ClientNetworkStatus = .disconnected
    var body: some View {
        Group {
            if networkStatus == .connecting {
                HStack {
                    ProgressView()
                    Text("Connecting..").font(.headline)
                }
            } else if networkStatus == .waitingForNetwork {
                HStack {
                    ProgressView()
                    Text("Waiting for Network..").font(.headline)
                }
            } else {
                EmptyView()
            }
        }
        .onReceive(authenticationService.account.$networkStatus) { status in
            networkStatus = status
        }
    }
}

struct TitleView_Previews: PreviewProvider {
    static var previews: some View {
        TitleView(title: "Chats")
            .environmentObject(AuthenticationService.preview)
    }
}
