//
//  HTTPSUpgradePersistence.swift
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

import Foundation
import CoreData


public protocol HTTPSUpgradePersistence {

    func persist(domains: [String], wildcardDomains: [String])

    func hasDomain(_ domain: String) -> Bool

}

// https://stackoverflow.com/questions/45922314/why-xcode-9-beta-does-not-show-index-options-for-coredata-entities-and-attribute
// https://developer.apple.com/videos/play/wwdc2017/210/

public class CoreDataHTTPSUpgradePersistence: HTTPSUpgradePersistence {

    let container = DDGPersistenceContainer(name: "HTTPSUpgrade")!

    var domains = [String]()
    
    public init() {
        
        
        
    }

    public func persist(domains: [String], wildcardDomains: [String]) {
        let start = Date()
        print("***", "persisting domains", domains.count, wildcardDomains.count)
        
        deleteAll()
        self.domains.removeAll()

        for simpleDomain in domains {
            let entityName = String(describing: HTTPSUpgradeSimpleDomain.self)
            let context = container.managedObjectContext
            let storedDomain = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! HTTPSUpgradeSimpleDomain
            storedDomain.domain = simpleDomain
        }

        for wildcardDomain in wildcardDomains {
            let domain = String(wildcardDomain.suffix(from: String.Index.init(encodedOffset: 1)))
            let entityName = String(describing: HTTPSUpgradeWildcardDomain.self)
            let context = container.managedObjectContext
            let storedDomain = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! HTTPSUpgradeWildcardDomain
            storedDomain.domain = domain
        }

        _ = container.save()
        
        print("***", "persisting domains DONE", Date().timeIntervalSince(start))
    }

    public func hasWildcardDomain(_ domain: String) -> Bool {
        let domains = buildDomainList(domain)
        let request:NSFetchRequest<HTTPSUpgradeWildcardDomain> = HTTPSUpgradeWildcardDomain.fetchRequest()
        request.predicate = NSPredicate(format: "domain in %@", domains)
        guard let count = try? container.managedObjectContext.count(for: request) else { return false }
        return count > 0
    }

    public func hasSimpleDomain(_ domain: String) -> Bool {
        let request:NSFetchRequest<HTTPSUpgradeSimpleDomain> = HTTPSUpgradeSimpleDomain.fetchRequest()
        request.predicate = NSPredicate(format: "domain = %@", domain)
        guard let count = try? container.managedObjectContext.count(for: request) else { return false }
        return count > 0
    }

    public func hasDomain(_ domain: String) -> Bool {
        return hasSimpleDomain(domain) || hasWildcardDomain(domain)
    }

    func reset() {
        deleteAll()
    }

    private func buildDomainList(_ domain: String) -> [String] {
        var domains = [String]()
        for part in domain.components(separatedBy: ".").reversed() {
            if domains.isEmpty {
                domains.append(".\(part)")
            } else {
                domains.append(".\(part)\(domains.last!)")
            }
        }
        return domains
    }

    private func deleteAll() {
        container.deleteAll(entities: try? container.managedObjectContext.fetch(HTTPSUpgradeSimpleDomain.fetchRequest()))
        container.deleteAll(entities: try? container.managedObjectContext.fetch(HTTPSUpgradeWildcardDomain.fetchRequest()))
    }

}
