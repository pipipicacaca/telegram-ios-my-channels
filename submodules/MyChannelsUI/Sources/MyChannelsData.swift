import Foundation
import SwiftSignalKit
import TelegramCore
import AccountContext

public enum MyChannelsSection: Int {
    case channels = 0
    case bots = 1
}

public struct MyChannelsItem: Equatable {
    public let peer: EnginePeer
    /// Subscribers for a channel, monthly active users for a bot.
    public let count: Int?
    public let isCreator: Bool

    public init(peer: EnginePeer, count: Int?, isCreator: Bool) {
        self.peer = peer
        self.count = count
        self.isCreator = isCreator
    }
}

public struct MyChannelsState: Equatable {
    public var channels: [MyChannelsItem]
    public var bots: [MyChannelsItem]
    public var isLoaded: Bool

    public static let empty = MyChannelsState(channels: [], bots: [], isLoaded: false)

    public var totalSubscribers: Int {
        return self.channels.reduce(0, { $0 + ($1.count ?? 0) })
    }

    public var totalBotUsers: Int {
        return self.bots.reduce(0, { $0 + ($1.count ?? 0) })
    }
}

/// Largest first; unknown counts keep their order at the end.
public func myChannelsSorted<T>(_ items: [T], count: (T) -> Int?) -> [T] {
    return items.enumerated().sorted(by: { lhs, rhs in
        let l = count(lhs.element), r = count(rhs.element)
        switch (l, r) {
        case let (l?, r?) where l != r:
            return l > r
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        default:
            return lhs.offset < rhs.offset
        }
    }).map(\.element)
}

/// Unique ids in first-seen order.
public func myChannelsUnique<T>(_ items: [T], id: (T) -> EnginePeer.Id) -> [T] {
    var seen = Set<EnginePeer.Id>()
    return items.filter { seen.insert(id($0)).inserted }
}

/// Channels: public ones the account administers (`channels.getAdminedPublicChannels`)
/// plus private ones it can post to (`stories.getChatsToSend`), broadcast only.
/// Bots: `bots.getAdminedBots`, count = `bot_active_users`.
public func myChannelsState(context: AccountContext) -> Signal<MyChannelsState, NoError> {
    let channels: Signal<[EnginePeer], NoError> = combineLatest(
        context.engine.peers.adminedPublicChannels(scope: .all),
        context.engine.peers.channelsForStories()
    )
    |> map { publicChannels, storyChannels -> [EnginePeer] in
        let all = publicChannels.map(\.peer) + storyChannels
        let broadcast = all.filter { peer in
            if case let .channel(channel) = peer, case .broadcast = channel.info {
                return true
            }
            return false
        }
        return myChannelsUnique(broadcast, id: \.id)
    }

    return combineLatest(channels, context.engine.peers.adminedBots())
    |> mapToSignal { channels, bots -> Signal<MyChannelsState, NoError> in
        return context.engine.data.subscribe(EngineDataMap(channels.map { TelegramEngine.EngineData.Item.Peer.ParticipantCount(id: $0.id) }))
        |> map { counts -> MyChannelsState in
            let channelItems = channels.map { peer -> MyChannelsItem in
                var isCreator = false
                if case let .channel(channel) = peer {
                    isCreator = channel.flags.contains(.isCreator)
                }
                return MyChannelsItem(peer: peer, count: counts[peer.id] ?? nil, isCreator: isCreator)
            }
            let botItems = bots.map { peer -> MyChannelsItem in
                var users: Int?
                if case let .user(user) = peer {
                    users = user.subscriberCount.flatMap(Int.init)
                }
                return MyChannelsItem(peer: peer, count: users, isCreator: true)
            }
            return MyChannelsState(
                channels: myChannelsSorted(channelItems, count: \.count),
                bots: myChannelsSorted(myChannelsUnique(botItems, id: \.peer.id), count: \.count),
                isLoaded: true
            )
        }
    }
    |> distinctUntilChanged
}
