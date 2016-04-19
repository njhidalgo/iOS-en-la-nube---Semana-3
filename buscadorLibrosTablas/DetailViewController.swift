//
//  DetailViewController.swift
//  buscadorLibrosTablas
//
//  Created by Nahim Jesus Hidalgo Sabido on 4/18/16.
//  Copyright © 2016 Nahim Jesus Hidalgo Sabido. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    @IBOutlet weak var autoresLabel: UILabel!
    
    @IBOutlet weak var imagenPortada: UIImageView!
    

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                
                label.text = detail.valueForKey("titulo")!.description
                
                autoresLabel.text = detail.valueForKey("autores")!.description
                
                let urlImage = detail.valueForKey("portada")!.description
                
                let image = UIImage(contentsOfFile: urlImage)
                
                imagenPortada.image = image
                
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

