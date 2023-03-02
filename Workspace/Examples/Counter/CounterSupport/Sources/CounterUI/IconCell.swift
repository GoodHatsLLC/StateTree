import UIKit

// MARK: - IconCell

final class IconCell: UITableViewCell {

  // MARK: Internal

  var icon: UIImage? {
    didSet { updateLabel() }
  }

  var count = 0 {
    didSet { updateLabel() }
  }

  static func register(in tableView: UITableView) {
    tableView.register(Self.self, forCellReuseIdentifier: Self.identifier)
  }

  static func dequeue(from tableView: UITableView) -> Self? {
    tableView.dequeueReusableCell(withIdentifier: Self.identifier) as? Self
  }

  // MARK: Private

  private static let identifier = "IconCellIdentifier"

  private func updateLabel() {
    var content = UIListContentConfiguration.cell()
    content.image = icon
    content.text = "\(count)"
    content.imageProperties.reservedLayoutSize = .init(width: 30, height: 30)
    contentConfiguration = content
  }
}
