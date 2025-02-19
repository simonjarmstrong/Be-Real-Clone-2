//
//  FeedViewController.swift
//  BeFake App
//
//

import UIKit
import ParseSwift
import PhotosUI
import UserNotifications

class FeedViewController: UIViewController {
    
    
    
    @IBOutlet weak var seeFriendsButton: UIBarButtonItem!
    
    @IBOutlet weak var feedTableView: UITableView!
    
    private  var posts: [Post] = [] {
        didSet {
            feedTableView.reloadData()
        }
    }
    
    private let refreshControl = UIRefreshControl()
    private var activityIndicator: UIActivityIndicatorView!

    let notificationCenter = UNUserNotificationCenter.current()
    
    // Pagination
    private var isLoadingMorePosts = false
    private var currentPage = 0
    private let postsPerPage = 10 // pagination size
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        feedTableView.backgroundColor = .black
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.allowsSelection = false
        setupRefreshControl()
        
        notificationCenter.requestAuthorization(options: [.alert, .sound]){ (permissionGranted, error) in
            if(!permissionGranted){
                print("Permission Denied")
            }
        }
        
        

        
        
        // Initialize the activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white  // Make it white for visibility on black background
        activityIndicator.center = feedTableView.center
        activityIndicator.hidesWhenStopped = true
        feedTableView.addSubview(activityIndicator)

    }
    private func setupRefreshControl() {
        if #available(iOS 10.0, *) {
            feedTableView.refreshControl = refreshControl
        } else {
            feedTableView.addSubview(refreshControl)
        }
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
    }

    @objc private func refreshFeed() {
        currentPage = 0
        queryPosts(refreshing: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queryPosts()
        scheduleNotification()
        
    }
    private func scheduleNotification(){
        notificationCenter.getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized else {
                    print("Notifications are not authorized.")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Time for BeFake Picture"
                content.body = "It's your time of the day to fake a picture."
                
                var dateComponents = DateComponents()
                dateComponents.hour = 01
                dateComponents.minute = 03
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "BeFakePicture", content: content, trigger: trigger)

                self.notificationCenter.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    private func queryPosts(refreshing: Bool = false) {
        // Show the activity indicator before starting the query
        activityIndicator.startAnimating()
        if isLoadingMorePosts{return}
        
        isLoadingMorePosts = true
        
        let yesterdayDate = Calendar.current.date(byAdding: .day, value: (-1), to: Date())!
        
        let query = Post.query().include("user").include("comments").include("comments.user").order([.descending("createdAt")]).limit(postsPerPage).skip(currentPage * postsPerPage).where("createdAt" >= yesterdayDate)
        
        query.find { [weak self] result in
            DispatchQueue.main.async {
                            self?.refreshControl.endRefreshing() // Step 4: Stop refreshing
                            self?.activityIndicator.stopAnimating() // Stop the activity indicator when done
                        }
            switch result{
            case .success(let posts):
                if refreshing {
                                    self?.posts = posts // Reset the posts array when refreshing
                                } else {
                                    self?.posts.append(contentsOf: posts) // Append new posts to existing array
                                }
                                self?.currentPage += 1
                
            case .failure(let error):
                print("Error")
//                self?.showUnknownErrorAlert(description: error.localizedDescription)
            }
            self?.isLoadingMorePosts = false
            }
        }
    
    @IBAction func didTapLogOutButton(_ sender: Any) {
        print("Log out Button Pressed.")
        showConfirmLogoutAlert()
    }
    
    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func didTapSeeFriendsButton(_ sender: Any) {
        print("Did Tap See Friends Button will be configured later")
    }
    

    private func showUnknownErrorAlert(description: String?) {
        let alertController = UIAlertController(title: "Unable to Sign Up", message: description ?? "An unknown error occurred.", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }
    
    private func showMissingFieldsAlert() {
        let alertController = UIAlertController(title: "Missing Fields", message: "Please fill in all fields", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(alertAction)
        present(alertController, animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FeedViewController: UITableViewDelegate, UITableViewDataSource, PostCellDelegate {
    
    func postCell(_ cell: PostCell, didSubmitComment commentText: String) {
            guard let indexPath = feedTableView.indexPath(for: cell) else { return }
            var post = posts[indexPath.row]

            let newComment = Comment(post: post, user: User.current, content: commentText)
            
            newComment.save { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let savedComment):
                    if post.comments == nil {
                        post.comments = []
                    }
                    
                    post.comments?.append(savedComment)
                    
                    self.posts[indexPath.row] = post
                    
                    post.save { result in
                        switch result {
                        case .success(let updatedPost):
                            DispatchQueue.main.async {

                                self.posts[indexPath.row] = updatedPost
                                self.feedTableView.reloadRows(at: [indexPath], with: .automatic)
                            }
                        case .failure(let error):
                            print("Error updating post: \(error.localizedDescription)")
                        }
                    }
                    
                case .failure(let error):
                    print("Error saving comment: \(error.localizedDescription)")
                }
            }
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCellReuse", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        let post = posts[indexPath.row]
        cell.configure(with: post)
        cell.delegate = self
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let contentHeight = scrollView.contentSize.height
            let offset = scrollView.contentOffset.y
            let height = scrollView.frame.size.height
            
            // Check if the user has reached the bottom of the table
            if offset > contentHeight - height - 50 { // 50 is a buffer value
                // Fetch more posts if we're not already loading more
                if !isLoadingMorePosts {
                    queryPosts()
                }
            }
        }
}
