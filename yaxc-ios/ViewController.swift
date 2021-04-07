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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
    
    @IBAction func loadClipboardBtn(_ sender: Any) {
        // build url
        let url = getUrl()
        if url == nil {
            return
        }
        print("lc:", url!)
        
        // make network request
        let session = URLSession.shared
        session.dataTask(with: url!, completionHandler: { data, response, error in
            if error != nil {
                self.statusLbl.text = error!.localizedDescription
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                self.msg("status code not 2xx")
                return
            }
            
            // read result
            let str = String(decoding: data!, as: UTF8.self)
            self.msg(str)
            
            // write to clipboard
            UIPasteboard.general.string = str
        }).resume()
        
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
            self.msg(res)
        }.resume()
    }
    
}
