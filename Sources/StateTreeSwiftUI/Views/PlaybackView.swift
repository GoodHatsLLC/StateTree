import Dispatch
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
    let tree = root.tree
    _tree = .init(wrappedValue: tree)
    let recorder = Recorder(tree: tree)
    do {
      try recorder.start()
    } catch {
      preconditionFailure(
        """
        Could not start PlaybackView's Recorder.
        error: \(error.localizedDescription)
        """
      )
    }
    _root = TreeNode(scope: root.scope)
    _mode = .init(wrappedValue: .record(recorder))
    _scanReporter = .init(wrappedValue: .init(recorder.frameCountEmitter.erase()))
    _control = .init(wrappedValue: .record)
  }

  // MARK: Public

  public var body: some View {
    VStack {
      Spacer()
      ZStack {
        rootViewBuilder($root)
          .allowsHitTesting(control == .record)
        Color.clear
          .contentShape(Rectangle())
          .allowsHitTesting(control == .play)
          .onTapGesture {
            withAnimation(.default) {
              suppressedTapCount += 1
            }
          }
      }
      Spacer()
      VStack {
        HStack {
          HStack(spacing: 1.su) {
            Button {
              control = .record
            } label: {
              Text("⏺️")
                .font(.title)
                .overlay(
                  RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(.pink)
                    .opacity(control == .play ? 1.0 : 0.5)
                    .blendMode(.color)
                    .padding(2)
                )
            }
            .buttonStyle(.borderless)
            .disabled(control == .record)
            Button {
              control = .play
            } label: {
              Text("▶️")
                .font(.title)
                .overlay(
                  RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(.green)
                    .blendMode(.color)
                    .opacity(control == .record ? 1.0 : 0.3)
                    .padding(2)
                )
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
          HStack(spacing: 1.su) {
            Button {
              guard let player
              else {
                return
              }
              scanLocation = Double(player.previous())
            } label: {
              Text("⏪")
                .font(.title)
                .overlay(
                  RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(control == .play ? .blue : .gray)
                    .blendMode(.color)
                    .padding(2)
                )
                .opacity(control == .play ? 1 : 0.7)
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
                .font(.title)
                .overlay(
                  RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(control == .play ? .blue : .gray)
                    .blendMode(.color)
                    .padding(2)
                )
                .opacity(control == .play ? 1 : 0.7)
            }
            .buttonStyle(.borderless)
            .disabled(control != .play)
            Button {
              popoverFrame = displayedFrame
            } label: {
              Text("🕵️")
                .font(.title)
                .overlay(
                  Text("🕵️")
                    .font(.title)
                    .blendMode(.colorBurn)
                    .padding(2)
                    .opacity(control == .record ? 0.2 : 0)
                )
                .opacity(control == .play ? 1 : 0.7)
            }
            .disabled(control != .play)
            .buttonStyle(.borderless)
            .popover(item: $popoverFrame) { frame in
              TextEditor(text: .constant(
                frame.state?
                  .formattedJSON ?? "Error: No record available."
              ))
              .frame(idealWidth: 600, maxWidth: .infinity)
              .font(.footnote.monospaced())
            }
          }
        }
        .padding()
        .background(.background)
        .cornerRadius(2.su)
        .shadow(color: .black.opacity(0.1), radius: 0.5.su)
        .padding([.leading, .trailing])
        HStack {
          Spacer()
          Text(displayedFrame?.event.description ?? "No event information available.")
            .lineLimit(1)
            .font(.footnote)
          Spacer()
        }
        .padding([.bottom])
        .opacity(displayedFrame?.event.description == nil ? 0 : 1.0)
      }
      .modifier(Shake(animatableData: CGFloat(suppressedTapCount)))
    }
    .background(.thickMaterial)
    .onReceive(
      scanReporter
        .flatMapLatest { $0
          .replaceFailures(with: 0)
        }
        .asCombinePublisher()
        .receive(on: DispatchQueue.main)
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
        player.currentFrameIndex = Int(newValue)
      }
    )
    .onChange(of: control) { _ in
      switch (mode, control) {
      case (.record(let recorder), .play):
        do {
          let frames = try recorder.stop()
          let player = try Player(tree: tree, frames: frames)
          try player.start()
          mode = .play(player)
          scanReporter.emit(value: player.currentFrameIndexEmitter.erase())
        } catch {
          assertionFailure("❌ \(error.localizedDescription)")
        }
      case (.play(let player), .record):
        do {
          let keptFrames = try player.stop()
          let recorder = Recorder(tree: tree, frames: keptFrames)
          frameRange = 0.0 ... Double(max(1, keptFrames.count - 1))
          try recorder.start()
          mode = .record(recorder)
          scanReporter.emit(value: recorder.frameCountEmitter.erase())
        } catch {
          assertionFailure("❌ \(error.localizedDescription)")
        }
      default:
        assertionFailure("❌ Unexpected player/recorder state.")
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

  @State var suppressedTapCount = 0

  @TreeNode var root: Root
  @State var tree: Tree<Root>
  @ViewBuilder var rootViewBuilder: (TreeNode<Root>) -> NodeView

  @State var popoverFrame: StateFrame?
  @State var frameRange: ClosedRange<Double> = 0.0 ... 1.0
  @State var mode: PlaybackMode
  @State var disposable: AutoDisposable?
  @State var control: ControlMode

  var displayedFrame: StateFrame? {
    player?.currentStateRecord
  }

  // MARK: Private

  @State private var scanLocation: Double = 1
  @State private var scanReporter: ValueSubject<AnyEmitter<Int, Never>, Never>

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

// MARK: - Shake

struct Shake: GeometryEffect {
  var amount: CGFloat = 1.su
  var shakesPerUnit = 3
  var animatableData: CGFloat

  func effectValue(size _: CGSize) -> ProjectionTransform {
    ProjectionTransform(CGAffineTransform(
      translationX:
      amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
      y: 0
    ))
  }
}
