//
//  PostCell.swift
//  BeFake App
//
//

import UIKit
import ParseSwift
import Alamofire
import AlamofireImage

class PostCell: UITableViewCell {
    weak var delegate: PostCellDelegate?

    @IBOutlet weak var nameAvatarLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationHoursLabel: UILabel!
    
    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var postCaptionLabel: UILabel!
    
    private var imageDataRequest: DataRequest?
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .black
        contentView.backgroundColor = .black
        nameAvatarLabel.layer.cornerRadius = nameAvatarLabel.frame.size.width / 2
        nameAvatarLabel.layer.masksToBounds = true
        
        nameAvatarLabel.textColor = .white
        nameLabel.textColor = .white
        locationHoursLabel.textColor = .white
        postCaptionLabel.textColor = .white
    }
    
    
    func configure(with post: Post){
        if let user = post.user {
            nameLabel.text = user.username
            nameAvatarLabel.text = self.extractInitials(from: user.username ?? "")
        }
        if let imageFile = post.image,
           let imageURL = imageFile.url {
            imageDataRequest = AF.request(imageURL).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    self?.postImageView.image = image
                case .failure(let error):
                    print("Error downloading image: \(error)")
                    break
                }
                
            }
        }
        postCaptionLabel.text = post.caption
        let locationText = post.location ?? "Washington, D.C."
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        locationHoursLabel.text = "\(locationText), \(formatter.string(from: post.createdAt!))"
        
        if let currentUser = User.current,
           
            let lastPostedDate = currentUser.lastAdded,
           
            let postCreatedDate = post.createdAt,
           
            
            let diffHours = Calendar.current.dateComponents([.hour], from: postCreatedDate, to: lastPostedDate).hour {
            
            blurView.isHidden = abs(diffHours) < 24
        } else {
            
            blurView.isHidden = false
        }
        
    }
    
    private func calculateTimeSincePost(_ date: Date?) -> String {
        guard let postDate = date else { return "Unknown time" }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: postDate, to: Date())
        if let hours = components.hour {
            return "\(hours) hrs ago"
        }
        return "Just now"
    }
    private func extractInitials(from username: String) -> String {
            let words = username.split(separator: " ")
            
            let initials = words.compactMap { $0.first }
            
            let firstTwoInitials = initials.prefix(2)
            
            let capitalizedInitials = firstTwoInitials.map { String($0).uppercased() }
            
            return capitalizedInitials.joined()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        postImageView.image = nil

        imageDataRequest?.cancel()

    }
    
    func handleCommentSubmission(text: String) {
            delegate?.postCell(self, didSubmitComment: text)
        }

}

protocol PostCellDelegate: AnyObject {
    func postCell(_ cell: PostCell, didSubmitComment commentText: String)
}

