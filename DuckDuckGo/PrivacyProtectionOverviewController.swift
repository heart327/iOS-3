//
//  PrivacyProtectionOverviewController.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Core

class PrivacyProtectionOverviewController: UITableViewController {

    @IBOutlet var margins: [NSLayoutConstraint]!

    @IBOutlet weak var encryptionCell: SummaryCell!
    @IBOutlet weak var trackersCell: SummaryCell!
    @IBOutlet weak var majorTrackersCell: SummaryCell!
    @IBOutlet weak var privacyPracticesCell: SummaryCell!

    fileprivate var popRecognizer: InteractivePopRecognizer!

    private weak var siteRating: SiteRating!
    private weak var contentBlocker: ContentBlockerConfigurationStore!
    private weak var header: PrivacyProtectionHeaderController!

    override func viewDidLoad() {
        super.viewDidLoad()

        initPopRecognizer()
        adjustMargins()

        update()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let displayInfo = segue.destination as? PrivacyProtectionInfoDisplaying {
            displayInfo.using(siteRating: siteRating, contentBlocker: contentBlocker)
        }

        if let header = segue.destination as? PrivacyProtectionHeaderController {
            self.header = header
        }
    }

    private func update() {
        // not keen on this, but there seems to be a race condition when the site rating is updated and the controller hasn't be loaded yet
        guard isViewLoaded else { return }

        header.using(siteRating: siteRating, contentBlocker: contentBlocker)
        updateEncryption()
        updateTrackersBlocked()
        updateMajorTrackersBlocked()
        updatePrivacyPractices()
    }

    private func updateEncryption() {
        encryptionCell.summaryLabel.text = siteRating.encryptedConnectionText()
        if siteRating.https && siteRating.hasOnlySecureContent {
            encryptionCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Connection On") : #imageLiteral(resourceName: "PP Icon Connection Off")
        } else {
            encryptionCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Connection Bad") : #imageLiteral(resourceName: "PP Icon Connection Off")
        }
    }

    private func updateTrackersBlocked() {
        trackersCell.summaryLabel.text = siteRating.networksText(contentBlocker: contentBlocker)

        if (protecting() ? siteRating.uniqueTrackerNetworksBlocked : siteRating.uniqueMajorTrackerNetworksBlocked) == 0 {
            trackersCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Networks On") : #imageLiteral(resourceName: "PP Icon Networks Off")
        } else {
            trackersCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Networks Bad") : #imageLiteral(resourceName: "PP Icon Networks Off")
        }
    }

    private func updateMajorTrackersBlocked() {
        majorTrackersCell.summaryLabel.text = siteRating.majorNetworksText(contentBlocker: contentBlocker)
        if siteRating.majorNetworksSuccess(contentBlocker: contentBlocker) {
            majorTrackersCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Major Networks On") : #imageLiteral(resourceName: "PP Icon Major Networks Off")
        } else {
            majorTrackersCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Major Networks Bad") : #imageLiteral(resourceName: "PP Icon Major Networks Off")
        }
    }

    private func updatePrivacyPractices() {
        privacyPracticesCell.summaryLabel.text = siteRating.privacyPracticesText()

        if siteRating.privacyPracticesSuccess() {
            privacyPracticesCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Privacy Good On") : #imageLiteral(resourceName: "PP Icon Privacy Good Off")
        } else {
            privacyPracticesCell.summaryImage.image = protecting() ? #imageLiteral(resourceName: "PP Icon Privacy Bad On") : #imageLiteral(resourceName: "PP Icon Privacy Bad Off")
        }
    }

    private func protecting() -> Bool {
        return contentBlocker.protecting(domain: siteRating.domain)
    }

    // see https://stackoverflow.com/a/41248703
    private func initPopRecognizer() {
        guard let controller = navigationController else { return }
        popRecognizer = InteractivePopRecognizer(controller: controller)
        controller.interactivePopGestureRecognizer?.delegate = popRecognizer
    }

    private func adjustMargins() {
        if #available(iOS 10, *) {
            for margin in margins {
                margin.constant = 0
            }
        }
    }

}

extension PrivacyProtectionOverviewController: PrivacyProtectionInfoDisplaying {

    func using(siteRating: SiteRating, contentBlocker: ContentBlockerConfigurationStore) {
        self.siteRating = siteRating
        self.contentBlocker = contentBlocker
        update()
    }

}

class SummaryCell: UITableViewCell {

    @IBOutlet weak var summaryImage: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!

}

class ProtectionUpgradedView: UIView {

    @IBOutlet weak var fromImage: UIImageView!
    @IBOutlet weak var toImage: UIImageView!

    func update(with siteRating: SiteRating) {
        let siteGradeImages = siteRating.siteGradeImages()
        isHidden = siteGradeImages.from == siteGradeImages.to
        fromImage.image = siteGradeImages.from
        toImage.image = siteGradeImages.to
    }

}

fileprivate class InteractivePopRecognizer: NSObject, UIGestureRecognizerDelegate {

    var navigationController: UINavigationController

    init(controller: UINavigationController) {
        self.navigationController = controller
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController.viewControllers.count > 1
    }

    // This is necessary because without it, subviews of your top controller can
    // cancel out your gesture recognizer on the edge.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


