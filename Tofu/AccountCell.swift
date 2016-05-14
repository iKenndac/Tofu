import UIKit

private func placeholderImageWithText(text: String) -> UIImage {
  let image = UIImage(named: "Placeholder")!
  UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
  image.drawAtPoint(CGPoint.zero)
  defer { UIGraphicsEndImageContext() }
  let paragraphStyle = NSMutableParagraphStyle()
  paragraphStyle.alignment = .Center
  let fontSize: CGFloat = 36
  let attributes = [
    NSFontAttributeName: UIFont.systemFontOfSize(fontSize, weight: UIFontWeightUltraLight),
    NSForegroundColorAttributeName: UIColor.lightGrayColor(),
    NSParagraphStyleAttributeName: paragraphStyle,
  ]
  let origin = CGPoint(x: 0, y: (image.size.height - fontSize) / 2 - 0.1 * fontSize)
  text.drawWithRect(CGRect(origin: origin, size: image.size), options: .UsesLineFragmentOrigin,
    attributes: attributes, context: nil)
  return UIGraphicsGetImageFromCurrentImageContext()
}

private func imageForAccount(account: Account) -> UIImage {
  switch account.issuer {
  case .Some("Amazon"): return UIImage(named: "Amazon")!
  case .Some("AWS"): return UIImage(named: "AWS")!
  case .Some("Bitbucket"): return UIImage(named: "Bitbucket")!
  case .Some("DigitalOcean"): return UIImage(named: "DigitalOcean")!
  case .Some("DNSimple"): return UIImage(named: "DNSimple")!
  case .Some("Dropbox"): return UIImage(named: "Dropbox")!
  case .Some("Evernote"): return UIImage(named: "Evernote")!
  case .Some("Facebook"): return UIImage(named: "Facebook")!
  case .Some("FastMail"): return UIImage(named: "FastMail")!
  case .Some("GitHub"): return UIImage(named: "GitHub")!
  case .Some("Google"): return UIImage(named: "Google")!
  case .Some("GreenAddress"): return UIImage(named: "GreenAddress")!
  case .Some("Heroku"): return UIImage(named: "Heroku")!
  case .Some("Hover"): return UIImage(named: "Hover")!
  case .Some("IFTTT"): return UIImage(named: "IFTTT")!
  case .Some("Intercom"): return UIImage(named: "Intercom")!
  case .Some("LinodeManager"): return UIImage(named: "Linode")!
  case .Some("LocalBitcoins"): return UIImage(named: "LocalBitcoins")!
  case .Some("Microsoft"): return UIImage(named: "Microsoft")!
  case .Some("Slack"): return UIImage(named: "Slack")!
  case .Some("Stripe"): return UIImage(named: "Stripe")!
  case .Some("Tumblr"): return UIImage(named: "Tumblr")!
  case .Some("www.fastmail.com"): return UIImage(named: "FastMail")!
  default:
    let text = String(account.description.characters.first ?? "?").uppercaseString
    return placeholderImageWithText(text)
  }
}

private func imageWithColor(color: UIColor, size: CGSize) -> UIImage {
  UIGraphicsBeginImageContext(size)
  color.setFill()
  UIRectFill(CGRectMake(0, 0, size.width, size.height))
  let image = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  return image;
}

private func formattedValue(value: String) -> String {
  let length = value.characters.count
  let prefix = String(value.characters.prefix(length / 2))
  let suffix = String(value.characters.suffix(length - length / 2))
  return "\(prefix) \(suffix)"
}

final class AccountCell: UITableViewCell {
  @IBOutlet weak var accountImageView: UIImageView!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var identifierLabel: UILabel!
  var delegate: AccountUpdateDelegate?
  private let button = UIButton(type: .Custom)
  private let progressView = CircularProgressView()

  var account: Account! {
    didSet {
      accessoryView = account.password.timeBased ? progressView : button
      let now = NSDate()
      updateWithDate(now)
    }
  }

  override func awakeFromNib() {
    let featureSettings = [[
      UIFontFeatureTypeIdentifierKey: kNumberSpacingType,
      UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]]
    let attributes = [UIFontDescriptorFeatureSettingsAttribute: featureSettings]
    let fontDescriptor = valueLabel.font.fontDescriptor()
      .fontDescriptorByAddingAttributes(attributes)
    valueLabel.font = UIFont(descriptor: fontDescriptor, size: 0)
    button.titleLabel?.font = UIFont.boldSystemFontOfSize(13)
    button.setTitle("NEXT", forState: .Normal)
    button.setTitleColor(tintColor, forState: .Normal)
    button.setTitleColor(UIColor.whiteColor(), forState: .Highlighted)
    button.setTitleColor(UIColor.whiteColor(), forState: .Selected)
    button.layer.borderColor = button.tintColor.CGColor
    button.layer.borderWidth = 1
    button.layer.cornerRadius = 4
    button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    button.sizeToFit()
    let image = imageWithColor(tintColor, size: button.bounds.size)
    button.setBackgroundImage(image, forState: .Highlighted)
    button.setBackgroundImage(image, forState: .Selected)
    button.clipsToBounds = true
    button.addTarget(self, action: #selector(didPressButton(_:)), forControlEvents: .TouchUpInside)
  }

  func didPressButton(sender: UIButton) {
    account.password.counter += 1
    delegate?.updateAccount(account)
  }

  func updateWithDate(date: NSDate) {
    accountImageView.image = imageForAccount(account)
    valueLabel.text = formattedValue(account.password.valueForDate(date))
    identifierLabel.text = account.description
    progressView.progress = account.password.progressForDate(date)
    progressView.tintColor = account.password.timeIntervalRemainingForDate(date) < 5 ?
      .redColor() : tintColor
  }
}
