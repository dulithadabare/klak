//
//  AddChannelView.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 11/17/21.
//

import SwiftUI

import Combine

struct AddChannelView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var channelListModel: ChannelListView.Model
    @StateObject var model = Model()
    @State private var firstName: String = ""
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section{
                        TextField("Channel Name", text: $firstName)
                    }
                }
            }
            .navigationTitle("New Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        model.add(name: firstName)
                            presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                    }
                    .disabled({firstName.isEmpty}())
                }
            }
            .onAppear {
                model.channelListModel = channelListModel
            }
        }
    }
}

struct AddChannelView_Previews: PreviewProvider {
    static var previews: some View {
        AddChannelView( channelListModel: ChannelListView.Model(chat: ChatGroup(groupName: "PREVIEW"), contactRepository: ContactRepository.preview))
    }
}

extension AddChannelView {
    class Model: ObservableObject {
        @Published var items: [ChannelListItem] = []
        var channelListModel: ChannelListView.Model?
        @Published var alertMessage = ""
        @Published var alert = false
        
        private var cancellables: Set<AnyCancellable> = []
        
        init() {
            #if DEBUG
            //            createDevData()
            #endif
        }
        
        func add(name: String){
            guard let channelListModel = channelListModel else { return }
            channelListModel.add(name: name)
        }
    }
}
