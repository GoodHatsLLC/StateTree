import Disposable
import Emitter
import StateTree
import StateTreePlayback
import SwiftUI

// MARK: - PlaybackView

@MainActor
public struct PlaybackView<Root: Node, NodeView: View>: View {

  // MARK: Lifecycle

  public init(
    root: TreeRoot<Root>,
    @ViewBuilder rootViewBuilder: @escaping (_ node: TreeNode<Root>) -> NodeView
  ) {
    self.rootViewBuilder = rootViewBuilder
    _root = TreeNode(scope: root.scope)
    let life = root.life()
    _life = .init(wrappedValue: life)
    let recorder = life.recorder()
    _mode = .init(wrappedValue: .record(recorder))
    _scanReporter = .init(wrappedValue: .init(recorder.frameCount.erase()))
    _control = .init(wrappedValue: .record)
    try! recorder.start()
  }

  // MARK: Public

  public var body: some View {
    VStack {
      Spacer()
      rootViewBuilder($root)
        .allowsHitTesting(control == .record)
      Spacer()
      HStack {
        HStack(spacing: 8) {
          Button {
            control = .record
          } label: {
            Text("▶️")
              .overlay(.blue.blendMode(control == .record ? .screen : .overlay))
          }
          .buttonStyle(.borderless)
          .disabled(control == .record)
          Button {
            control = .play
          } label: {
            Text("⏺️")
              .overlay(.blue.blendMode(control == .play ? .screen : .overlay))
          }
          .buttonStyle(.borderless)
          .disabled(control == .play)
        }

        let transition = AnyTransition.slide
        Slider(
          value: $scanLocation,
          in: frameRange,
          step: 1
        )
        .transition(transition)
        .animation(.default.speed(0.5), value: frameRange)
        .frame(maxWidth: .infinity)
        .disabled(control != .play)
        HStack(spacing: 8) {
          Button {
            guard let player
            else {
              return
            }
            scanLocation = Double(player.previous())
          } label: {
            Text("⏪")
              .overlay(.blue.blendMode(.overlay))
          }
          .buttonStyle(.borderless)
          .disabled(control != .play)
          Button {
            guard let player
            else {
              return
            }
            scanLocation = Double(player.next())
          } label: {
            Text("⏩")
              .overlay(.blue.blendMode(.overlay))
          }
          .buttonStyle(.borderless)
          .disabled(control != .play)
          Button {
            popoverFrame = recorder?.currentFrame ?? player?.currentFrame
          } label: {
            Text("🔍")
          }
          .buttonStyle(.borderless)
          .padding(.leading)
          .popover(item: $popoverFrame) { frame in
            TextEditor(text: .constant(frame.state.formattedJSON))
              .frame(idealWidth: 600, maxWidth: .infinity)
              .font(.footnote.monospaced())
          }
        }
      }
      .padding()
      .background(.background)
      .cornerRadius(16)
      .shadow(color: .black.opacity(0.1), radius: 4)
      .padding()
    }
    .background(.thickMaterial)
    .onReceive(
      scanReporter
        .flatMapLatest(producer: { $0 })
        .combineDriver
    ) { loc in
      switch mode {
      case .record(let recorder): frameRange = recorder.frameRangeDouble
      case .play(let player): frameRange = player.frameRangeDouble
      }
      scanLocation = Double(loc)
    }
    .onChange(
      of: scanLocation,
      perform: { newValue in
        guard let player
        else {
          return
        }
        player.frame = Int(newValue)
      }
    )
    .onChange(of: control) { _ in
      switch (mode, control) {
      case (.record(let recorder), .play):
        do {
          let frames = try recorder.stop()
          let player = try life.player(frames: frames)
          try player.start()
          mode = .play(player)
          scanReporter.emit(.value(player.currentFrameIndex.erase()))
        } catch {
          assertionFailure("❌ \(error.localizedDescription)")
        }
      case (.play(let player), .record):
        do {
          let keptFrames = player.stop()
          let recorder = life.recorder(frames: keptFrames)
          frameRange = 0.0 ... Double(max(1, keptFrames.count - 1))
          try recorder.start()
          mode = .record(recorder)
          scanReporter.emit(.value(recorder.frameCount.erase()))
        } catch {
          assertionFailure("❌ \(error.localizedDescription)")
        }
      case (_, .record):
        do {
          let recorder = life.recorder()
          try recorder.start()
          mode = .record(recorder)
          scanReporter.emit(.value(recorder.frameCount.erase()))
        } catch {
          assertionFailure("❌ \(error.localizedDescription)")
        }
      default: break
      }
    }
  }

  // MARK: Internal

  enum PlaybackMode {
    case record(Recorder<Root>)
    case play(Player<Root>)
  }

  enum ControlMode: View {
    case record
    case play

    var icon: (String, Color) {
      switch self {
      case .record: return ("⏺️", .red)
      case .play: return ("▶️", .green)
      }
    }

    var body: some View {
      Text(icon.0)
        .tag(self)
    }
  }

  @TreeNode var root: Root
  @State var life: TreeLifetime<Root>
  @ViewBuilder var rootViewBuilder: (TreeNode<Root>) -> NodeView

  @State var popoverFrame: StateFrame?
  @State var frameRange: ClosedRange<Double> = 0.0 ... 1.0
  @State var mode: PlaybackMode
  @State var disposable: AnyDisposable?
  @State var control: ControlMode

  // MARK: Private

  @State private var scanLocation: Double = 1
  @State private var scanReporter: ValueSubject<AnyEmitter<Int>>

  private var player: Player<Root>? {
    switch mode {
    case .play(let player): return player
    case .record: return nil
    }
  }

  private var recorder: Recorder<Root>? {
    switch mode {
    case .play: return nil
    case .record(let recorder): return recorder
    }
  }

}
