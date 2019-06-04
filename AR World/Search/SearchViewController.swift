//
//  SearchViewController.swift
//  AR World
//
//  Created by Nate Sesti on 12/5/18.
//  Copyright © 2018 Nate Sesti. All rights reserved.
//

import UIKit
import Firebase

class SearchViewController: UIViewController, UISearchControllerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Variables and viewDidLoad()
    var results = [User]()
    var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true
        navigationItem.searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController!.searchBar.delegate = self
        navigationItem.searchController!.searchBar.autocapitalizationType = .none
        navigationItem.searchController!.delegate = self
        navigationItem.title = "Search"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        
        tableView = UITableView(frame: view.frame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "searchReuse")
        view.addSubview(tableView)
    }
    
    //MARK: UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        getDocuments(from: db.collection("users").whereField("username", isEqualTo: searchText)) { (querySnap) in
            self.results = [User]()
            for doc in querySnap {
                self.results.append(User(doc: doc.document))
            }
            self.tableView.reloadData()
        }
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: UITableViewDelegate/DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchReuse", for: indexPath) as! SearchResultTableViewCell
        
        let user = results[indexPath.row]
        cell.usernameButton.setTitle(user.name, for: .normal)
        cell.usernameButton.initialize(uid: user.uid, parentVC: self)
        //Load photo from Firebase/Storage
        storage.reference().child(user.imageName).getData(maxSize: 10240*10240) { (imageData, err) in
            if let err = err {
                print(err)
            } else {
                guard let newImage = UIImage(data: imageData!) else {return}
                cell.userIcon.image = newImage
            }
        }
        return cell
    }
}
