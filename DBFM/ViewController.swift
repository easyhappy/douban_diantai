//
//  ViewController.swift
//  DBFM
//
//  Created by andyhu on 14-10-27.
//  Copyright (c) 2014年 andyhu. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, HttpProtocol, ChannelProtocol{

    @IBOutlet weak var tv: UITableView!
    @IBOutlet weak var iv: UIImageView!
    @IBOutlet weak var playTim: UIView!
    @IBOutlet weak var progressView: UIView!
    
    var eHttp:HttpController = HttpController()
    var tableData:NSArray = NSArray()
    var channelData:NSArray = NSArray()
    var imageCache = Dictionary<String, UIImage>()
    var audioPlayer:MPMoviePlayerController = MPMoviePlayerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        eHttp.delegate = self
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        eHttp.onSearch("http://douban.fm/j/mine/playlist?channel=0")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var channelC:ChannelController = segue.destinationViewController as ChannelController
        channelC.delegate = self
        channelC.channelData = self.channelData
    }
    
    func onChangeChannel(channel: String) {
        let url = "http://douban.fm/j/mine/playlist?\(channel)"

        eHttp.onSearch(url)
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return tableData.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "douban")
        let rowData:NSDictionary = self.tableData[indexPath.row] as NSDictionary
        
        cell.textLabel.text = rowData["title"] as? String
        //cell.detailTextLabel.text = rowData["artist"] as String
        cell.imageView.image = UIImage(named:"listen_katong.jpeg")
        let url = rowData["picture"] as String
        let image = self.imageCache[url]
        if image == nil {
            let imgURL:NSURL = NSURL(string: url)!
            let request:NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response: NSURLResponse!, data: NSData!, error:NSError!) -> Void in
                let img = UIImage(data:data)
                cell.imageView.image = img
                self.imageCache[url] = img
            })
        }else{
            cell.imageView.image = image
        }
        return cell
    }
    
    func didReceiveResults(results: NSDictionary) {
        if (results["song"] != nil){
            self.tableData = results["song"] as NSArray
            println(results)
            self.tv.reloadData()
        }else if (results["channels"] != nil){
            self.channelData = results["channels"] as NSArray
        }
    }
    
    func onSetAudio(url:String){
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string:url)
        self.audioPlayer.play()
    }
    
    func onSetImage(url:String){
        let image = self.imageCache[url]
        
        if image == nil {
            let imgURL:NSURL = NSURL(string: url)!
            let request:NSURLRequest = NSURLRequest(URL: imgURL)
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response: NSURLResponse!, data: NSData!, error:NSError!) -> Void in
                let img = UIImage(data:data)
                //cell.imageView.image = img
                self.imageCache[url] = img
            })
        }else{
            //cell.imageView.image = image
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        var rowData:NSDictionary = self.tableData[indexPath.row] as NSDictionary
        
        var audioUrl:String = rowData["url"] as String
        onSetAudio(audioUrl)
    }
}

