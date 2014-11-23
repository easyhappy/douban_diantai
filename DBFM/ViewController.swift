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
    @IBOutlet weak var playTime: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var nextMuisc: UIButton!
    var eHttp:HttpController = HttpController()
    var tableData:NSArray = NSArray()
    var channelData:NSArray = NSArray()
    var imageCache = Dictionary<String, UIImage>()
    var audioPlayer:MPMoviePlayerController = MPMoviePlayerController()
    var timer:NSTimer?
    var currentMuiscIndex:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.progress = 0.0
        audioPlayer.repeatMode = .One
        nextMuisc.addTarget(self, action: "test", forControlEvents: UIControlEvents.TouchUpInside)
        eHttp.delegate = self
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        eHttp.onSearch("http://douban.fm/j/mine/playlist?channel=0")
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func test(){
     println("just test")
     let rowData:NSDictionary = self.tableData[currentMuiscIndex+1] as NSDictionary
     println(currentMuiscIndex)
     currentMuiscIndex  += 1
     println(currentMuiscIndex)
     println("==============")
     updateCurrentMusic(rowData)
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
        currentMuiscIndex = indexPath.row
        
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
            var rowData = self.tableData.firstObject as NSDictionary
            var url = rowData["url"] as String
            self.onSetAudio(url)
            
        }else if (results["channels"] != nil){
            self.channelData = results["channels"] as NSArray
        }
    }
    
    func onSetAudio(url:String){
        timer?.invalidate()
        self.audioPlayer.stop()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.4,  target: self,  selector: "onUpdate", userInfo: nil, repeats: true)
        self.audioPlayer.contentURL = NSURL(string:url)
        self.audioPlayer.play()
        
    }
    
    func onUpdate(){
        let currentTimer = audioPlayer.currentPlaybackTime
        if currentTimer>0.0 {
            let dur = audioPlayer.duration
            let pecent:CFloat = CFloat(currentTimer/dur)
            progressBar.setProgress(pecent, animated: false)
            let all:Int = Int(currentTimer)
            let m:Int = all%60
            let f:Int = Int(all/60)
            var time:String = ""
            //分钟
            if f<10{
                time = "0\(f):"
            }else{
                time = "\(f):"
            }
            //秒
            if m<10{
                time += "0\(m)"
            }else{
                time += "\(m)"
            }
            playTime.text = time
        }
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
        currentMuiscIndex = indexPath.row
        updateCurrentMusic(rowData)
    }
    
    func updateCurrentMusic(muiscData:NSDictionary){
        var audioUrl:String = muiscData["url"] as String
        var length = muiscData["length"] as? Int
        playTime.text = formateTime(length!)
        onSetAudio(audioUrl)
        var counter:Int = 0 {
            didSet {
                let fractionalProgress = Float(counter) / 100.0
                let animated = counter != 0
                
                progressBar.setProgress(fractionalProgress, animated: animated)
            }
        }
    }
    
    func formateTime(time:Int)->NSString{
        var seconds = (time % 60) as NSNumber
        var minutes = (time / 60) as NSNumber
        if (seconds.intValue >= 10) {
            return "\(minutes.stringValue):\(seconds.stringValue)"
        }else{
            return "\(minutes.stringValue):0\(seconds.stringValue)"
        }
    }
}
