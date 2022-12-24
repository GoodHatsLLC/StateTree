import Disposable
import StateTree
import SwiftUI
import TreeJSON

@MainActor
public struct TimeTravelView<RootModel: Model, ModelView: View>: View {

  public init(
    tree: Tree<RootModel>,
    options: [StartOption] = [],
    rootViewBuilder: @MainActor (_ model: RootModel) -> ModelView
  ) {
    self.tree = tree
    // @State used to ensure the 'rootModel' value is also not changes on re-init.
    rootView = rootViewBuilder(tree.rootModel)
    self.options = options.filter {
      switch $0 {
      case .statePlayback: return false
      case .dependencies: return true
      case .logging: return true
      }
    }
  }

  public var tree: Tree<RootModel>

  public var rootModel: RootModel {
    tree.rootModel
  }

  public var body: some View {
    VStack {
      Spacer()
      rootView
        .allowsHitTesting(control == .record)
      Spacer()
      HStack {
        Picker("", selection: $control) {
          ControlMode.record.view
          ControlMode.pause.view
        }
        .pickerStyle(.segmented)
        .layoutPriority(-1)

        Slider(value: .init(projectedValue: $scanLocation))
          .frame(maxWidth: .infinity)
          .disabled(control != .pause)
        HStack(spacing: 0) {
          Button("⏪") {
            guard let player
            else {
              return
            }
            scanLocation = player.previousFrameScan()
          }
          Button("⏩") {
            guard let player
            else {
              return
            }
            scanLocation = player.nextFrameScan()
          }
          Button("ℹ️") {
            debugPrint(player?.frames ?? [])
          }.padding(.leading)
        }.disabled(control != .pause)
      }
    }
    .padding()
    .onChange(
      of: scanLocation,
      perform: { newValue in
        guard let player
        else {
          return
        }
        player.scanTo(proportion: newValue)
      }
    )
    .onChange(of: control) { _ in
      switch (mode, control) {
      case (.record(let record), .pause):
        do {
          let player = record.makePlayer()
          mode = .playback(player)
          disposable?.dispose()
          disposable = try tree.start(options: [.statePlayback(mode: .playback(player))] + options)
        } catch {
          DependencyValues.defaults.logger
            .error(
              message: "failed to start the tree in playback mode",
              error
            )
        }
      case (.playback, .record):
        do {
          let record = JSONTreeStateRecord()
          mode = .record(record)
          disposable?.dispose()
          disposable = try tree.start(options: [.statePlayback(mode: .record(record))] + options)
        } catch {
          DependencyValues.defaults.logger
            .error(
              message: "failed to start the tree in record mode",
              error
            )
        }
      case _:
        break
      }
    }
    .onAppear {
      control = .record
    }
  }

  enum TimeTravelMode {
    case record(JSONTreeStateRecord)
    case playback(JSONTreeStatePlayer)
  }

  enum ControlMode {
    case record
    case pause

    var icon: String {
      switch self {
      case .record: return "⏺️"
      case .pause: return "⏸️"
      }
    }

    var view: some View {
      Text(icon).tag(self)
    }
  }

  @State var disposable: AnyDisposable?

  @State var control: ControlMode = .pause

  @State private var scanLocation: Double = 0
  private let rootView: ModelView
  @State private var mode: TimeTravelMode = .playback(JSONTreeStatePlayer(treePatches: []))
  private let options: [StartOption]

  private var player: JSONTreeStatePlayer? {
    if case .playback(let player) = mode {
      return player
    }
    return nil
  }

}
