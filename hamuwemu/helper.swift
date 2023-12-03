//
//  helper.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 9/30/21.
//

import Foundation
import UIKit
import FirebaseAuth

func unimplemented<T>(message: String = "", file: StaticString = #file, line: UInt = #line) -> T{
    fatalError("unimplemented: \(message)", file: file, line: line)
}

struct DatabaseHelper {
    static let pathUsers = "users"
    static let pathUserContacts = "userContacts"
    static let pathUserGroups = "userGroups"
    static let pathUserChats = "userChats"
    static let pathUserChatIDs = "userChatIDs"
    static let pathUserChannels = "userChannels"
    static let pathUserThreads = "userThreads"
    static let pathUserUpdates = "userUpdates"
    static let pathUserMessages = "userMessages"
    static let pathGroups = "groups"
    static let pathChannels = "channels"
    static let pathThreads = "threads"
    static let pathChannelMessages = "channelMessages"
    static let pathThreadMessages = "threadMessages"
    static let pathMessageReceipts = "messageReceipts"
    static let pathUserChannelMessages = "userChannelMessages"
    static let pathUserThreadMessages = "userThreadMessages"
}

struct SignUpError: Identifiable {
    var id: String { msg }
    let msg: String
}

class PushIdGenerator {
    private init() {}
    static let shared = PushIdGenerator()
    
    /// custom unique identifier
    /// @see https://www.firebase.com/blog/2015-02-11-firebase-unique-identifiers.html
    private let PUSH_CHARS = Array("-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz")
    private var lastPushTime: UInt64 = 0
    private var lastRandChars = Array<Int>(repeating: 0, count: 12)

    func generatePushID(ascending: Bool = true) -> String {
        
      var now = UInt64(NSDate().timeIntervalSince1970 * 1000)
      let duplicateTime = (now == lastPushTime)
      lastPushTime = now
        
        var timeStampChars = Array<Character>(repeating: PUSH_CHARS.first!, count: 8)

        for i in stride(from: 7, through: 0, by: -1) {
                    timeStampChars[i] = PUSH_CHARS[Int(now % 64)]
                    now >>= 6
                }

      assert(now == 0, "We should have converted the entire timestamp.")
      var id: String = String(timeStampChars)

      if !duplicateTime {
          for i in 0..<12 {
                          lastRandChars[i] = Int(floor(Double.random(in: 0..<1) * 64))
                      }
      } else {
          var i = 11
                      while i >= 0 && lastRandChars[i] == 63 {
                          lastRandChars[i] = 0
                          i -= 1
                      }
                      lastRandChars[i] += 1
      }

      for i in 0..<12 { id.append(PUSH_CHARS[lastRandChars[i]]) }
        assert(id.count == 20, "Length should be 20.")
      return id
    }
}

func urlForImage(nameOfImage : String, group: String) -> URL? {
    FileManager.appGroupDirectory?.appendingPathComponent(group).appendingPathComponent(nameOfImage)
}

func loadImageFromDocumentDirectory(nameOfImage : String, group: String) -> UIImage? {
//            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
//            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
//            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
//            if let dirPath = paths.first{
//                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameOfImage)
//                let image    = UIImage(contentsOfFile: imageURL.path)
//                return image!
//            }
    if let imageURL = urlForImage(nameOfImage: nameOfImage, group: group),
       let image    = UIImage(contentsOfFile: imageURL.path) {
        return image
    }
    
    return nil
}

func saveImageToDocumentDirectory(image: UIImage, group: String, fileName: String, saveToCameraRoll: Bool = false) -> String? {
    let documentsDirectory = FileManager.appGroupDirectory!
    let groupFolder = documentsDirectory.appendingPathComponent(group)
    
    do {
        try FileManager.default.createDirectory(
            at: groupFolder,
            withIntermediateDirectories: false,
            attributes: nil
        )
    } catch CocoaError.fileWriteFileExists {
        // Folder already existed
    } catch {
        print("Error while creating group folder")
    }
    
   
    let fileURL = groupFolder.appendingPathComponent(fileName)
    if let data = image.jpeg(.lowest),!FileManager.default.fileExists(atPath: fileURL.path){
        do {
            try data.write(to: fileURL)
            print("file saved \(fileName)")
            if saveToCameraRoll {
                ImageSaver().writeToPhotoAlbum(image: image)
            }
            
            return fileName
        } catch {
            print("error saving file:", error)
        }
    }
    
    
    
    return nil
}

// for use with NSAttributedString obtained from InputBarAccesoryView
func getMessage(from attributedText: NSAttributedString, with content: String) -> HwMessage{
    guard !content.isEmpty else {
        return HwMessage(content: nil, mentions: [], links: [], imageDocumentUrl: nil, imageDownloadUrl: nil, imageBlurHash: nil)
    }
    
    // Here we can parse for which substrings were autocompleted
    let range = NSRange(location: 0, length: attributedText.length)
    var mentions = [Mention]()
    var replacements = [NSRange: (uid: String, phoneNumber: String)]()
    attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (attributes, range, stop) in
        
        let substring = attributedText.attributedSubstring(from: range)
        
        
        if substring.string.hasPrefix("@") {
            print("Autocompleted: attributed substring \(substring.string)")
            guard let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil) as? [String: String] else {return}
            if !context.isEmpty {
                let uid = context["uid"]!
                let phoneNumber = context["phoneNumber"]!
                replacements[range] = (uid, phoneNumber)
            }
        }
        
    }
    
    var content = content
    
    let sortedKeys = replacements.keys.sorted { $0.lowerBound < $1.lowerBound }
    var accDiff = 0
    for rangeKey in sortedKeys {
        let location = rangeKey.location + accDiff
        let currRange = NSMakeRange(rangeKey.location + accDiff, rangeKey.length)
        guard let subrange = Range(currRange, in: content) else {continue}
        guard let context = replacements[rangeKey] else {continue}
        let replacement = "@\(context.phoneNumber)"
        
//        let lowerBound = content.index(subrange.lowerBound, offsetBy: accDiff)
//        let upperBound = content.index(subrange.upperBound, offsetBy: accDiff)
        
        let lowerBound = subrange.lowerBound
        let upperBound = subrange.upperBound
        
        let curr = content[lowerBound ..< upperBound]
//        print("Autocompleted: replacing", curr, "` with: ", replacement, " in ", content)
        print("Autocompleted: replacing `\(curr)` with: `\(replacement)` in `\(content)`")
        // use utf16 count because NSRange in NSAttributedString uses utf16 count for location
        // and length
        let diff = replacement.utf16.count - curr.utf16.count
        
        content.replaceSubrange(lowerBound ..< upperBound, with: replacement)
        accDiff += diff
        
//        let location = content.distance(from: content.startIndex, to: lowerBound)
        
        // use utf16 count for indexes sent to the server. because calculating String.Index requires NSRange
        // NSRange uses utf16 count for length
        let newRange = NSMakeRange(location, replacement.utf16.count)
//                        content.replaceSubrange(Range(newRange, in: content)!, with: newRange.description)
        let mention = Mention( range: newRange, uid: context.uid, phoneNumber: context.phoneNumber)
        mentions.append(mention)
    }
    
    var links:[String] = []
    
    if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
        let matches = detector.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
    
        for match in matches {
            guard let range = Range(match.range, in: content) else { continue }
            let url = content[range]
            links.append(url.description)
            print(url)
        }
    }
    
    // 1
    let message = HwMessage(content: content, mentions: mentions, links: links)
    
    return message
}

func getMessage(from attributedText: NSAttributedString) -> HwMessage {
    let range = NSRange(location: 0, length: attributedText.length)
    var mentions = [Mention]()
    
    attributedText.enumerateAttribute(.mention, in: range, options: []) { (attributes, range, stop) in
        
        let substring = attributedText.attributedSubstring(from: range)
        
        
        if substring.string.hasPrefix("@") {
            print("Mention: attributed substring \(substring.string)")
            guard let context = substring.attribute(.mentionContext, at: 0, effectiveRange: nil) as? [String: String] else {return}
            if !context.isEmpty {
                let uid = context["uid"]!
                let phoneNumber = context["phoneNumber"]!
                let mention = Mention( range: range, uid: uid, phoneNumber: phoneNumber)
                mentions.append(mention)
            }
        }
        
    }
    
    var links:[String] = []
    
    let content = attributedText.string
    if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
        let matches = detector.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
    
        for match in matches {
            guard let range = Range(match.range, in: content) else { continue }
            let url = content[range]
            links.append(url.description)
            print(url)
        }
    }
    
    let message = HwMessage( content: content, mentions: mentions, links: links)
    
    return message
}

func getThreadCreatedSystemMessage(from message: HwMessage) -> NSAttributedString {
    guard let content = message.content else {
        return NSAttributedString()
    }
    
    let attrString = NSMutableAttributedString(string: content)
    
    for mention in message.mentions {
        let context = ["uid": mention.uid,
                       "phoneNumber": mention.phoneNumber]
        attrString.addAttribute(.mention, value: URL(string: "mention:\(mention.uid)")!, range: mention.range)
        attrString.addAttribute(.mentionContext, value: context, range: mention.range)
    
    }
    
    return NSAttributedString(attributedString: attrString)
}

//for string loaded from core data
func modifiedAttributedString(from text: NSAttributedString, contactRepository: ContactRepository, authenticationService: AuthenticationService = .shared) -> NSAttributedString {
//    let authenticationService: AuthenticationService = .shared
    var temp = text.string
    
    let attrs = [
        NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
        NSAttributedString.Key.foregroundColor: UIColor.label
    ]
    var attrString = NSMutableAttributedString(string: temp, attributes: attrs)
    if let phoneNumber = authenticationService.phoneNumber {
        
        let displayName = authenticationService.displayName ?? "You"
        
        var modifiedMentions = [(uid: String, matchRange: NSRange, prefixRange: NSRange)]()
        
        let range = NSRange(location: 0, length: text.length)
        var replacements = [NSRange: (uid: String, phoneNumber: String)]()
        text.enumerateAttribute(.mention, in: range, options: []) { (attributes, range, stop) in
            
            let substring = text.attributedSubstring(from: range)
            
            
            if substring.string.hasPrefix("@") {
                print("Mention: attributed substring \(substring.string)")
                guard let context = substring.attribute(.mentionContext, at: 0, effectiveRange: nil) as? [String: String] else {return}
                if !context.isEmpty {
                    let uid = context["uid"]!
                    let phoneNumber = context["phoneNumber"]!
                    replacements[range] = (uid, phoneNumber)
                }
            }
            
        }
        
        let sortedKeys = replacements.keys.sorted { $0.lowerBound < $1.lowerBound }
        var accDiff = 0
        for rangeKey in sortedKeys {
            let currRange = NSMakeRange(rangeKey.location + accDiff, rangeKey.length)
            guard let subrange = Range(currRange, in: temp) else {continue}
            guard let context = replacements[rangeKey] else {continue}
            
            
            var name = context.phoneNumber
            if context.phoneNumber == phoneNumber {
                name = displayName
            } else {
                name = contactRepository.getFullName(for: context.phoneNumber)
            }
            
            let replacement = "@\(name)"
            
            let lowerBound = subrange.lowerBound
            let upperBound = subrange.upperBound
            
            let curr = temp[lowerBound ..< upperBound]
            print("Mention: replacing `\(curr)` with: `\(replacement)` in `\(temp)`")
            // use utf16 count because NSRange in NSAttributedString uses utf16 count for location
            // and length
            let diff = replacement.utf16.count - curr.utf16.count
            
            temp.replaceSubrange(lowerBound ..< upperBound, with: replacement)
            
            let location = currRange.location + 1
            let length =  name.utf16.count
            let matchRange = NSMakeRange(location, length)
            let prefixRange = NSMakeRange(currRange.location, 1)
            
            modifiedMentions.append((context.uid, matchRange, prefixRange))
            accDiff += diff
        }
        
        attrString = NSMutableAttributedString(string:temp, attributes:attrs)
        
//            private let mentionTextAttributes: [NSAttributedString.Key : Any] = [
//                .font: UIFont.preferredFont(forTextStyle: .body),
//                .foregroundColor: UIColor.systemBlue,
//                .backgroundColor: UIColor.systemBlue.withAlphaComponent(0.1)
//            ]
        
        for mention in modifiedMentions {
            //                    attrString.addAttribute(NSAttributedString.Key.link, value: "mention://\(mention.uid)", range: mention.matchRange)
            attrString.addAttribute(NSAttributedString.Key.link, value: URL(string: "mention:\(mention.uid)")!, range: mention.matchRange)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemBlue, range: mention.matchRange)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkGray, range: mention.prefixRange)
        
        }
        
    }
    
    return NSAttributedString(attributedString: attrString)
}

func attributedString(with message: HwMessage, contactRepository: ContactRepository) -> NSAttributedString {
    guard let content = message.content else {
        return NSAttributedString()
    }
    let authenticationService: AuthenticationService = .shared
    var temp = content
    
    let attrs = [
        NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
        NSAttributedString.Key.foregroundColor: UIColor.label
    ]
    var attrString = NSMutableAttributedString(string: temp, attributes: attrs)
    if let phoneNumber = authenticationService.phoneNumber{
        
        let displayName = authenticationService.displayName ?? "You"
        
        var modifiedMentions = [String: (uid: String, matchRange: NSRange, prefixRange: NSRange)]()
        
        let sortedMentions = message.mentions.sorted { $0.range.location < $1.range.location }
        var accDiff = 0
        for mention in sortedMentions {
            let nsRange = NSMakeRange(mention.range.location + accDiff, mention.range.length)
            guard let subrange = Range(nsRange, in: temp) else {continue}
            
            var name = mention.phoneNumber
            if mention.phoneNumber == phoneNumber {
                name = displayName
            } else {
                name = contactRepository.getFullName(for: mention.phoneNumber)
            }
            
            let replacement = "@\(name)"
            
//            let lowerBound = temp.index(subrange.lowerBound, offsetBy: accDiff)
//            let upperBound = temp.index(subrange.upperBound, offsetBy: accDiff)
            
            let curr = temp[subrange.lowerBound ..< subrange.upperBound]
            print("Mention: replacing `\(curr)` with: `\(replacement)` in `\(temp)`")
            let diff = replacement.utf16.count - curr.utf16.count
            
            temp.replaceSubrange(subrange.lowerBound ..< subrange.upperBound, with: replacement)
            
            
            let location = mention.range.location + accDiff + 1
            let length =  name.utf16.count
            let matchRange = NSMakeRange(location, length)
            let prefixRange = NSMakeRange(mention.range.location + accDiff , 1)
            
            modifiedMentions[mention.id] = (mention.uid, matchRange, prefixRange)
            
            accDiff += diff
        }
        
//        for mention in sortedMentions {
//            var name = mention.phoneNumber
//            if mention.phoneNumber == phoneNumber {
//                name = displayName
//            } else if let fullName = contactRepository.getFullName(for: mention.phoneNumber) {
//                name = fullName
//            }
//
//            guard let range = Range(mention.range, in: temp) else {continue}
//            temp.replaceSubrange(range, with: "@\(name)")
//            //                let word = String(temp[range])
//            //                var stringifiedWord:String = word
//            //                stringifiedWord = String(stringifiedWord.dropFirst())
//            let location = mention.range.location + 1
//            let length =  name.count
//            let matchRange = NSMakeRange(location, length)
//            let prefixRange = NSMakeRange(mention.range.location , 1)
//
//            modifiedMentions[mention.id] = (mention.uid, matchRange, prefixRange)
//        }
        
        attrString = NSMutableAttributedString(string:temp, attributes:attrs)
        
        for (_ , mention) in modifiedMentions {
            //                    attrString.addAttribute(NSAttributedString.Key.link, value: "mention://\(mention.uid)", range: mention.matchRange)
            attrString.addAttribute(NSAttributedString.Key.link, value: URL(string: "mention:\(mention.uid)")!, range: mention.matchRange)
            attrString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.darkGray, range: mention.prefixRange)
        
        }
        
    }
    
    return NSAttributedString(attributedString: attrString)
}
