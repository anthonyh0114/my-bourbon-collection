let createTableString = """
    CREATE TABLE IF NOT EXISTS Bourbon (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        proof REAL NOT NULL,
        age INTEGER DEFAULT 0,
        purchaseDate TEXT NOT NULL,
        purchaseLocation TEXT,
        purchaseLocationLatitude REAL,
        purchaseLocationLongitude REAL,
        flavorProfile TEXT,
        notes TEXT,
        price REAL,
        size TEXT,
        category TEXT DEFAULT 'Standard',
        imageFilename TEXT,
        rating INTEGER DEFAULT 0,
        fillLevel INTEGER DEFAULT 100,
        dateOpened TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
    );
"""

if sqlite3_bind_text(statement, 11, (bourbon.size as NSString).utf8String, -1, nil) != SQLITE_OK {
    print("BourbonDatabase: Failed to bind size")
    bindError = true
}
if sqlite3_bind_text(statement, 12, (bourbon.category as NSString).utf8String, -1, nil) != SQLITE_OK {
    print("BourbonDatabase: Failed to bind category")
    bindError = true
}
if sqlite3_bind_text(statement, 13, (bourbon.imageFilename as NSString).utf8String, -1, nil) != SQLITE_OK {
    print("BourbonDatabase: Failed to bind imageFilename")
    bindError = true
}
if sqlite3_bind_int(statement, 14, Int32(bourbon.rating)) != SQLITE_OK {
    print("BourbonDatabase: Failed to bind rating")
    bindError = true
}
if sqlite3_bind_int(statement, 15, Int32(bourbon.fillLevel)) != SQLITE_OK {
    print("BourbonDatabase: Failed to bind fillLevel")
    bindError = true
}
if let dateOpened = bourbon.dateOpened {
    if sqlite3_bind_text(statement, 16, (dateFormatter.string(from: dateOpened) as NSString).utf8String, -1, nil) != SQLITE_OK {
        print("BourbonDatabase: Failed to bind dateOpened")
        bindError = true
    }
} else {
    if sqlite3_bind_null(statement, 16) != SQLITE_OK {
        print("BourbonDatabase: Failed to bind null dateOpened")
        bindError = true
    }
}

let price = sqlite3_column_double(statement, 10)
let size = String(cString: sqlite3_column_text(statement, 11))
let category = String(cString: sqlite3_column_text(statement, 12))
let imageFilename = String(cString: imageFilenamePtr)
let rating = Int(sqlite3_column_int(statement, 14))
let fillLevel = Int(sqlite3_column_int(statement, 15))

var dateOpened: Date?
if sqlite3_column_type(statement, 16) != SQLITE_NULL {
    let dateOpenedString = String(cString: sqlite3_column_text(statement, 16))
    dateOpened = dateFormatter.date(from: dateOpenedString)
}

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
                    category: category,
                    imageFilename: imageFilename,
                    rating: rating,
                    fillLevel: fillLevel,
                    dateOpened: dateOpened)

sqlite3_bind_text(statement, 11, (bourbon.size as NSString).utf8String, -1, nil)
sqlite3_bind_text(statement, 12, (bourbon.category as NSString).utf8String, -1, nil)
sqlite3_bind_text(statement, 13, (bourbon.imageFilename as NSString).utf8String, -1, nil)
sqlite3_bind_int(statement, 14, Int32(bourbon.rating))
sqlite3_bind_int(statement, 15, Int32(bourbon.fillLevel))
if let dateOpened = bourbon.dateOpened {
    sqlite3_bind_text(statement, 16, (dateFormatter.string(from: dateOpened) as NSString).utf8String, -1, nil)
} else {
    sqlite3_bind_null(statement, 16)
} 