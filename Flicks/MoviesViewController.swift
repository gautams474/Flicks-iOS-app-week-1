//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Gautam Sadarangani on 1/16/16.
//  Copyright © 2016 Gautam Sadarangani. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController , UITableViewDataSource, UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UISearchBarDelegate {

    let refreshControl = UIRefreshControl()
    @IBOutlet weak var NetworkLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var listView: UICollectionView!
    @IBOutlet weak var viewToggle: UISegmentedControl!
    
    var movies: [NSDictionary]?
    var filteredData: [NSDictionary]?
    var endpoint: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        listView.dataSource = self
        listView.delegate = self
        searchBar.delegate = self
        
        let viewButton = UIBarButtonItem(customView: viewToggle)
        navigationItem.rightBarButtonItem = viewButton
        
        NetworkLabel.hidden = true
        listView.hidden = true
        //start monitoring
        //[[AFNetworkReachabilityManager sharedManager] startMonitoring];
        
        refreshControl.addTarget(self, action: "refreshControlAction:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        refreshControlAction(refreshControl)
                // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
   
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        // Display HUD right before the request is made
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                
                // Hide HUD once the network request comes back (must be done on main UI thread)
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            NSLog("response: \(responseDictionary)")
                           // print("response: \(responseDictionary)")
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredData = self.movies
                            self.tableView.reloadData();
                            self.NetworkLabel.hidden = true
                            refreshControl.endRefreshing()
                    }
                    else{
                        self.NetworkLabel.hidden = false
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        self.tableView.reloadData();
                        
                        refreshControl.endRefreshing()
                        self.refreshControlAction(refreshControl) 
                    }
                    if(error != nil){
                        self.NetworkLabel.hidden = false
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        refreshControl.endRefreshing()
                    }
                }
        });
        print(task.response)
        print(task.error)
        print(request)
            delay(0.5) {
                
            }
            self.refreshControl.endRefreshing()
        
        task.resume()
    
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        filteredData = searchText.isEmpty ? movies : movies?.filter({(movie: NSDictionary) -> Bool in
            if let title = movie["title"] as? String {
                return title.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
            }
            return false
        })
        if(viewToggle.selectedSegmentIndex == 1){
        tableView.reloadData()
        }
        else{
            listView.reloadData()
        }
        
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let filteredData  = filteredData  {
            return filteredData.count
        }
        else{
            return 0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = movies! [indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        //let baseUrl = "http://image.tmdb.org/t/p/w500"
        let smallBaseUrl = "http://image.tmdb.org/t/p/w45"
        let largeBaseUrl = "http://image.tmdb.org/t/p/original"
        
        
     /*   if let posterPath = movie["poster_path"] as? String{
            let imageUrl = NSURL(string: baseUrl + posterPath)
            cell.posterView.setImageWithURL(imageUrl!)
        }
        */
        if let posterPath = movie["poster_path"] as? String {
            let smallImageUrl = NSURL(string: smallBaseUrl + posterPath)
            let largeImageUrl = NSURL(string: largeBaseUrl + posterPath)
            // cell.posterView.setImageWithURL(posterUrl!)
            
            
            let smallImageRequest = NSURLRequest(URL: smallImageUrl!)
            let largeImageRequest = NSURLRequest(URL: largeImageUrl!)
            
            cell.posterView.setImageWithURLRequest(
                smallImageRequest,
                placeholderImage: nil,
                success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                    
                    // smallImageResponse will be nil if the smallImage is already available
                    // in cache (might want to do something smarter in that case).
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = smallImage;
                    
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        
                        cell.posterView.alpha = 1.0
                        
                        }, completion: { (sucess) -> Void in
                            
                            // The AFNetworking ImageView Category only allows one request to be sent at a time
                            // per ImageView. This code must be in the completion block.
                            cell.posterView.setImageWithURLRequest(
                                largeImageRequest,
                                placeholderImage: smallImage,
                                success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    
                                    cell.posterView.image = largeImage;
                                    
                                },
                                failure: { (request, response, error) -> Void in
                                    // do something for the failure condition of the large image request
                                    // possibly setting the ImageView's image to a default image
                            })
                    })
                },
                failure: { (request, response, error) -> Void in
                    // do something for the failure condition
                    // possibly try to get the large image
            })
        }
        else {
            cell.posterView.image = nil
        }
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.yellowColor()
        cell.selectedBackgroundView = backgroundView
        
        
        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
        
        cell.selected = false
        
    }
    
   
     func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if let movies  = movies  {
            return movies.count
        }
        else{
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ListCell", forIndexPath: indexPath) as! ListCell
        let movie = movies! [indexPath.item]
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
                let imageUrl = NSURL(string: baseUrl + posterPath)
                cell.listImage.setImageWithURL(imageUrl!)
        }
        
        // Configure the cell
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let totalwidth = collectionView.bounds.size.width;
        let numberOfCellsPerRow = 3
        //let oddEven = indexPath.row / numberOfCellsPerRow % 2
        let dimensions = CGFloat(Int(totalwidth) / numberOfCellsPerRow)
        return CGSizeMake(dimensions, dimensions)
            }
    
    @IBAction func OnViewChange(sender: AnyObject) {
        
        if(viewToggle.selectedSegmentIndex == 1){
        tableView.hidden = true
        listView.hidden = false
          self.listView.reloadData()   
        }
        else if(viewToggle.selectedSegmentIndex == 0){
            tableView.hidden = false
            listView.hidden = true
        }
        
        
    }

}
