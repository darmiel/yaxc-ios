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

    @IBAction func loadClipboardBtn(_ sender: Any) {
        self.statusLbl.text = "clicked button."
        
        // get anywhere path
        let anywhere = self.anywherePathTxt.text
        if (anywhere == nil || anywhere!.isEmpty) {
            self.statusLbl.text = "No anywhere path set."
            return
        }
        
        self.statusLbl.text = "nw resp."
        
        // make network request
        let url = URL(string: "https://yaxc.d2a.io/" + anywhere!)!
        let session = URLSession.shared
        
        print(url)
        
        // read clipboard
        session.dataTask(with: url, completionHandler: { data, response, error in
            if error != nil {
                self.statusLbl.text = error!.localizedDescription
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("status code not 2xx")
                return
            }
            
            // read result
            let str = String(decoding: data!, as: UTF8.self)
            print("Result: ", str)
            
            // write to clipboard
            UIPasteboard.general.string = str
            
            // write to status label
            DispatchQueue.main.async {
                self.statusLbl.text = str
            }
        }).resume()
        
    }
    
}
