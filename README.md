# BrainCoinz - iOS Parental Control Screen Time App

## Overview

BrainCoinz is a comprehensive iOS application designed to help parents manage and motivate their children's screen time through an advanced gamified learning economy. The app integrates with Apple's Screen Time frameworks to create a balanced system where children earn virtual Coinz through educational app usage, which they can spend on entertainment apps, while still respecting parent-set daily time limits for healthy screen time management.

## Features

### Core Functionality
- **Coinz Economy System**: Gamified learning where children earn virtual Coinz through educational apps and spend them on entertainment
- **Cumulative Rewards**: Coinz accumulate across days, encouraging saving and long-term planning
- **Balanced Time Management**: Coinz purchases are constrained by parent-set daily time limits for responsible screen time
- **Minimum Learning Requirements**: Configurable daily learning time requirements before accessing reward apps
- **Learning Goal Management**: Set daily time targets for educational apps with progress tracking
- **App Categorization**: Separate learning apps (educational) from reward apps (entertainment) with custom rates
- **Parent Balance Controls**: Award bonuses, apply penalties, and manage child's Coinz balance with full oversight
- **Real-time Progress Tracking**: Monitor learning time, Coinz earning, and goal progress with live updates
- **Family-Friendly Design**: Separate interfaces for parents and children with age-appropriate designs
- **Remote Control**: Manage child devices from parent's device across different iCloud accounts (v2.0+)
- **True Multi-Family Support**: Connect family members across different iCloud accounts (v3.0+)

### Technical Integration
- **Family Controls Framework**: Parental authorization and app selection
- **DeviceActivity Framework**: Real-time app usage monitoring
- **ManagedSettings Framework**: App blocking and unblocking
- **CloudKit Framework**: Cross-device family data synchronization (v2.0+)
- **Core Data**: Local data persistence
- **User Notifications**: Progress updates and goal completion alerts

## Architecture

### Project Structure
```
BrainCoinz/
├── BrainCoinzApp.swift          # Main app entry point
├── ContentView.swift            # Navigation coordinator
├── Managers/                    # Business logic managers
│   ├── AuthenticationManager.swift
│   ├── FamilyControlsManager.swift
│   ├── DeviceActivityManager.swift
│   ├── ManagedSettingsManager.swift
│   └── NotificationManager.swift
├── Views/                       # SwiftUI views
│   ├── ParentDashboardView.swift
│   ├── ChildDashboardView.swift
│   ├── OnboardingView.swift
│   └── GoalCreationView.swift
├── Data/                        # Core Data models
│   └── DataModel.xcdatamodeld
└── Assets.xcassets             # App resources
```

### Key Components

#### 1. Authentication System
- **Dual Role Support**: Parent and child authentication modes
- **Secure Access**: Parent code protection and biometric authentication
- **Session Management**: Persistent login state with secure storage

#### 2. Family Controls Integration
- **Authorization Flow**: Guided setup for Family Controls permissions
- **App Selection**: FamilyActivityPicker integration for choosing apps
- **Permission Management**: Real-time authorization status monitoring

#### 3. Goal Management System
- **Flexible Goals**: Customizable daily time targets (15-120 minutes)
- **Multi-App Support**: Multiple learning and reward apps per goal
- **Progress Tracking**: Real-time monitoring of learning time accumulation

#### 4. Device Activity Monitoring
- **Screen Time Tracking**: Integration with DeviceActivity framework
- **Usage Statistics**: Detailed analytics on app usage patterns
- **Goal Completion Detection**: Automatic reward unlocking triggers

#### 5. Managed Settings Control
- **App Blocking**: Automatic blocking of reward apps until goals are met
- **Dynamic Unlocking**: Seamless access restoration upon goal completion
- **Daily Reset**: Automatic re-blocking for new daily goals

## Data Models

### Core Data Schema

#### User Entity
- `userID`: Unique identifier (UUID)
- `name`: Display name (String)
- `role`: User role - "parent" or "child" (String)
- `parentCode`: Access code for parent authentication (String, optional)
- `createdAt`: Account creation date (Date)
- `isActive`: Account status (Boolean)

#### LearningGoal Entity
- `goalID`: Unique identifier (UUID)
- `targetDurationMinutes`: Daily time target (Int32)
- `isActive`: Goal status (Boolean)
- `createdAt`: Goal creation date (Date)
- `updatedAt`: Last modification date (Date)
- `user`: Relationship to User entity

#### SelectedApp Entity
- `appBundleID`: App bundle identifier (String)
- `appName`: Display name (String)
- `appType`: "learning" or "reward" (String)
- `isBlocked`: Current blocking status (Boolean)
- `selectedAt`: Selection date (Date)
- `iconData`: App icon data (Binary, optional)

#### AppUsageSession Entity
- `sessionID`: Unique identifier (UUID)
- `appBundleID`: App bundle identifier (String)
- `startTime`: Session start time (Date)
- `endTime`: Session end time (Date, optional)
- `duration`: Session duration in seconds (Double)
- `user`: Relationship to User entity

## Setup Instructions

### Prerequisites
1. **iOS 16.0+**: Required for Screen Time framework features
2. **Xcode 15.0+**: Latest development environment
3. **Apple Developer Account**: For Family Controls entitlements
4. **Physical Device**: Screen Time APIs require real device testing

### Project Configuration

#### 1. Bundle Identifier and Team
```swift
// Update in project settings
PRODUCT_BUNDLE_IDENTIFIER = "com.yourcompany.braincoinz"
DEVELOPMENT_TEAM = "YOUR_TEAM_ID"
```

#### 2. Required Entitlements
The app requires these specific entitlements in `BrainCoinz.entitlements`:
- `com.apple.developer.family-controls`
- `com.apple.developer.deviceactivity`
- `com.apple.developer.managedsettings`
- `com.apple.developer.screentime-request`

#### 3. Info.plist Permissions
Add usage descriptions for:
- `NSFamilyControlsUsageDescription`
- `NSUserNotificationsUsageDescription`
- `NSLocalNetworkUsageDescription`

### Building and Running

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd BrainCoinz
   ```

2. **Open in Xcode**
   ```bash
   open BrainCoinz.xcodeproj
   ```

3. **Configure Signing**
   - Select your development team
   - Ensure proper provisioning profiles
   - Verify entitlements are enabled

4. **Build and Run**
   - Connect a physical iOS device (required for Screen Time APIs)
   - Build and run the project (⌘+R)

## Usage Guide

### First-Time Setup

#### 1. Onboarding Flow
1. **Welcome Screen**: Introduction to app features
2. **How It Works**: Step-by-step explanation
3. **Family Controls Permission**: Authorization request
4. **Notification Permission**: Alert preferences setup
5. **Completion**: Ready to use confirmation

#### 2. Parent Setup
1. **Sign In**: Create or enter parent access code
2. **Family Controls**: Grant authorization in system settings
3. **Create Goal**: Set daily learning time target
4. **Select Learning Apps**: Choose educational apps to track
5. **Select Reward Apps**: Choose entertainment apps to block/unlock

### Daily Operation

#### 1. Child Experience
1. **View Progress**: Visual progress circle showing completion
2. **Check Goals**: See current learning targets and remaining time
3. **Use Learning Apps**: Tracked time contributes to goal
4. **Unlock Rewards**: Automatic access when goal is completed
5. **Celebration**: Visual feedback for achievements

#### 2. Parent Experience
1. **Monitor Progress**: Real-time tracking of child's learning time
2. **View Statistics**: Weekly and daily usage analytics
3. **Manage Goals**: Create, edit, or delete learning objectives
4. **Adjust Settings**: Modify app selections and time targets
5. **Receive Notifications**: Goal completion and progress alerts

## API Integration

### Apple Frameworks

#### Family Controls
```swift
// Authorization request
try await AuthorizationCenter.shared.requestAuthorization(for: .individual)

// App selection
FamilyActivityPicker(selection: $selectedApps)
```

#### DeviceActivity
```swift
// Monitor setup
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 0, minute: 0),
    intervalEnd: DateComponents(hour: 23, minute: 59),
    repeats: true
)

try deviceActivityCenter.startMonitoring(monitorName, during: schedule)
```

#### ManagedSettings
```swift
// Block apps
managedSettingsStore.application.blockedApplications = rewardApps

// Unblock apps
managedSettingsStore.application.blockedApplications = Set<ApplicationToken>()
```

### Notification System

#### Local Notifications
- Goal completion celebrations
- Progress milestone alerts
- Daily learning reminders
- Time exceeded warnings

#### Interactive Notifications
- View progress action
- Open app action
- Start learning action

## Privacy and Security

### Data Protection
- **Local Storage**: All data stored locally using Core Data
- **No Cloud Sync**: Privacy-first approach with device-only data
- **Secure Authentication**: Parent codes stored in Keychain
- **Minimal Data Collection**: Only essential usage statistics

### Apple Guidelines Compliance
- **Screen Time Privacy**: Follows Apple's strict privacy requirements
- **Family Controls**: Proper authorization and permission flows
- **App Store Guidelines**: Compliant with parental control app policies
- **Child Privacy**: COPPA-compliant design and data handling

## Customization Options

### Goal Configuration
- **Time Targets**: 15, 30, 45, 60, 90, or 120 minutes
- **App Categories**: Custom learning and reward app selections
- **Daily Reset**: Automatic goal renewal at midnight
- **Flexible Scheduling**: Support for different daily schedules

### Notification Settings
- **Progress Updates**: Configurable milestone notifications
- **Completion Alerts**: Celebration messages for achievements
- **Reminder Schedule**: Customizable daily learning reminders
- **Parent Notifications**: Optional progress reports

### Visual Customization
- **Child Dashboard**: Motivational design with progress visualization
- **Parent Dashboard**: Professional interface with detailed analytics
- **Color Themes**: App-appropriate color schemes
- **Accessibility**: VoiceOver and Dynamic Type support

## Troubleshooting

### Common Issues

#### 1. Family Controls Authorization Failed
**Problem**: Authorization request denied or failed
**Solution**:
- Ensure iOS 16.0+ is installed
- Check Apple ID has Family Controls enabled
- Restart app and retry authorization
- Verify entitlements are properly configured

#### 2. Apps Not Blocking/Unblocking
**Problem**: Reward apps remain accessible when they should be blocked
**Solution**:
- Verify ManagedSettings entitlement
- Check app tokens are valid
- Ensure goal is properly configured
- Restart device if necessary

#### 3. DeviceActivity Not Tracking
**Problem**: Learning time not accumulating
**Solution**:
- Confirm DeviceActivity entitlement
- Check monitoring is active
- Verify learning apps are properly selected
- Test with background app refresh enabled

#### 4. Core Data Sync Issues
**Problem**: Data not persisting or loading
**Solution**:
- Check Core Data model configuration
- Verify save operations are successful
- Review fetch request predicates
- Clear app data if corruption suspected

### Debugging Tips

#### 1. Console Logging
Enable detailed logging for debugging:
```swift
print("Family Controls Status: \(familyControlsManager.authorizationStatus)")
print("Active Monitoring: \(deviceActivityManager.isMonitoring)")
print("Blocked Apps Count: \(managedSettingsManager.blockedAppsCount)")
```

#### 2. Simulator Limitations
- Family Controls APIs require physical device
- DeviceActivity monitoring unavailable in simulator
- ManagedSettings blocking won't work in simulator
- Test core UI logic in simulator, APIs on device

## Future Enhancements

### Planned Features
1. **Multi-Child Support**: Manage multiple children from one parent account
2. **Cloud Sync**: Optional iCloud synchronization across family devices
3. **Advanced Analytics**: Detailed usage reports and trends
4. **Custom Rewards**: Non-app rewards like extra screen time or privileges
5. **Scheduling**: Time-based goals and restrictions
6. **Parental Insights**: AI-powered recommendations for optimal learning

### Technical Improvements
1. **Background Processing**: Enhanced monitoring accuracy
2. **Widget Support**: Home screen progress widgets
3. **Shortcuts Integration**: Siri voice commands for quick actions
4. **iPad Optimization**: Enhanced UI for larger screens
5. **Accessibility**: Expanded accessibility feature support

## Support and Contributing

### Getting Help
- **Documentation**: Refer to Apple's Screen Time framework documentation
- **Issues**: Check common troubleshooting section above
- **Community**: iOS developer forums for Screen Time related questions

### Development Guidelines
- **Code Style**: Follow Swift conventions and comment thoroughly
- **Testing**: Test all functionality on physical devices
- **Privacy**: Maintain strict privacy standards
- **Performance**: Optimize for battery usage and responsiveness

## License

This project is intended for educational and demonstration purposes. Please ensure compliance with Apple's developer guidelines and applicable laws when implementing parental control features.

## Version History

### v4.0.0 (Coinz Economy System Release) - December 2024
- **🪙 Coinz Reward System**: Complete gamified learning economy where kids earn virtual Coinz through educational app usage
- **⚖️ Balanced Economy**: Coinz accumulate across days but are constrained by parent-set daily time limits for healthy screen time
- **📚 Minimum Learning Requirements**: Configurable daily learning time (default 15 minutes) required before accessing reward apps
- **⏰ Daily Time Limits**: Parents can set individual daily time limits per reward app with real-time usage tracking
- **💰 Cumulative Coinz System**: Unused Coinz carry over to the next day, encouraging saving and planning
- **🎛️ Parent Balance Controls**: Award bonus, apply penalties, reset, increase, or decrease child's Coinz balance with custom reasons
- **📊 Smart Purchase Validation**: Three-tier validation system (learning requirement → Coinz balance → daily time limits)
- **📱 Enhanced Child Dashboard**: Visual indicators showing available time vs. limiting factors ("Limited by Coinz" vs "Limited by daily time")
- **📈 Usage Statistics**: Real-time monitoring of daily app usage vs. limits for parent oversight
- **🎯 Transaction History**: Complete audit trail of all Coinz transactions with parent adjustment tracking
- **💜 Carryover Indicators**: Visual highlights showing Coinz carried over from previous days
- **🔄 Economy Integration**: Sophisticated validation logic preventing purchases that exceed any constraint
- **⚡ Real-time Notifications**: Coinz earning alerts, purchase confirmations, and limit notifications
- **🎮 Reward App Economy**: Customizable Coinz costs per minute for different entertainment apps
- **📚 Learning App Rates**: Configurable earning rates to incentivize priority educational content

### v3.0.0 (True Multi-Family Release)
- **👨‍👩‍👧‍👦 True Multi-Family Support**: Multiple family members across different iCloud accounts
- **🔗 CloudKit Shared Databases**: Secure, synchronized data access without requiring shared iCloud account
- **📧 Family Invitations**: Email/phone invitation system with acceptance workflows
- **⚡ Real-time Synchronization**: Family usage data, permissions, and settings sync across accounts
- **🔐 Cross-Account Security**: Secure family membership management with role-based permissions
- **📱 Native Screen Time Behavior**: Mirrors iOS native Screen Time multi-family functionality

### v2.0.0 (Remote Control Release)
- **Remote Family Control**: Parents can now control child devices from their own device
- **CloudKit Integration**: Family data sync across devices using iCloud
- **Multi-Device Management**: Support for multiple child devices per family account
- **Real-time Remote Commands**: Block/unblock apps, create goals, send messages remotely
- **Family Account System**: Secure device pairing with 6-digit family codes
- **Cross-Device Synchronization**: Goals, app selections, and usage data sync automatically
- **Enhanced Parent Dashboard**: New remote control interface with device management
- **Device Pairing Flow**: Easy setup process for connecting family devices
- **QR Code Sharing**: Quick device registration using QR codes
- **Privacy-First Cloud Sync**: Secure CloudKit implementation following Apple guidelines

### v1.0.0 (Initial Release)
- Complete parental control system
- Family Controls integration
- DeviceActivity monitoring
- ManagedSettings app blocking
- Core Data persistence
- Notification system
- Onboarding flow
- Parent and child dashboards

---

**Note**: This app requires Apple's Screen Time frameworks which are only available on iOS 16.0+ and require specific entitlements that must be approved by Apple. Ensure your Apple Developer account has the necessary permissions before attempting to build and test the app.