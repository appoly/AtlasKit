//
//  LocationSearchViewController.swift
//  UIKitExample
//
//  Created by James Wolfe on 17/03/2022.
//



import Foundation
import UIKit
import AtlasKit




class LocationSearchViewController: UIViewController {
    
    // MARK: - Variables
    
    public var atlas: AtlasKit!
    
    private var values: [AtlasKitPlace] = []
    private var shouldAutoSearch: Bool = false
    
    private var isSearching: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.isSearching ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
                self.pickerView.alpha = self.isSearching ? 0 : 1
                self.searchButton.isUserInteractionEnabled = !self.isSearching
                self.searchButton.alpha = self.isSearching ? 0.5 : 1
            }
        }
    }
    
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    
    // MARK: - Actions
    
    @IBAction func textField_EditingDidChange(_ sender: UITextField) {
        guard shouldAutoSearch else { return }
        performDelayedSearch()
    }
    
    
    @IBAction func searchButtonTouchUpInside(_ sender: Any) {
        performSearch()
    }
    
    
    @IBAction func autoSearchSwitch_ValueChanged(_ sender: UISwitch) {
        shouldAutoSearch = !shouldAutoSearch
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.searchButton.isHidden = sender.isOn
            self?.searchButton.superview?.layoutIfNeeded()
        }
    }
    
    
    
    // MARK: - Utilities
    
    private func cancelIfNecessary() {
        if(textField.text == nil || textField.text!.isEmpty) {
            values = []
            atlas.cancelSearch()
        }
    }
    
    
    private func performDelayedSearch() {
        cancelIfNecessary()
        guard let text = textField.text, !text.isEmpty else {
            isSearching = false
            pickerView.reloadAllComponents()
            return
        }
        
        isSearching = true
        atlas.performSearchWithDelay(text, delay: 2) { results, error in
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.showError(error)
                }
                self?.values = results ?? []
                self?.pickerView.reloadAllComponents()
                self?.isSearching = false
            }
        }
    }
    
    
    private func performSearch() {
        cancelIfNecessary()
        guard let text = textField.text, !text.isEmpty else {
            isSearching = false
            return
        }
        
        isSearching = true
        atlas.performSearch(text) { results, error in
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.showError(error)
                }
                self?.values = results ?? []
                self?.pickerView.reloadAllComponents()
                self?.isSearching = false
            }
        }
    }
    
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(.init(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}



extension LocationSearchViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard values.indices.contains(row) else { return "" }
        let value = values[row]
        return value.formattedAddress
    }
    
}
