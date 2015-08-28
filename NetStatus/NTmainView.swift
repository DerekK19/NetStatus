//
//  NTmainView.swift
//  NetStatus
//
//  Created by Derek Knight on 5/06/14.
//  Copyright (c) 2014 Derek Knight. All rights reserved.
//

import UIKit

let kReuseId = "statusCell"
let kCellNib = "statusCell"

/**
    Server run state enumeration

    Has run states for the server: running, not running and unknown
 */
enum ServerRunState
{
    case Running
    case NotRunning
    case Unknown
}

/**
    Server structure

    Has name, IP and run state for a server
 */
struct Server
{
    let name: String
    let ip: String
    let state: ServerRunState

    init(name: String, ip: String, state:ServerRunState)
    {
        self.name = name
        self.ip = ip
        self.state = state
    }
}

/**
    Class for the main window

    Has a table view and a refresh table header view. Can flip to an information view.
    Gets the server status information from an NT Net Service class
 */
@objc(mainView) class mainView : UIViewController, UITableViewDataSource,
                                   UITableViewDelegate,
                                   UIPopoverControllerDelegate,
                                   EGORefreshTableHeaderDelegate,
                                   NTNetStatusServiceDelegate
{

    @IBOutlet var tableView : UITableView!
    @IBOutlet var refreshHeaderView : EGORefreshTableHeaderView!
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {}

    var servers = [Server]()
    var reloading: Bool = false

    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.tableView.registerClass(serverCell.self, forCellReuseIdentifier: kReuseId)
        let nibName=UINib(nibName: kCellNib, bundle:nil)
        self.tableView.registerNib(nibName, forCellReuseIdentifier: kReuseId)

        if self.refreshHeaderView == nil
        {
            let view: EGORefreshTableHeaderView = EGORefreshTableHeaderView(frame: CGRectMake(0.0, 0.0 - self.tableView.bounds.size.height, self.tableView.bounds.size.width, self.tableView.bounds.size.height))
            view.delegate = self
            self.tableView.addSubview(view)
            self.refreshHeaderView = view
        }

        //  update the last update date
        if self.refreshHeaderView != nil
        {
            refreshHeaderView.refreshLastUpdatedDate()
        }
        
        NTNetStatusService.setDelegate(self)
        NTNetStatusService.loadData()
    }

    // Delegate functions for UITableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.servers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell: serverCell? = tableView.dequeueReusableCellWithIdentifier(kReuseId, forIndexPath: indexPath) as? serverCell
        if cell == nil
        {
            cell = serverCell(style: UITableViewCellStyle.Default, reuseIdentifier: kReuseId)
        }
        cell!.server = self.servers[indexPath.row]
        cell!.selectionStyle = UITableViewCellSelectionStyle.None
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
    }

    // Delegate functions for NTNetStatusService
    func service(service: NTNetStatusService!, didGetServers records: [AnyObject])
    {
        servers = []
        for record : AnyObject in records
        {
            let sRecord = record as! NSDictionary
            self.servers.append(Server(name: sRecord["name"] as! String,
                                         ip: sRecord["ip"] as! String,
                                      state: sRecord["state"] as! String == "R" ? ServerRunState.Running :
                                             sRecord["state"] as! String == "N" ? ServerRunState.NotRunning : ServerRunState.Unknown))
        }
        self.tableView.reloadData()
    }

    // Delegate functions for EGO Table Pull Refresh
    func reloadTableViewDataSource()
    {
        self.reloading = true
        NTNetStatusService.loadData()
    }

    func doneLoadingTableViewData()
    {
        self.reloading = false
        refreshHeaderView.egoRefreshScrollViewDataSourceDidFinishedLoading(self.tableView)
    }

    func scrollViewDidScroll(scrollView: UIScrollView)
    {
        refreshHeaderView.egoRefreshScrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        refreshHeaderView.egoRefreshScrollViewDidEndDragging(scrollView)
    }

    func egoRefreshTableHeaderDidTriggerRefresh(view: EGORefreshTableHeaderView)
    {
        self.reloadTableViewDataSource()
        let delay = 3.0 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {self.doneLoadingTableViewData()})
    }

    func egoRefreshTableHeaderDataSourceIsLoading(view: EGORefreshTableHeaderView) -> Bool
    {
        return self.reloading // should return if data source model is reloading
    }

    func egoRefreshTableHeaderDataSourceLastUpdated(view: EGORefreshTableHeaderView) -> NSDate
    {
        return NSDate() // should return date data source was last changed
    }
}

/**
    An info view to show when the main view is flipped over
 */
class reverseView : UIViewController
{
    @IBOutlet var info: UILabel!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.info.text = "This app shows whether my home machines are running:\n\nYellow dot - unknown\nRed dot - not running\nGreen dot - running\n\nThe app uses ping to check machine status. There is no indication the machines are fully functioning\n\nPull the list down to refresh"
    }
}

/**
    A server table view cell

    Has a Server. When the server is set, sets the label and an image to show the server state
 */
class serverCell : UITableViewCell
{
    @IBOutlet var serverName: UILabel!
    @IBOutlet var serverStatus: UIImageView!

    var server: Server?
    {
        didSet
        {
            if server != nil
            {
                let imageName = server!.state == ServerRunState.Running ? "greenDot" :
                                server!.state == ServerRunState.NotRunning ? "redDot" : "yellowDot"
                self.serverName.text = server!.name + " (\(server!.ip))"
                self.serverStatus.image = UIImage(named: imageName)
            }
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
