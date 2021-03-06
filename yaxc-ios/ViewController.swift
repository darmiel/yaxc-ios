//
//  ViewController.swift
//  yaxc-ios
//
//  Created by Daniel Statzner on 07.04.21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var anywherePathTxt: UITextField!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var previousTable: UITableView!
    @IBOutlet weak var autoCheckSwitch: UISwitch!
    
    var history: [String] = []
    var autoTimer: Timer?
    
    @IBAction func switchToggled(_ sender: Any) {
        if self.autoCheckSwitch.isOn {
            self.startAutoTimer()
        } else {
            self.stopAutoTimer()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previousTable.delegate = self
        self.previousTable.dataSource = self
        
        // start timer
        if self.autoCheckSwitch.isOn {
          print("Starting timer ...")
            self.startAutoTimer()
        }
    }
    @objc func fire() {
        self.readServer(replaceClipboard: false)
    }
    
    func startAutoTimer() {
        self.msg("Starting Auto Timer Task.")
        stopAutoTimer()
        self.autoTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(fire),
            userInfo: nil,
            repeats: true)
    }
    
    func stopAutoTimer() {
        self.msg("Stopping Auto Timer Task.")
        if self.autoTimer == nil {
            return
        }
        print("Stopping timer ...")
        self.autoTimer?.invalidate()
        self.autoTimer = nil
    }
    
    func getUrl() -> URL? {
        // get anywhere path
        let anywhere = self.anywherePathTxt.text
        if (anywhere == nil || anywhere!.isEmpty) {
            self.statusLbl.text = "No anywhere path set."
            return nil
        }
        return URL(string: "https://yaxc.d2a.io/" + anywhere!)
    }
    
    func msg(_ message: String) {
        print(message)
        DispatchQueue.main.async {
            self.statusLbl.text = message
        }
    }
    
    func doAppendHistory(_ cb: String) -> Bool {
        if self.history.count == 0 {
            return true
        }
        let last = self.history[self.history.count - 1]
        return last != cb
    }
    
    func appendHistory(_ cb: String) {
        if !(doAppendHistory(cb)) {
            return
        }
        // append
        self.history.append(cb)
        // reload table
        DispatchQueue.main.async {
            self.previousTable.reloadData()
        }
    }
    
    func readServer(replaceClipboard: Bool) {
        let url = getUrl()
        if url == nil {
            return
        }
        print("requesting", url!, "to check clipboard")
        
        // make network request
        let session = URLSession.shared
        session.dataTask(with: url!, completionHandler: { data, response, error in
            if error != nil {
                self.statusLbl.text = error!.localizedDescription
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                self.msg("no clipboard on server.")
                return
            }
            
            // read result
            let str = String(decoding: data!, as: UTF8.self)
            
            // history
            self.appendHistory(str)
            
            // write to clipboard
            if replaceClipboard {
                self.msg("received: " + str)
                UIPasteboard.general.string = str
            }
        }).resume()
    }
    
    @IBAction func loadClipboardBtn(_ sender: Any) {
       readServer(replaceClipboard: true)
    }
    
    @IBAction func writeClipboardBtn(_ sender: Any) {
        // build url
        let url = getUrl()
        if url == nil {
            return
        }
        print("u:", url!)
        
        // read clipboard
        let cb = UIPasteboard.general.string
        if cb == nil || cb!.isEmpty {
            self.msg("Empty clipboard")
            return
        }
        print("cb:", cb!)
        
        // make network request
        let session = URLSession.shared
        let data = Data(cb!.utf8)
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        session.uploadTask(with: request, from: data) {data, response, error in
            if error != nil {
                self.msg("error: " + error!.localizedDescription)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                self.msg("status code not 2xx")
                return
            }
            
            // write result
            let res = String(decoding: data!, as: UTF8.self)
            self.msg("sent: " + res)
        }.resume()
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.history[indexPath.row]
        print("you tapped me:", data)
        
        // write to clipboard
        UIPasteboard.general.string = data
        self.msg("Wrote clipboard.")
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.history.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.previousTable.dequeueReusableCell(withIdentifier: "cell", for:indexPath)
        cell.textLabel?.text = self.history[indexPath.row]
        return cell
    }
}
