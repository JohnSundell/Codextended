<p align="center">
    <img src="Logo.png" width="480” max-width="90%" alt="Codextended" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
    <img src="https://img.shields.io/badge/platforms-mac+linux-brightgreen.svg?style=flat" alt="Mac + Linux" />
    <a href="https://twitter.com/johnsundell">
        <img src="https://img.shields.io/badge/twitter-@johnsundell-blue.svg?style=flat" alt="Twitter: @johnsundell" />
    </a>
</p>

Welcome to **Codextended** — a suite of extensions that aims to make Swift’s `Codable` API easier to use by giving it type inference-powered capabilities and conveniences. It’s not a wrapper, nor is it a brand new framework, instead it augments `Codable` directly in a very lightweight way.

## Codable is awesome!

No third-party serialization framework can beat the convenience of `Codable`. Since it’s built in, it can both leverage the compiler to automatically synthesize all serialization code needed in many situations, and it can also be used as a common bridge between multiple different modules — without having to introduce any shared dependencies.

However, once some form of customization is needed — for example to transform parts of the decoded data, or to provide default values for certain keys — the standard `Codable` API starts to become *really* verbose. It also doesn’t take advantage of Swift’s robust type inference capabilities, which produces a lot of unnecessary boilerplate.

That’s what **Codextended** aims to fix.

## Examples

Here are a few examples that demonstrate the difference between using “vanilla” `Codable` and the APIs that **Codextended** adds to it. The goal is to turn all common serialization operations into one-liners, rather than having to set up a ton of boilerplate.

### 🏢 Top-level API

**Codextended** makes a few slight tweaks to the top-level API used to encode and decode values, making it possible to leverage type inference and use methods on the actual values that are being encoded or decoded.

🍨 With vanilla `Codable`:

```swift
// Encoding
let encoder = JSONEncoder()
let data = try encoder.encode(value)

// Decoding
let decoder = JSONDecoder()
let article = try decoder.decode(Article.self, from: data)
```

🦸‍♀️ With **Codextended**:

```swift
// Encoding
let data = try value.encoded()

// Decoding
let article = try data.decoded() as Article

// Decoding when the type can be inferred
try saveArticle(data.decoded())
```

### 🔑 Overriding the behavior for a single key

While `Codable` is amazing as long as the serialized data’s format exactly matches the format of the Swift types that’ll use it — as soon as we need to make just a small tweak, things quickly go from really convenient to very verbose.

As an example, let’s just say that we want to provide a default value for one single property (without having to make it an optional, which would make it harder to handle in the rest of our code base). To do that, we need to completely manually implement our type’s decoding — like below for the `tags` property of an `Article` type.

🍨 With vanilla `Codable`:

```swift
struct Article: Codable {
    enum CodingKeys: CodingKey {
        case title
        case body
        case footnotes
        case tags
    }

    var title: String
    var body: String
    var footnotes: String?
    var tags: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        footnotes = try container.decodeIfPresent(String.self, forKey: .footnotes)
        tags = (try? container.decode([String].self, forKey: .tags)) ?? []
    }
}
```

🦸‍♂️ With **Codextended**:

```swift
struct Article: Codable {
    var title: String
    var body: String
    var footnotes: String?
    var tags: [String]

    init(from decoder: Decoder) throws {
        title = try decoder.decode("title")
        body = try decoder.decode("body")
        footnotes = try decoder.decodeIfPresent("footnotes")
        tags = (try? decoder.decode("tags")) ?? []
    }
}
```

**Codextended** includes decoding overloads both for `CodingKey`-based values and for string literals, so that we can pick the approach that’s the most appropriate/convenient for each given situation.

### 📆 Using date formatters

`Codable` already comes with support for custom date formats through assigning a `DateFormatter` to either a `JSONEncoder` or `JSONDecoder`. However, requiring each call site to be aware of the specific date formats used for each type isn’t always great — so with **Codextended**, it’s easy for a type itself to pick what date format it needs to use.

That’s really convenient when working with third-party data, and we only want to customize the date format for some of our types, or when we want to produce more readable date strings when encoding a value.

🍨 With vanilla `Codable`:

```swift
struct Bookmark: Codable {
    enum CodingKeys: CodingKey {
        case url
        case date
    }

    struct DateCodingError: Error {}

    static let dateFormatter = makeDateFormatter()

    var url: URL
    var date: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)

        let dateString = try container.decode(String.self, forKey: .date)

        guard let date = Bookmark.dateFormatter.date(from: dateString) else {
            throw DateCodingError()
        }

        self.date = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)

        let dateString = Bookmark.dateFormatter.string(from: date)
        try container.encode(dateString, forKey: .date)
    }
}
```

🦹‍♀️ With **Codextended**:

```swift
struct Bookmark: Codable {
    static let dateFormatter = makeDateFormatter()

    var url: URL
    var date: Date

    init(from decoder: Decoder) throws {
        url = try decoder.decode("url")
        date = try decoder.decode("date", using: Bookmark.dateFormatter)
    }

    func encode(to encoder: Encoder) throws {
        try encoder.encode(url, for: "url")
        try encoder.encode(date, for: "date", using: Bookmark.dateFormatter)
    }
}
```

Again, we could’ve chosen to use a `CodingKeys` enum above to represent our keys, rather than using inline strings.

## Mix and match

Since **Codextended** is 100% implemented through extensions, you can easily mix and match it with “vanilla” `Codable` code within the same project. It also doesn’t change what makes `Codable` so great — the fact that it often doesn’t require any manual code at all, and that it can be used as a bridge between frameworks.

All it does is give `Codable` a *helping hand* when some form of customization is needed.

## Installation

Since **Codextended** is implemented within a single file, the easiest way to use it is to simply drag and drop it into your Xcode project.

But if you wish to use a dependency manager, you can either use the [Swift Package Manager](https://github.com/apple/swift-package-manager) by declaring **Codextended** as a dependency in your `Package.swift` file:

```swift
.package(url: "https://github.com/JohnSundell/Codextended", from: "0.1.0")
```

*For more information, see [the Swift Package Manager documentation](https://github.com/apple/swift-package-manager/tree/master/Documentation).*

You can also use [CocoaPods](https://cocoapods.org) by adding the following line to your `Podfile`:

```ruby
pod "Codextended"
```

## Contributions & support

**Codextended** is developed completely in the open, and your contributions are more than welcome.

Before you start using **Codextended** in any of your projects, it’s highly recommended that you spend a few minutes familiarizing yourself with its documentation and internal implementation (it all fits [in a single file](https://github.com/JohnSundell/Codextended/blob/master/Sources/Codextended/Codextended.swift)!), so that you’ll be ready to tackle any issues or edge cases that you might encounter.

To learn more about the principles used to implement **Codextended**, check out *[“Type inference-powered serialization in Swift”](https://www.swiftbysundell.com/posts/type-inference-powered-serialization-in-swift)* on Swift by Sundell.

This project does not come with GitHub Issues-based support, and users are instead encouraged to become active participants in its continued development — by fixing any bugs that they encounter, or improving the documentation wherever it’s found to be lacking.

If you wish to make a change, [open a Pull Request](https://github.com/JohnSundell/Codextended/pull/new) — even if it just contains a draft of the changes you’re planning, or a test that reproduces an issue — and we can discuss it further from there.

Hope you’ll enjoy using **Codextended**! 😀

