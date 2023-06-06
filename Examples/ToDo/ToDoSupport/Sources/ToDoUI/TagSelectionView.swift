import StateTreeSwiftUI
import SwiftUI
import ToDoDomain

struct TagSelectionView: View {

  @TreeNode var tagSelector: TagSelector
  @Binding var isDisplayed: Bool

  var body: some View {
    VStack(spacing: 0) {
      TextField("Filter", text: $tagSelector.$searchText)
        .textFieldStyle(.roundedBorder)
        .padding(0.5.su)
      List(
        tagSelector.matchingTags,
        id: \.id,
        selection: $tagSelector.$selectedMatchingTags
      ) { tag in
        Text(tag.name)
          .padding([.horizontal], 1.su)
          .padding([.vertical], 0.25.su)
          .background(Capsule().fill(tag.colour.swiftUI))
      }
      .listStyle(.sidebar)
      .padding(0)
    }
  }
}
