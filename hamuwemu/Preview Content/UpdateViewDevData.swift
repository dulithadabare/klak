//
//  StatusStoreDevData.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/18/21.
//

import Foundation

extension UpdateView.Model {
    func createDevData() {
        // Development data
        messages = [
            Update(groupName: "Ada", channelName: "General", message: HwMessage(content: "Hello @Dulitha", sender: "+16505553535"), sender: "+16505553535", type: [.mention] ),
            Update(groupName: "Ada", channelName: "Kamu", message: HwMessage(content: "Ado @Dulitha", sender: "+16505553636"), sender: "+16505553636", type: [.mention]),
            Update(groupName: "Catan", channelName: "General", message: HwMessage(content: "https://colonist.io/#oKGX", sender: "+16505553737"), sender: "+16505553737", type: [.link]),
            Update(groupName: "Catan", channelName: "Deals", message: HwMessage(content: "https://discord.gg/gRYVXaxY", sender: "+16505553838"), sender: "+16505553838", type: [.mention]),
            Update(groupName: "Catan", channelName: "Memes", message: HwMessage(content: "Meme", sender: "+16505553636"), sender: "+16505553636", type: [.image]),
        ]
    }
}
