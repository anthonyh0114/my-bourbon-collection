//
//  BourbonDatabase.swift
//  My Bourbon Collection
//
//  Created by Tony Hill on 4/19/25.
//


import Foundation
import SQLite3
import UIKit

extension Notification.Name {
    static let bourbonCollectionDidChange = Notification.Name("bourbonCollectionDidChange")
}

class BourbonDatabase {
    static let shared = BourbonDatabase()
    private var db: OpaquePointer?
    private let dbPath: String
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let dbQueue = DispatchQueue(label: "com.mybourboncollection.database", qos: .userInitiated)
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()
    
    private init() {
        // Initialize with default values first
        let defaultURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.documentsDirectory = defaultURL
        
        // Get the documents directory
        let dbURL = documentsDirectory.appendingPathComponent("BourbonCollection.sqlite")
        dbPath = dbURL.path
        
        // Ensure the database directory exists
        let dbDirectory = dbURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        } catch {
            print("BourbonDatabase: Failed to create database directory: \(error.localizedDescription)")
        }
        
        // Initialize database on the database queue
        dbQueue.sync {
            initializeDatabase()
        }
    }
    
    private func initializeDatabase() {
        print("BourbonDatabase: Initializing database at \(dbPath)")
        
        // Close existing connection if any
        if let existingDB = db {
            sqlite3_close(existingDB)
            db = nil
        }
        
        // Open database
        let openResult = sqlite3_open(dbPath, &db)
        if openResult == SQLITE_OK {
            print("BourbonDatabase: Successfully opened database at \(dbPath)")
            
            // Enable foreign keys
            if sqlite3_exec(db, "PRAGMA foreign_keys = ON;", nil, nil, nil) == SQLITE_OK {
                print("BourbonDatabase: Successfully enabled foreign keys")
            } else {
                print("BourbonDatabase: Failed to enable foreign keys")
            }
            
            // Create table if it doesn't exist
            createTables()
            
            // Run migrations
            migrateAgeColumn()
            
            // Verify table structure
            verifyTableStructure()
        } else {
            print("BourbonDatabase: Failed to open database at \(dbPath)")
            print("BourbonDatabase: SQLite error code: \(openResult)")
            if let errorMessage = sqlite3_errmsg(db) {
                print("BourbonDatabase: SQLite error message: \(String(cString: errorMessage))")
            }
            db = nil
        }
    }
    
    private func migrateAgeColumn() {
        print("BourbonDatabase: Starting age column migration")
        
        // Check if we need to migrate
        let checkColumnType = "PRAGMA table_info(Bourbon);"
        var statement: OpaquePointer?
        var needsMigration = false
        
        if sqlite3_prepare_v2(db, checkColumnType, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let columnName = String(cString: sqlite3_column_text(statement, 1))
                let columnType = String(cString: sqlite3_column_text(statement, 2))
                
                if columnName == "age" && columnType.uppercased() == "INTEGER" {
                    needsMigration = true
                    break
                }
            }
        }
        sqlite3_finalize(statement)
        
        if needsMigration {
            print("BourbonDatabase: Migrating age column from INTEGER to TEXT")
            
            // Begin transaction
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            
            // Create temporary table with new schema
            let createTempTable = """
                CREATE TABLE Bourbon_temp (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    proof REAL NOT NULL,
                    age TEXT DEFAULT '',
                    purchaseDate TEXT NOT NULL,
                    purchaseLocation TEXT,
                    purchaseLocationLatitude REAL,
                    purchaseLocationLongitude REAL,
                    flavorProfile TEXT,
                    notes TEXT,
                    price REAL,
                    size TEXT,
                    imageFilename TEXT,
                    rating INTEGER DEFAULT 0,
                    fillLevel INTEGER DEFAULT 100,
                    dateOpened TEXT,
                    dateEmptied TEXT,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
            """
            
            if sqlite3_exec(db, createTempTable, nil, nil, nil) == SQLITE_OK {
                // Copy data with age conversion
                let copyData = """
                    INSERT INTO Bourbon_temp
                    SELECT 
                        id, name, proof,
                        CASE 
                            WHEN age = 0 THEN ''
                            ELSE CAST(age AS TEXT)
                        END as age,
                        purchaseDate, purchaseLocation, purchaseLocationLatitude,
                        purchaseLocationLongitude, flavorProfile, notes, price,
                        size, imageFilename, rating, fillLevel, dateOpened,
                        dateEmptied, created_at, updated_at
                    FROM Bourbon;
                """
                
                if sqlite3_exec(db, copyData, nil, nil, nil) == SQLITE_OK {
                    // Drop old table
                    if sqlite3_exec(db, "DROP TABLE Bourbon;", nil, nil, nil) == SQLITE_OK {
                        // Rename temp table to original name
                        if sqlite3_exec(db, "ALTER TABLE Bourbon_temp RENAME TO Bourbon;", nil, nil, nil) == SQLITE_OK {
                            print("BourbonDatabase: Successfully migrated age column")
                            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
                            return
                        }
                    }
                }
            }
            
            // If we get here, something went wrong
            print("BourbonDatabase: Migration failed, rolling back")
            sqlite3_exec(db, "ROLLBACK;", nil, nil, nil)
        } else {
            print("BourbonDatabase: No migration needed for age column")
        }
    }
    
    private func createTables() {
        print("BourbonDatabase: Creating tables")
        
        // Create the table with all required columns
        let createTableString = """
            CREATE TABLE IF NOT EXISTS Bourbon (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                proof REAL NOT NULL,
                age TEXT DEFAULT '',
                purchaseDate TEXT NOT NULL,
                purchaseLocation TEXT,
                purchaseLocationLatitude REAL,
                purchaseLocationLongitude REAL,
                flavorProfile TEXT,
                notes TEXT,
                price REAL,
                size TEXT,
                imageFilename TEXT,
                rating INTEGER DEFAULT 0,
                fillLevel INTEGER DEFAULT 100,
                dateOpened TEXT,
                dateEmptied TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
        """
        
        var statement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(db, createTableString, -1, &statement, nil)
        if prepareResult == SQLITE_OK {
            print("BourbonDatabase: Successfully prepared create table statement")
            
            let stepResult = sqlite3_step(statement)
            if stepResult == SQLITE_DONE {
                print("BourbonDatabase: Successfully created Bourbon table")
                
                // Check if we need to add the size column
                let checkSizeColumn = "PRAGMA table_info(Bourbon);"
                var checkStatement: OpaquePointer?
                var hasSizeColumn = false
                
                if sqlite3_prepare_v2(db, checkSizeColumn, -1, &checkStatement, nil) == SQLITE_OK {
                    while sqlite3_step(checkStatement) == SQLITE_ROW {
                        let columnName = String(cString: sqlite3_column_text(checkStatement, 1))
                        if columnName == "size" {
                            hasSizeColumn = true
                            break
                        }
                    }
                }
                sqlite3_finalize(checkStatement)
                
                // Add size column if it doesn't exist
                if !hasSizeColumn {
                    print("BourbonDatabase: Adding size column to Bourbon table")
                    let addSizeColumn = "ALTER TABLE Bourbon ADD COLUMN size TEXT;"
                    var alterStatement: OpaquePointer?
                    
                    if sqlite3_prepare_v2(db, addSizeColumn, -1, &alterStatement, nil) == SQLITE_OK {
                        if sqlite3_step(alterStatement) == SQLITE_DONE {
                            print("BourbonDatabase: Successfully added size column")
                        } else {
                            print("BourbonDatabase: Failed to add size column")
                            if let errorMessage = sqlite3_errmsg(db) {
                                print("BourbonDatabase: SQLite error message: \(String(cString: errorMessage))")
                            }
                        }
                    }
                    sqlite3_finalize(alterStatement)
                }
            } else {
                print("BourbonDatabase: Failed to create Bourbon table")
                print("BourbonDatabase: SQLite error code: \(stepResult)")
                if let errorMessage = sqlite3_errmsg(db) {
                    print("BourbonDatabase: SQLite error message: \(String(cString: errorMessage))")
                }
            }
        } else {
            print("BourbonDatabase: Failed to prepare create table statement")
            print("BourbonDatabase: SQLite error code: \(prepareResult)")
            if let errorMessage = sqlite3_errmsg(db) {
                print("BourbonDatabase: SQLite error message: \(String(cString: errorMessage))")
            }
        }
        sqlite3_finalize(statement)
    }
    
    private func verifyTableStructure() {
        let query = "PRAGMA table_info(Bourbon);"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            print("BourbonDatabase: Table structure:")
            while sqlite3_step(statement) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(statement, 1))
                let type = String(cString: sqlite3_column_text(statement, 2))
                print("BourbonDatabase: Column: \(name), Type: \(type)")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func addBourbon(_ bourbon: Bourbon) -> Int {
        print("BourbonDatabase: Starting addBourbon operation")
        var id: Int = 0
        
        dbQueue.sync {
            // Ensure database is initialized
            if db == nil {
                print("BourbonDatabase: Database is nil, attempting to initialize")
                initializeDatabase()
                if db == nil {
                    print("BourbonDatabase: Failed to initialize database for addBourbon")
                    return
                }
            }
            
            let now = dateFormatter.string(from: Date())
            print("BourbonDatabase: Preparing to insert bourbon with name: \(bourbon.name)")
            
            let insertString = """
                INSERT INTO Bourbon (
                    name, proof, age, purchaseDate, purchaseLocation,
                    purchaseLocationLatitude, purchaseLocationLongitude,
                    flavorProfile, notes, price, size, imageFilename,
                    rating, fillLevel, dateOpened, dateEmptied, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            var statement: OpaquePointer?
            let prepareResult = sqlite3_prepare_v2(db, insertString, -1, &statement, nil)
            if prepareResult == SQLITE_OK {
                print("BourbonDatabase: Successfully prepared SQL statement")
                
                // Bind values with error checking
                var bindError = false
                
                if sqlite3_bind_text(statement, 1, (bourbon.name as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind name")
                    bindError = true
                }
                if sqlite3_bind_double(statement, 2, bourbon.proof) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind proof")
                    bindError = true
                }
                if sqlite3_bind_text(statement, 3, (bourbon.age as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind age")
                    bindError = true
                }
                if sqlite3_bind_text(statement, 4, (dateFormatter.string(from: bourbon.purchaseDate) as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind purchaseDate")
                    bindError = true
                }
                if sqlite3_bind_text(statement, 5, (bourbon.purchaseLocation as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind purchaseLocation")
                    bindError = true
                }
                
                if let latitude = bourbon.purchaseLocationLatitude {
                    if sqlite3_bind_double(statement, 6, latitude) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind latitude")
                        bindError = true
                    }
                } else {
                    if sqlite3_bind_null(statement, 6) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind null latitude")
                        bindError = true
                    }
                }
                
                if let longitude = bourbon.purchaseLocationLongitude {
                    if sqlite3_bind_double(statement, 7, longitude) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind longitude")
                        bindError = true
                    }
                } else {
                    if sqlite3_bind_null(statement, 7) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind null longitude")
                        bindError = true
                    }
                }
                
                if sqlite3_bind_text(statement, 8, (bourbon.flavorProfile as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind flavorProfile")
                    bindError = true
                }
                if sqlite3_bind_text(statement, 9, (bourbon.notes as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind notes")
                    bindError = true
                }
                if sqlite3_bind_double(statement, 10, bourbon.price) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind price")
                    bindError = true
                }
                if sqlite3_bind_text(statement, 11, (bourbon.size as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind size")
                    bindError = true
                }
                if sqlite3_bind_text(statement, 12, (bourbon.imageFilename as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind imageFilename")
                    bindError = true
                }
                if sqlite3_bind_int(statement, 13, Int32(bourbon.rating)) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind rating")
                    bindError = true
                }
                if sqlite3_bind_int(statement, 14, Int32(bourbon.fillLevel)) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind fillLevel")
                    bindError = true
                }
                if let dateOpened = bourbon.dateOpened {
                    if sqlite3_bind_text(statement, 15, (dateFormatter.string(from: dateOpened) as NSString).utf8String, -1, nil) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind dateOpened")
                        bindError = true
                    }
                } else {
                    if sqlite3_bind_null(statement, 15) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind null dateOpened")
                        bindError = true
                    }
                }
                if let dateEmptied = bourbon.dateEmptied {
                    if sqlite3_bind_text(statement, 16, (dateFormatter.string(from: dateEmptied) as NSString).utf8String, -1, nil) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind dateEmptied")
                        bindError = true
                    }
                } else {
                    if sqlite3_bind_null(statement, 16) != SQLITE_OK {
                        print("BourbonDatabase: Failed to bind null dateEmptied")
                        bindError = true
                    }
                }
                if sqlite3_bind_text(statement, 17, (now as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind created_at")
                    bindError = true
                }
                if sqlite3_bind_text(statement, 18, (now as NSString).utf8String, -1, nil) != SQLITE_OK {
                    print("BourbonDatabase: Failed to bind updated_at")
                    bindError = true
                }
                
                if bindError {
                    print("BourbonDatabase: One or more bind operations failed")
                    sqlite3_finalize(statement)
                    return
                }
                
                print("BourbonDatabase: All values bound successfully, executing insert")
                let stepResult = sqlite3_step(statement)
                if stepResult == SQLITE_DONE {
                    id = Int(sqlite3_last_insert_rowid(db))
                    print("BourbonDatabase: Successfully inserted bourbon with ID: \(id)")
                } else {
                    print("BourbonDatabase: Failed to insert bourbon")
                    print("BourbonDatabase: SQLite error code: \(stepResult)")
                    if let errorMessage = sqlite3_errmsg(db) {
                        print("BourbonDatabase: SQLite error message: \(String(cString: errorMessage))")
                    }
                }
            } else {
                print("BourbonDatabase: Failed to prepare insert statement")
                print("BourbonDatabase: SQLite error code: \(prepareResult)")
                if let errorMessage = sqlite3_errmsg(db) {
                    print("BourbonDatabase: SQLite error message: \(String(cString: errorMessage))")
                }
            }
            sqlite3_finalize(statement)
        }
        
        return id
    }
    
    func getAllBourbons() -> [Bourbon] {
        var bourbons: [Bourbon] = []
        
        dbQueue.sync {
            // Check if database is initialized
            guard let db = self.db else {
                print("BourbonDatabase: Database not initialized")
                return
            }
            
            let queryString = "SELECT * FROM Bourbon;"
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    // Safely get text values with nil checks
                    let id = Int(sqlite3_column_int(statement, 0))
                    
                    guard let namePtr = sqlite3_column_text(statement, 1),
                          let purchaseDatePtr = sqlite3_column_text(statement, 4),
                          let purchaseLocationPtr = sqlite3_column_text(statement, 5),
                          let flavorProfilePtr = sqlite3_column_text(statement, 8),
                          let notesPtr = sqlite3_column_text(statement, 9),
                          let imageFilenamePtr = sqlite3_column_text(statement, 12) else {
                        print("BourbonDatabase: Failed to get required text values")
                        continue
                    }
                    
                    let name = String(cString: namePtr)
                    let proof = sqlite3_column_double(statement, 2)
                    let age = String(cString: sqlite3_column_text(statement, 3))
                    let purchaseDateString = String(cString: purchaseDatePtr)
                    let purchaseLocation = String(cString: purchaseLocationPtr)
                    let flavorProfile = String(cString: flavorProfilePtr)
                    let notes = String(cString: notesPtr)
                    let price = sqlite3_column_double(statement, 10)
                    let size = String(cString: sqlite3_column_text(statement, 11))
                    let imageFilename = String(cString: imageFilenamePtr)
                    let rating = Int(sqlite3_column_int(statement, 13))
                    let fillLevel = Int(sqlite3_column_int(statement, 14))
                    
                    var purchaseLocationLatitude: Double?
                    var purchaseLocationLongitude: Double?
                    var dateOpened: Date?
                    var dateEmptied: Date?
                    
                    if sqlite3_column_type(statement, 6) != SQLITE_NULL {
                        purchaseLocationLatitude = sqlite3_column_double(statement, 6)
                    }
                    if sqlite3_column_type(statement, 7) != SQLITE_NULL {
                        purchaseLocationLongitude = sqlite3_column_double(statement, 7)
                    }
                    if sqlite3_column_type(statement, 15) != SQLITE_NULL {
                        let dateOpenedString = String(cString: sqlite3_column_text(statement, 15))
                        dateOpened = dateFormatter.date(from: dateOpenedString)
                    }
                    if sqlite3_column_type(statement, 16) != SQLITE_NULL {
                        let dateEmptiedString = String(cString: sqlite3_column_text(statement, 16))
                        dateEmptied = dateFormatter.date(from: dateEmptiedString)
                    }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                    let purchaseDate = dateFormatter.date(from: purchaseDateString) ?? Date()
                    
                    let bourbon = Bourbon(id: id,
                                        name: name,
                                        proof: proof,
                                        age: age,
                                        purchaseDate: purchaseDate,
                                        purchaseLocation: purchaseLocation,
                                        purchaseLocationLatitude: purchaseLocationLatitude,
                                        purchaseLocationLongitude: purchaseLocationLongitude,
                                        flavorProfile: flavorProfile,
                                        notes: notes,
                                        price: price,
                                        size: size,
                                        imageFilename: imageFilename,
                                        rating: rating,
                                        fillLevel: fillLevel,
                                        dateOpened: dateOpened,
                                        dateEmptied: dateEmptied)
                    
                    bourbons.append(bourbon)
                }
            } else {
                print("BourbonDatabase: Failed to prepare query: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            sqlite3_finalize(statement)
        }
        
        return bourbons
    }
    
    func getBourbon(id: Int) -> Bourbon? {
        var bourbon: Bourbon?
        
        dbQueue.sync {
        let queryString = "SELECT * FROM Bourbon WHERE id = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, queryString, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(statement, 1))
                let proof = sqlite3_column_double(statement, 2)
                let age = String(cString: sqlite3_column_text(statement, 3))
                let purchaseDateString = String(cString: sqlite3_column_text(statement, 4))
                let purchaseLocation = String(cString: sqlite3_column_text(statement, 5))
                    let flavorProfile = String(cString: sqlite3_column_text(statement, 8))
                    let notes = String(cString: sqlite3_column_text(statement, 9))
                    let price = sqlite3_column_double(statement, 10)
                    let size = String(cString: sqlite3_column_text(statement, 11))
                    let imageFilename = String(cString: sqlite3_column_text(statement, 12))
                    let rating = Int(sqlite3_column_int(statement, 13))
                    let fillLevel = Int(sqlite3_column_int(statement, 14))
                    
                    var purchaseLocationLatitude: Double?
                    var purchaseLocationLongitude: Double?
                    var dateOpened: Date?
                    var dateEmptied: Date?
                    
                    if sqlite3_column_type(statement, 6) != SQLITE_NULL {
                        purchaseLocationLatitude = sqlite3_column_double(statement, 6)
                    }
                    if sqlite3_column_type(statement, 7) != SQLITE_NULL {
                        purchaseLocationLongitude = sqlite3_column_double(statement, 7)
                    }
                    if sqlite3_column_type(statement, 15) != SQLITE_NULL {
                        let dateOpenedString = String(cString: sqlite3_column_text(statement, 15))
                        dateOpened = dateFormatter.date(from: dateOpenedString)
                    }
                    if sqlite3_column_type(statement, 16) != SQLITE_NULL {
                        let dateEmptiedString = String(cString: sqlite3_column_text(statement, 16))
                        dateEmptied = dateFormatter.date(from: dateEmptiedString)
                    }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                let purchaseDate = dateFormatter.date(from: purchaseDateString) ?? Date()
                
                    bourbon = Bourbon(id: id,
                                    name: name,
                                    proof: proof,
                                    age: age,
                                    purchaseDate: purchaseDate,
                                    purchaseLocation: purchaseLocation,
                                    purchaseLocationLatitude: purchaseLocationLatitude,
                                    purchaseLocationLongitude: purchaseLocationLongitude,
                                    flavorProfile: flavorProfile,
                                    notes: notes,
                                    price: price,
                                    size: size,
                                    imageFilename: imageFilename,
                                    rating: rating,
                                    fillLevel: fillLevel,
                                    dateOpened: dateOpened,
                                    dateEmptied: dateEmptied)
            }
        }
        sqlite3_finalize(statement)
        }
        
        return bourbon
    }
    
    func updateBourbon(_ bourbon: Bourbon) -> Bool {
        var success = false
        
        dbQueue.sync {
            // Ensure database is initialized
            if db == nil {
                initializeDatabase()
                if db == nil {
                    print("BourbonDatabase: Failed to initialize database for updateBourbon")
                    return
                }
            }
            
            guard let id = bourbon.id else {
                print("BourbonDatabase: Cannot update bourbon without ID")
                return
            }
            
            let now = dateFormatter.string(from: Date())
            let updateString = """
                UPDATE Bourbon
                SET name = ?, proof = ?, age = ?, purchaseDate = ?,
                    purchaseLocation = ?, purchaseLocationLatitude = ?,
                    purchaseLocationLongitude = ?, flavorProfile = ?,
                    notes = ?, price = ?, size = ?, imageFilename = ?,
                    rating = ?, fillLevel = ?, dateOpened = ?, dateEmptied = ?, updated_at = ?
                WHERE id = ?;
            """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, updateString, -1, &statement, nil) == SQLITE_OK {
                print("BourbonDatabase: Successfully prepared update statement")
                
                sqlite3_bind_text(statement, 1, (bourbon.name as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 2, bourbon.proof)
                sqlite3_bind_text(statement, 3, (bourbon.age as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (dateFormatter.string(from: bourbon.purchaseDate) as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 5, (bourbon.purchaseLocation as NSString).utf8String, -1, nil)
                
                if let latitude = bourbon.purchaseLocationLatitude {
                    sqlite3_bind_double(statement, 6, latitude)
                } else {
                    sqlite3_bind_null(statement, 6)
                }
                
                if let longitude = bourbon.purchaseLocationLongitude {
                    sqlite3_bind_double(statement, 7, longitude)
                } else {
                    sqlite3_bind_null(statement, 7)
                }
                
                sqlite3_bind_text(statement, 8, (bourbon.flavorProfile as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 9, (bourbon.notes as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 10, bourbon.price)
                sqlite3_bind_text(statement, 11, (bourbon.size as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 12, (bourbon.imageFilename as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 13, Int32(bourbon.rating))
                sqlite3_bind_int(statement, 14, Int32(bourbon.fillLevel))
                if let dateOpened = bourbon.dateOpened {
                    sqlite3_bind_text(statement, 15, (dateFormatter.string(from: dateOpened) as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 15)
                }
                if let dateEmptied = bourbon.dateEmptied {
                    sqlite3_bind_text(statement, 16, (dateFormatter.string(from: dateEmptied) as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 16)
                }
                sqlite3_bind_text(statement, 17, (now as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 18, Int32(id))
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    success = true
                    print("BourbonDatabase: Successfully updated bourbon with ID: \(id)")
                } else {
                    print("BourbonDatabase: Failed to update bourbon: \(String(cString: sqlite3_errmsg(db)))")
                }
            } else {
                print("BourbonDatabase: Failed to prepare update statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            sqlite3_finalize(statement)
        }
        
        return success
    }
    
    func saveImage(_ image: UIImage, filename: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }
    
    func deleteImage(filename: String) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try fileManager.removeItem(at: imageURL)
        } catch {
            print("Error deleting image: \(error.localizedDescription)")
        }
    }
    
    func deleteBourbon(id: Int) -> Bool {
        var success = false
        
        dbQueue.sync {
            // Ensure database is initialized
            if db == nil {
                initializeDatabase()
                if db == nil {
                    print("BourbonDatabase: Failed to initialize database for deleteBourbon")
                    return
                }
            }
            
            let deleteString = "DELETE FROM Bourbon WHERE id = ?;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, deleteString, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(id))
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("BourbonDatabase: Successfully deleted bourbon with ID: \(id)")
                    success = true
                } else {
                    print("BourbonDatabase: Failed to delete bourbon: \(String(cString: sqlite3_errmsg(db)))")
                }
            } else {
                print("BourbonDatabase: Failed to prepare delete statement: \(String(cString: sqlite3_errmsg(db)))")
            }
            
            sqlite3_finalize(statement)
        }
        
        return success
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
} 

