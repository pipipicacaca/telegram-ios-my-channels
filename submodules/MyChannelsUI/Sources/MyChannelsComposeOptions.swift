import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AccountContext
import AppBundle
import AvatarNode

private let stackAvatarSize: CGFloat = 24.0
private let stackBorder: CGFloat = 2.0
private let stackOverlap: CGFloat = 7.0

/// Up to three avatars, each over the previous one, with a ring of the row background.
func myChannelsAvatarStack(context: AccountContext, peers: [EnginePeer], borderColor: UIColor) -> Signal<UIImage?, NoError> {
    let peers = Array(peers.prefix(3))
    if peers.isEmpty {
        return .single(nil)
    }
    let size = CGSize(width: stackAvatarSize, height: stackAvatarSize)
    return combineLatest(peers.map { peerAvatarCompleteImage(account: context.account, peer: $0, size: size, font: avatarPlaceholderFont(size: 10.0)) })
    |> map { images -> UIImage? in
        let outer = stackAvatarSize + stackBorder * 2.0
        let width = outer + CGFloat(images.count - 1) * (outer - stackOverlap)
        return generateImage(CGSize(width: width, height: outer), rotatedContext: { contextSize, c in
            c.clear(CGRect(origin: CGPoint(), size: contextSize))
            for (index, image) in images.enumerated() {
                let x = CGFloat(index) * (outer - stackOverlap)
                c.setBlendMode(.copy)
                c.setFillColor(borderColor.cgColor)
                c.fillEllipse(in: CGRect(x: x, y: 0.0, width: outer, height: outer))
                c.setBlendMode(.normal)
                if let cgImage = image?.cgImage {
                    c.saveGState()
                    c.translateBy(x: 0.0, y: contextSize.height)
                    c.scaleBy(x: 1.0, y: -1.0)
                    c.draw(cgImage, in: CGRect(x: x + stackBorder, y: stackBorder, width: stackAvatarSize, height: stackAvatarSize))
                    c.restoreGState()
                }
            }
        })
    }
}

/// «My Channels» and «My Bots» rows for the New Message screen, below New Group / New Contact / New Channel.
/// A row is shown only when the account has at least one channel or bot.
public func myChannelsComposeOptions(context: AccountContext, open: @escaping (MyChannelsSection) -> Void) -> Signal<[ContactListAdditionalOption], NoError> {
    return combineLatest(context.sharedContext.presentationData, myChannelsState(context: context))
    |> mapToSignal { presentationData, state -> Signal<[ContactListAdditionalOption], NoError> in
        let strings = MyChannelsStrings(languageCode: presentationData.strings.baseLanguageCode)
        let borderColor = presentationData.theme.list.itemBlocksBackgroundColor
        return combineLatest(
            myChannelsAvatarStack(context: context, peers: state.channels.map(\.peer), borderColor: borderColor),
            myChannelsAvatarStack(context: context, peers: state.bots.map(\.peer), borderColor: borderColor)
        )
        |> map { channelsStack, botsStack -> [ContactListAdditionalOption] in
            var options: [ContactListAdditionalOption] = []
            if !state.channels.isEmpty, let icon = UIImage(bundleImageName: "Chat/Context Menu/Channels") {
                options.append(ContactListAdditionalOption(title: strings.myChannels, subtitle: strings.channelsSummary(count: state.channels.count, subscribers: state.totalSubscribers), icon: .generic(icon), action: {
                    open(.channels)
                }, accessoryImage: channelsStack))
            }
            if !state.bots.isEmpty, let icon = UIImage(bundleImageName: "Peer Info/BotSettings") {
                options.append(ContactListAdditionalOption(title: strings.myBots, subtitle: strings.botsSummary(count: state.bots.count, users: state.totalBotUsers), icon: .generic(icon), action: {
                    open(.bots)
                }, accessoryImage: botsStack))
            }
            return options
        }
    }
}
