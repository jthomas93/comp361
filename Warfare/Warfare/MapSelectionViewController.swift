//
//  MapSelectionViewController.swift
//  Warfare
//
//  Created by Harry Simmonds on 2015-03-03.
//  Copyright (c) 2015 Justin Domingue. All rights reserved.
//

import Foundation
import UIKit

class MapSelectionViewController: UIViewController {
    
    @IBOutlet weak var confirmationButton: UIButton!
    
    var selectedIndex: Int = 1
    
    @IBOutlet weak var map1: UIImageView!
    @IBOutlet weak var map2: UIImageView!
    @IBOutlet weak var map3: UIImageView!
    @IBOutlet weak var map4: UIImageView!
    @IBOutlet weak var mapChoice: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set MatchHelper's view controller
        MatchHelper.sharedInstance().vc = self

        self.confirmationButton.enabled = true

        self.setChoiceView(self.map1.image!)

        // add tap gesture to images
        map1.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "mapTapped:"))
        map2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "mapTapped:"))
        map3.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "mapTapped:"))
        map4.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "mapTapped:"))
    }
    
    @IBAction func confirmationAction(sender: AnyObject) {
        if !self.confirmationButton.enabled { return }

        self.confirmationButton.enabled = false

        // GameEngine will take care of dismissing this view controller
        // as well as processing the map selection
        GameEngine.Instance.processMapSelection(selectedIndex)
    }
    
    func mapTapped(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            if let view = sender.view as? UIImageView {
                if let image = view.image {
                    let tag = view.tag
                    self.selectedIndex = tag
                    setChoiceView(image)
                }
            }
        }
    }
    
    private func setChoiceView(image: UIImage) {
        self.mapChoice.image = image
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
