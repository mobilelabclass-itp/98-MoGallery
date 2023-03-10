//
//  MetaModel.swift
//
//  Created by jht2 on 12/20/22.
//

import FirebaseDatabase

class MetaModel: ObservableObject {
    
    @Published var metas: [MetaEntry] = []

    // mo-meta
    private var metaRef: DatabaseReference? 
    private var metaHandle: DatabaseHandle?
    
    unowned var app: AppModel
    init(_ app:AppModel) {
        print("MetaModel init")
        self.app = app
        metaRef = Database.root.child("mo-meta")
    }
    
    func refresh() {
        print("MetaModel refresh")
        observeStop()
        metaRef = Database.root.child("mo-meta")
        observeStart()
    }
    
    func observeStart() {
        guard let metaRef else { return }
        print("MetaModel observeStart metaHandle", metaHandle ?? "nil")
        if metaHandle != nil {
            return;
        }
        metaHandle = metaRef.observe(.value, with: { snapshot in
            guard let snapItems = snapshot.value as? [String: [String: Any]] else {
                print("MetaModel meta EMPTY")
                self.metas = []
                return
            }
            let items = snapItems.compactMap { MetaEntry(id: $0, dict: $1) }
            let sortedItems = items.sorted(by: { $0.galleryName > $1.galleryName })
            self.metas = sortedItems;
            print("MetaModel metas count", self.metas.count)
        })
    }
    
    func observeStop() {
        guard let metaRef else { return }
        print("MetaModel observeStop metaHandle", metaHandle ?? "nil")
        if let refHandle = metaHandle {
            metaRef.removeObserver(withHandle: refHandle)
            metaHandle = nil;
        }
    }
    
    func find(galleryName: String) -> MetaEntry? {
        return metas.first(where: { $0.galleryName == galleryName })
    }
    
    func fetch(galleryName: String) -> MetaEntry?  {
        if let metaEntry = find(galleryName: galleryName) {
            return metaEntry
        }
        guard let user = app.lobbyModel.currentUser else {
            print("addMeta no currentUser")
            return nil
        }
        return addMeta(galleryName: galleryName, user: user)
    }
    
    func addMeta(galleryName: String) -> MetaEntry? {
        guard let user = app.lobbyModel.currentUser else {
            print("addMeta no currentUser")
            return nil
        }
        return addMeta(galleryName: galleryName, user: user)
    }
    
    func addMeta(galleryName: String, user: UserModel?) -> MetaEntry? {
        print("addMeta galleryName", galleryName);
        let mentry = find(galleryName: galleryName)
        if let mentry  {
            print("addMeta present uid", mentry.uid);
            return mentry;
        }
        guard let user else {
            print("addMeta no currentUser")
            return nil
        }
        guard let metaRef else {
            print("addMeta no metaRef")
            return nil
        }
        guard let key = metaRef.childByAutoId().key else {
            print("addMeta no key")
            return nil
        }
        var values:[String : Any] = [:];
        values["uid"] = user.id;
        values["galleryName"] = galleryName;
        metaRef.child(key).updateChildValues(values) { error, ref in
            if let error = error {
                print("addMeta updateChildValues error: \(error).")
            }
        }
        return MetaEntry(id: key, dict: values)
    }
    
    func removeMeta(galleryName: String) {
        print("removeMeta galleryName", galleryName);
        guard let mentry = find(galleryName: galleryName)
        else {
            print("removeMeta NOT FOUND galleryName", galleryName)
            return;
        }
        // Delete from meta if this user is the creator
        guard let user = app.lobbyModel.currentUser else {
            print("addMeta no currentUser");
            return
        }
        if user.id != mentry.uid {
            print("removeMeta NOT owner mentry.uid", mentry.uid, "user.id", user.id)
            return
        }
        guard let metaRef else { return }
        metaRef.child(mentry.id).removeValue {error, ref in
            if let error = error {
                print("removeMeta removeValue error: \(error).")
            }
        }
    }
    
    func update(metaEntry: MetaEntry) {
        guard let metaRef else { return }
        var values:[AnyHashable : Any] = [:];
        values["status"] = metaEntry.status;
        metaRef.child(metaEntry.id).updateChildValues(values) { error, ref in
            if let error = error {
                print("update metaEntry updateChildValues error: \(error).")
            }
        }
    }
}

