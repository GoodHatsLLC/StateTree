# TicTacToe

TicTacToe is a common example app, and so a useful opportunity for comparison:
* [Uber's RIBs](https://github.com/uber/RIBs/tree/27d8eba3fc93ec350b1736d620977e95752d44df/ios/tutorials/tutorial4)
* [PointFree's TCA](https://github.com/pointfreeco/swift-composable-architecture/tree/c432a76b5bde896ac6427c446b573ac487776379/Examples/TicTacToe)
* [Square's Workflow](https://github.com/square/workflow-swift/tree/edb6f1767495f27970b0d2d0e94c064f8f4c630b/Samples/TicTacToe)

The StateTree TicTacToe example app showcases:
* A moderately complicated SwiftUI—StateTree integration.
* Reasonable unit tests for StateTree logic.
* The StateTree `PlaybackView` which provides:
  - state recording
  - state playback
  - Behavior (i.e. side effect) recording
  - state JSON printing
