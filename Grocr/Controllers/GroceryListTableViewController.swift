/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {
    
    let ref = Database.database().reference(withPath: "grocery-items")

  // MARK: Constants
  let listToUsers = "ListToUsers"
  
  // MARK: Properties
  var items: [GroceryItem] = []
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
    // add
    let usersRef = Database.database().reference(withPath: "online")
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    userCountBarButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
    user = User(uid: "FakeId", email: "hungry@person.food")

   // using : queryOrdered to impletement code
    
    ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
      var newItems: [GroceryItem] = []
      for child in snapshot.children {
        if let snapshot = child as? DataSnapshot,
           let groceryItem = GroceryItem(snapshot: snapshot) {
          newItems.append(groceryItem)
        }
      }
      
      self.items = newItems
      self.tableView.reloadData()
    })
    
//    // Attach a listener to receive updates whenever the grocery-items endpoint is modified.
//    ref.observe(.value, with: { snapshot in
//        // Store the latest version of the data in a local variable inside the listener’s closure.
//        var newItems: [GroceryItem] = []
//
//        // The listener’s closure returns a snapshot of the latest set of data. The snapshot contains the entire list of grocery items, not just the updates.
//        for child in snapshot.children {
//            if let snapshot = child as? DataSnapshot,
//               let groceryItem = GroceryItem(snapshot: snapshot) {
//                newItems.append(groceryItem)
//
//                // The GroceryItem struct has an initializer that populates its properties using a DataSnapshot. A snapshot’s value is of type AnyObject, and can be a dictionary, array, number, or string. After creating an instance of GroceryItem, it’s added it to the array that contains the latest version of the data.
//            }
//        }
//
//        self.items = newItems
//        self.tableView.reloadData()
//    })
    
    // Setting the User in the Grocery List:
    Auth.auth().addStateDidChangeListener { auth, user in
      guard let user = user else { return }
      self.user = User(authData: user)
        
        // Create a child reference using a user’s uid, which is generated when Firebase creates an account.
        let currentUserRef = self.usersRef.child(self.user.uid)
        // save the current user’s email
        currentUserRef.setValue(self.user.email)
        // This removes the value at the reference’s location after the connection to Firebase closes, for instance when a user quits your app. This is perfect for monitoring users who have gone offline.
        currentUserRef.onDisconnectRemoveValue()
    }
  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    
    if editingStyle == .delete {
      let groceryItem = items[indexPath.row]
      groceryItem.ref?.removeValue()
    }
    // origin
//    if editingStyle == .delete {
//      items.remove(at: indexPath.row)
//      tableView.reloadData()
//    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    var groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
//    groceryItem.completed = toggledCompletion
//    tableView.reloadData()
    // replace :
    groceryItem.ref?.updateChildValues([
        "completed": toggledCompletion
    ])
    // Use updateChildValues(_:), passing a dictionary, to update Firebase. This method is different than setValue(_:) because it only applies updates, whereas setValue(_:) is destructive and replaces the entire value at that reference.
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = .black
      cell.detailTextLabel?.textColor = .black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = .gray
      cell.detailTextLabel?.textColor = .gray
    }
  }
  
  // MARK: Add Item
  
  @IBAction func addButtonDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Grocery Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
        
        guard let textField = alert.textFields?.first,
              let text = textField.text else { return }
      
      let groceryItem = GroceryItem(name: textField.text!,
                                    addedByUser: self.user.email,
                                    completed: false)
        let groceryItemRef = self.ref.child(text.lowercased())
        groceryItemRef.setValue(groceryItem.toAnyObject())
        
        //1. Get the text field, and its text, from the alert controller.
        //2. Using the current user’s data, create a new, uuncompleted GroceryItem.
        //3. Create a child reference using child(_:). The key value of this reference is the item’s name in lowercase, so when users add duplicate items (even if they capitalize it, or use mixed case) the database saves only the latest entry.
        //4. Use setValue(_:) to save data to the database. This method expects a Dictionary. GroceryItem has a helper function called toAnyObject() to turn it into a Dictionary.
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .cancel)
    
    alert.addTextField()
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  @objc func userCountButtonDidTouch() {
    performSegue(withIdentifier: listToUsers, sender: nil)
  }
}
