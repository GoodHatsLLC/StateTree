# Counter

This is a example app showing the basics of integrating
StateTree with an imperative UI framework like UIKit.
It is an intentionally a limited example.

Note: there are significant conceptual challenges involved
when integrating with imperative UI frameworks. UIKit included.

Unlike declarative UI frameworks, imperative systems don't
handle transitioning from one known state to another — they
simply receive commands and execute them. If those commands
are invalid, behaviour is probably undefined.
(In UIKit and AppKit apps for example, view modifications
performed when a view is not installed in a window might be
invalid.)

More problematically, some core UIKit and AppKit view
modification actions like view controller presentation are
asynchronous and unblock the UI thread — but also cause
otherwise legal behaviour to be undefined. (i.e. pushing a
view controller while another is being pushed triggers
undefined behaviour.)
To make matters worse, not all asynchronous events have
completion callbacks, and some of them don't even provide
a way to poll for transition completion.

In short, anyone attempting to create a declarative control
layer on top of existing UIKit or AppKit APIs has their
work set out for them.
(SwiftUI's longstanding [navigation bugs](https://openradar.appspot.com/search?query=swiftui+navigation)
suggest that Apple itself is feeling this pain.)

In short: if you are planning to integrate a declarative
system like StateTree into an imperative UI framework,
plan research upfront, and don't try to boil the ocean. :)

Remember: A declarative framework is just someone else's
imperative code.
