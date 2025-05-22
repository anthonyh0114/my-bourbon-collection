class Bourbon: Codable {
    var id: Int?
    var name: String
    var proof: Double
    var age: Int
    var purchaseDate: Date
    var purchaseLocation: String
    var purchaseLocationLatitude: Double?
    var purchaseLocationLongitude: Double?
    var flavorProfile: String
    var notes: String
    var price: Double
    var size: String
    var category: String
    var imageFilename: String
    var rating: Int // 1-3 star rating
    var fillLevel: Int // 0-100 percentage
    var dateOpened: Date?
    
    init(id: Int? = nil, name: String, proof: Double, age: Int = 0, purchaseDate: Date, purchaseLocation: String, purchaseLocationLatitude: Double? = nil, purchaseLocationLongitude: Double? = nil, flavorProfile: String, notes: String, price: Double, size: String = "", category: String = "Standard", imageFilename: String, rating: Int = 0, fillLevel: Int = 100, dateOpened: Date? = nil) {
        self.id = id
        self.name = name
        self.proof = proof
        self.age = age
        self.purchaseDate = purchaseDate
        self.purchaseLocation = purchaseLocation
        self.purchaseLocationLatitude = purchaseLocationLatitude
        self.purchaseLocationLongitude = purchaseLocationLongitude
        self.flavorProfile = flavorProfile
        self.notes = notes
        self.price = price
        self.size = size
        self.category = category
        self.imageFilename = imageFilename
        self.rating = rating
        self.fillLevel = fillLevel
        self.dateOpened = dateOpened
    }
} 