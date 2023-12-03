//
//  UpdateCard.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 10/27/21.
//

import SwiftUI
import LinkPresentation

struct UpdateCard: View {
    var chatRepository = ChatRepository()
    @EnvironmentObject var chatDataModel: ChatDataModel
    @EnvironmentObject var contactRepository: ContactRepository
    var update: Update
    @State var redrawPreview = false
    @State private var showReplyView: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Image(systemName: "number")
                    .font(.title)
                VStack(alignment: .leading) {
                    GroupNameView(isChat: update.isChat, groupName: update.groupName)
                    Text("\(update.groupName): \(update.channelName)")
                        .font(.subheadline)
                }
                Spacer()
                Button(action: {
                    
                }) {
                    Image(systemName: "arrowshape.turn.up.backward.fill")
                }
                .onTapGesture {
                    showReplyView.toggle()
                }
                
            }
            if update.type.contains(UpdateType.link) {
//                Link(destination: URL(string: update.message.links.first!)!) {
//                    MessageContentView(message: update.message, contactRepository: contactRepository)
//                }
                LinkRow(previewURL: URL(string: update.message.links.first!)!, redraw: $redrawPreview)
            } else {
//                AttributedMessageContentView(message: update.message, contactRepository: contactRepository)
            }
        }
        .background(NavigationLink( destination: ChatDetailView(model: ChatDetailView.Model(chat: chatDataModel.chats[update.group] ?? ChatGroup(group: update.group, groupName: update.groupName, isChat: update.isChat), contactRepository: contactRepository))){
            EmptyView()
        })
//        ZStack {
//
//        }
//        .frame(
//            maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/,
//            alignment: .leading
//        )
        .sheet(isPresented: $showReplyView, content: {
            ReplyView(update: update)
        })
    }
}

struct UpdateCard_Previews: PreviewProvider {
    static var previews: some View {
        UpdateCard(update: UpdateView.Model().messages[3])
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct LinkRow : UIViewRepresentable {
    
    var previewURL:URL
    
    @Binding var redraw: Bool
    
    func makeUIView(context: Context) -> LPLinkView {
        let view = LPLinkView(url: previewURL)
        
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: previewURL) { (metadata, error) in
            if let md = metadata {
                md.imageProvider = nil
                DispatchQueue.main.async {
                    view.metadata = md
                    view.sizeToFit()
                    self.redraw.toggle()
                }
            }
            else if error != nil
            {
                let md = LPLinkMetadata()
                md.title = "No title"
                view.metadata = md
                view.sizeToFit()
                self.redraw.toggle()
            }
        }
        
        return view
    }
    
    func updateUIView(_ view: LPLinkView, context: Context) {
        // New instance for each update
    }
}
