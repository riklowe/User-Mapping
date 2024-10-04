//
//  WalksViewController.swift
//  User Mapping
//
//  Created by Richard Lowe on 03/10/2024.
//

import UIKit

class WalksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    weak var delegate: WalkSelectionDelegate?
    var walks: [Walk] = []

    // MARK: - Constants
    let metersPerSecondToMilesPerHour = 2.23694
    let metersToMiles = 0.000621371

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Sort walks by date (most recent first)
        walks.sort { $0.date > $1.date }

        print ("walks.count = ", walks.count)
        // Set up table view
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Load walks from storage
        walks = DataManager.shared.loadWalks()
        walks.sort { $0.date > $1.date }

        // Reload the table view
        tableView.reloadData()
    }

    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return walks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WalkCell", for: indexPath)

        let walk = walks[indexPath.row]

        // Format date
        cell.textLabel?.text = dateFormatter.string(from: walk.date)
        //cell.detailTextLabel?.text = String(format: "Distance: %.2f km | Duration: %@", walk.distance / 1000, formatDuration(walk.duration))
        cell.detailTextLabel?.text = String(format: "Distance: %.2f miles | Duration: %@", (walk.distance * metersToMiles), formatDuration(walk.duration))

        return cell
    }

    // MARK: - Table View Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedWalk = walks[indexPath.row]
        delegate?.didSelectWalk(selectedWalk)
        navigationController?.popViewController(animated: true)
    }

    // Support deleting walks
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove walk from data source
            walks.remove(at: indexPath.row)
            DataManager.shared.saveWalks(walks)

            // Delete the row from the table view
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
