import Foundation

/// en / ru texts, inlined so the module builds standalone. Move to Localizable.strings when merging.
public struct MyChannelsStrings {
    public let isRussian: Bool

    public init(languageCode: String) {
        self.isRussian = languageCode.hasPrefix("ru")
    }

    public var myChannels: String { self.isRussian ? "Мои каналы" : "My Channels" }
    public var myBots: String { self.isRussian ? "Мои боты" : "My Bots" }
    public var channelsTab: String { self.isRussian ? "Каналы" : "Channels" }
    public var botsTab: String { self.isRussian ? "Боты" : "Bots" }
    public var createChannel: String { self.isRussian ? "Создать канал" : "Create Channel" }
    public var createBot: String { self.isRussian ? "Создать бота" : "Create Bot" }
    public var owner: String { self.isRussian ? "Владелец" : "Owner" }
    public var admin: String { self.isRussian ? "Админ" : "Admin" }
    public var channelsFooter: String { self.isRussian ? "Каналы, которыми вы владеете или управляете." : "Channels you own or manage." }
    public var botsFooter: String { self.isRussian ? "Боты, созданные вами в @BotFather." : "Bots you created with @BotFather." }

    /// "4 channels · 21.4K subscribers"
    public func channelsSummary(count: Int, subscribers: Int) -> String {
        return "\(self.plural(count, one: "channel", many: "channels", ruOne: "канал", ruFew: "канала", ruMany: "каналов")) · \(self.subscribers(subscribers, compact: true))"
    }

    /// "3 bots · 8.6K monthly users"
    public func botsSummary(count: Int, users: Int) -> String {
        return "\(self.plural(count, one: "bot", many: "bots", ruOne: "бот", ruFew: "бота", ruMany: "ботов")) · \(self.monthlyUsers(users, compact: true))"
    }

    public func subscribers(_ value: Int, compact: Bool = false) -> String {
        return self.plural(value, one: "subscriber", many: "subscribers", ruOne: "подписчик", ruFew: "подписчика", ruMany: "подписчиков", compact: compact)
    }

    public func monthlyUsers(_ value: Int, compact: Bool = false) -> String {
        if self.isRussian {
            return "\(compact ? myChannelsCompactCount(value) : myChannelsGroupedCount(value, separator: "\u{00A0}")) в месяц"
        }
        return "\(compact ? myChannelsCompactCount(value) : myChannelsGroupedCount(value, separator: ",")) monthly users"
    }

    func plural(_ value: Int, one: String, many: String, ruOne: String, ruFew: String, ruMany: String, compact: Bool = false) -> String {
        let number = compact ? myChannelsCompactCount(value) : myChannelsGroupedCount(value, separator: self.isRussian ? "\u{00A0}" : ",")
        if self.isRussian {
            return "\(number) \(compact && value >= 1000 ? ruMany : myChannelsRussianPlural(value, one: ruOne, few: ruFew, many: ruMany))"
        }
        return "\(number) \(value == 1 ? one : many)"
    }
}

/// 21_400 → "21.4K", 1_250_000 → "1.2M", 689 → "689"
public func myChannelsCompactCount(_ value: Int) -> String {
    func format(_ v: Double, _ suffix: String) -> String {
        let rounded = (v * 10.0).rounded(.down) / 10.0
        if rounded == rounded.rounded(.down) {
            return "\(Int(rounded))\(suffix)"
        }
        return String(format: "%.1f%@", rounded, suffix)
    }
    if value >= 1_000_000 {
        return format(Double(value) / 1_000_000.0, "M")
    } else if value >= 1_000 {
        return format(Double(value) / 1_000.0, "K")
    }
    return "\(value)"
}

/// 12480 → "12,480"
public func myChannelsGroupedCount(_ value: Int, separator: String) -> String {
    let digits = Array(String(abs(value)))
    var result = ""
    for (index, digit) in digits.enumerated() {
        if index > 0 && (digits.count - index) % 3 == 0 {
            result += separator
        }
        result.append(digit)
    }
    return value < 0 ? "-" + result : result
}

public func myChannelsRussianPlural(_ value: Int, one: String, few: String, many: String) -> String {
    let mod100 = value % 100, mod10 = value % 10
    if mod100 >= 11 && mod100 <= 14 {
        return many
    }
    switch mod10 {
    case 1: return one
    case 2, 3, 4: return few
    default: return many
    }
}
