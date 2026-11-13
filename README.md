# My Channels & My Bots — in New Message

Everything you run, one tap from the compose button.
**New Message** gets two rows under *New Channel*: **My Channels** and **My Bots**, with counts and avatars.
They open one screen with two tabs: your channels with subscribers, your bots with monthly users.

## How it works

| Step | Behaviour | Code |
|---|---|---|
| Rows | Compose → *New Message*. Under New Group / New Contact / New Channel: **My Channels** · *4 channels · 21.4K subscribers* and **My Bots** · *3 bots · 8.6K monthly users*, three avatars and a disclosure arrow. Hidden when the account owns nothing. | `myChannelsComposeOptions`, `ContactListAdditionalOption.accessoryImage` |
| Channels | Public channels you administer + private ones you can post to, broadcast only, largest first. *Owner* or *Admin* on the right. | `myChannelsState` — `adminedPublicChannels`, `channelsForStories`, `ParticipantCount` |
| Bots | Bots you own with `@username · 5,920 monthly users`. | `TelegramEngine.Peers.adminedBots()` (`bots.getAdminedBots`, `bot_active_users`) |
| Tabs | One screen, *Channels 4 · Bots 3* in the title, like channel statistics. | `ItemListController`, `.textWithTabs` |
| Actions | Tap a row → the chat. *Create Channel* → the usual New Channel flow. *Create Bot* → @BotFather. | `myChannelsController(openPeer:createChannel:)` |

Strings: English and Russian.

## Files

```
submodules/MyChannelsUI/                        new module (Bazel swift_library)
  Sources/MyChannelsData.swift                  channels + bots, counts, sorting
  Sources/MyChannelsComposeOptions.swift        the two New Message rows, avatar stack
  Sources/MyChannelsController.swift            the Channels / Bots screen
  Sources/MyChannelsStrings.swift               en / ru, compact counts, plurals
  Tests/MyChannelsTests.swift                   sorting, counts, plurals
patches/0001-my-channels-integration.patch      TelegramCore, ContactListUI, AccountContext, TelegramUI
```

The patch:
- `TelegramCore` — `TelegramEngine.Peers.adminedBots()` over `bots.getAdminedBots`;
- `AccountContext` / `ContactListUI` — `ContactListAdditionalOption.accessoryImage`, drawn by `ContactListActionItem` before a disclosure arrow;
- `TelegramUI` — `ComposeControllerNode` appends the rows, `ComposeController` pushes the screen.

## Install

Base: `TelegramMessenger/Telegram-iOS` master `24638bc` (the patch applies cleanly).

```bash
cd Telegram-iOS
cp -R /path/to/telegram-ios-my-channels/submodules/MyChannelsUI submodules/
git apply /path/to/telegram-ios-my-channels/patches/0001-my-channels-integration.patch
```

`MyChannelsStrings` inlines en/ru so the module builds standalone; move the texts to `Localizable.strings` when merging.
For the tests add an `ios_unit_test` target for `Tests/`, like `ChatListUITests` in `ChatListUI/BUILD`.

Written against the sources of `24638bc`; not built locally (the string and sorting logic was checked with `swiftc`).
