# SocialEats - A Social Restaurant Discovery and Meetup App

SocialEats is a modern iOS application built with SwiftUI that combines location-based restaurant discovery with real-time social connectivity. Users can discover nearby restaurants, select where they plan to dine, and see where their friends are going - all with a 12-hour expiration system that keeps plans fresh and engaging.

## Features

### 🗺️ Restaurant Discovery
- Interactive map showing nearby restaurants using Google Maps API
- Detailed restaurant information including ratings, price levels, and photos
- Location-based search with customizable radius
- Beautiful restaurant detail views with contact information

### 👥 Social Features
- Add friends by email or from contacts
- Real-time friend activity tracking
- See where friends plan to dine
- 12-hour restaurant selection expiration system
- Friend status indicators (online/offline)
- Push notifications for friend activity and requests

### ⭐ Reviews & Ratings
- Write and read restaurant reviews
- 5-star rating system with detailed feedback
- Photo uploads with reviews
- Like and interact with reviews
- Verified visit badges for authentic reviews
- Push notifications for review interactions

### 👥 Group Dining Coordination
- Create group dining events at restaurants
- Invite friends to join group meals
- Set maximum participants and event details
- Real-time participant tracking
- Group event notifications and reminders
- Join/leave group dining events

### 📸 Photo Sharing at Restaurants
- Share photos from restaurant visits
- Tag photos with categories (food, drinks, interior, etc.)
- Like and interact with friends' photos
- Verified photo badges for current restaurant visits
- Photo discovery and exploration
- Restaurant photo galleries

### 🔐 Authentication & Security
- Firebase Authentication integration
- Secure user registration and login
- Password reset functionality
- User profile management

### 📱 Modern iOS Design
- Built with SwiftUI for iOS 14+
- Clean, intuitive user interface
- Responsive design for all iOS devices
- System integration (phone calls, web links)

## Architecture

This project follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
socialeats/
├── Models/                 # Data models and structures
│   ├── User.swift
│   ├── Restaurant.swift
│   ├── Friend.swift
│   ├── Review.swift
│   ├── GroupDining.swift
│   └── RestaurantPhoto.swift
├── Views/                  # SwiftUI views organized by feature
│   ├── Authentication/
│   ├── Restaurants/
│   │   ├── RestaurantDetailView.swift
│   │   └── WriteReviewView.swift
│   ├── Friends/
│   ├── GroupDining/
│   │   ├── GroupDiningView.swift
│   │   ├── CreateGroupDiningView.swift
│   │   └── GroupDiningCard.swift
│   ├── PhotoSharing/
│   │   ├── PhotoSharingView.swift
│   │   ├── PhotoCard.swift
│   │   └── UploadPhotoView.swift
│   ├── Components/
│   └── ContentView.swift
├── ViewModels/            # Business logic and state management
│   ├── RestaurantsViewModel.swift
│   ├── FriendsViewModel.swift
│   ├── GroupDiningViewModel.swift
│   └── RestaurantPhotoViewModel.swift
├── Services/              # External API and data services
│   ├── AuthenticationService.swift
│   ├── UserService.swift
│   ├── GooglePlacesService.swift
│   ├── LocationService.swift
│   ├── NotificationService.swift
│   ├── ReviewsService.swift
│   ├── GroupDiningService.swift
│   └── RestaurantPhotoService.swift
│   ├── NotificationService.swift
│   └── ReviewsService.swift
├── Utilities/             # Helper functions and extensions
│   ├── Constants.swift
│   └── Extensions.swift
├── Resources/             # Assets, Info.plist, etc.
├── SocialEatsApp.swift    # Main app entry point
└── Package.swift          # Swift Package Manager configuration
```

## Prerequisites

- Xcode 14.0 or later
- iOS 14.0 or later
- Swift 5.5 or later
- CocoaPods or Swift Package Manager

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd socialeats
```

### 2. Firebase Setup
1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add an iOS app to your project with bundle identifier `com.yourcompany.socialeats`
4. Download the `GoogleService-Info.plist` file
5. Add the file to your Xcode project (drag it into the Resources folder)
6. Enable Authentication with Email/Password in Firebase Console
7. Set up Cloud Firestore database

### 3. Google Maps & Places API Setup
1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for iOS
   - Places API
4. Create API credentials (API Key)
5. Restrict the API key to your app's bundle identifier
6. Update the API keys in `Constants.swift`:
   ```swift
   static let googleMapsAPIKey = "YOUR_GOOGLE_MAPS_API_KEY"
   static let googlePlacesAPIKey = "YOUR_GOOGLE_PLACES_API_KEY"
   ```

### 4. Install Dependencies

#### Using Swift Package Manager (Recommended)
1. Open the project in Xcode
2. Go to File → Add Package Dependencies
3. Add the following packages:
   - Firebase: `https://github.com/firebase/firebase-ios-sdk`
   - Google Maps: `https://github.com/googlemaps/ios-maps-sdk`

Note: Make sure to add Firebase/Messaging for push notifications support.

#### Using CocoaPods
Create a `Podfile` in the project root:
```ruby
platform :ios, '14.0'
use_frameworks!

target 'SocialEats' do
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Messaging'
  pod 'Firebase/Storage'
  pod 'GoogleMaps'
  pod 'GooglePlaces'
end
```

Then run:
```bash
pod install
```

### 5. Configure Push Notifications
1. In the Firebase Console, go to your project settings
2. Navigate to Cloud Messaging tab
3. Upload your APNs certificates (for production) or enable APNs development
4. Update the `YOUR_SERVER_KEY` in `NotificationService.swift` with your Firebase Server Key
5. Add Push Notifications capability in Xcode project settings
6. Add Background Modes capability and enable "Remote notifications"

### 6. Configure Xcode Project
1. Add location usage description in `Info.plist` (already included)
2. Add contacts usage description in `Info.plist` (already included)
3. Add push notifications capability in project settings
4. Set your development team in project settings
5. Update the bundle identifier to match your Firebase project

### 7. Build and Run
1. Select your target device or simulator
2. Build and run the project (⌘+R)

## Configuration

### Firebase Rules
Set up the following Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        resource.data.friends.hasAny([request.auth.uid]);
    }
  }
}
```

### Google Maps Configuration
1. Add your API key to the app delegate or in the GooglePlacesService
2. Ensure the API key has proper restrictions for security
3. Test that maps and places are loading correctly

## Usage

### For Users
1. **Sign Up/Sign In**: Create an account or log in with existing credentials
2. **Allow Location**: Grant location permission to find nearby restaurants
3. **Discover Restaurants**: Browse the map to see nearby dining options
4. **Select Restaurant**: Tap on a restaurant and select it as your dining choice
5. **Add Friends**: Search for friends by email or import from contacts
6. **Social Features**: See where your friends plan to dine and coordinate meetups

### For Developers
1. **Adding New Features**: Follow the MVVM pattern
2. **Extending Models**: Add new properties to existing models or create new ones
3. **New Views**: Create views in the appropriate subfolder under Views/
4. **Business Logic**: Implement in ViewModels, keep Views focused on UI
5. **External APIs**: Add new services in the Services/ folder

## Key Components

### Models
- `User`: Represents app users with authentication and social data
- `Restaurant`: Google Places data with selection tracking
- `Friend`: Social connections with activity status
- `GroupDining`: Group dining event coordination
- `RestaurantPhoto`: Photo sharing with tagging and interactions

### Services
- `AuthenticationService`: Firebase Auth integration
- `UserService`: Firestore user data management
- `GooglePlacesService`: Restaurant discovery and details
- `LocationService`: Core Location wrapper with permissions
- `NotificationService`: Push notifications for social features
- `ReviewsService`: Restaurant reviews and ratings management
- `GroupDiningService`: Group dining event management
- `RestaurantPhotoService`: Photo upload and sharing functionality

### ViewModels
- `RestaurantsViewModel`: Manages map data and restaurant selection
- `FriendsViewModel`: Handles social features and friend management
- `GroupDiningViewModel`: Manages group dining events and invitations
- `RestaurantPhotoViewModel`: Handles photo sharing and interactions

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing code style and architecture patterns
4. Write tests for new functionality
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Security Considerations

- API keys should never be committed to version control
- Use environment variables or secure configuration for production
- Implement proper Firebase security rules
- Validate all user inputs
- Use HTTPS for all network requests

## Future Enhancements

- [x] Push notifications for friend activity
- [x] Restaurant reviews and ratings
- [x] Group dining coordination
- [x] Photo sharing at restaurants
- [ ] Restaurant reservations integration
- [ ] Social feed with dining updates
- [ ] Apple Maps integration as alternative
- [ ] Offline mode with cached data

## Troubleshooting

### Common Issues

1. **Maps not loading**: Check API key configuration and billing account
2. **Location not working**: Verify permissions in device settings
3. **Firebase connection**: Ensure GoogleService-Info.plist is properly added
4. **Build errors**: Clean build folder and update dependencies

### Support

For issues and questions:
1. Check the existing documentation
2. Search through GitHub issues
3. Create a new issue with detailed information
4. Include device logs and reproduction steps

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Firebase for authentication and database services
- Google Maps Platform for location and places data
- SwiftUI community for best practices and examples
- iOS development community for guidance and support

---

**SocialEats** - Bringing people together through great food! 🍽️👥
