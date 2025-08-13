# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pixivel is a Flutter application that serves as a Pixiv client, allowing users to browse illustrations, rankings, and artist profiles. The app supports multiple platforms (iOS, Android, macOS, Linux, Windows, Web) and implements Material Design 3 with both light and dark themes.

## Development Commands

### Basic Flutter Commands
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build macos` - Build macOS app
- `flutter build web` - Build web version
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Code Quality
- `flutter analyze` - Run static analysis (uses flutter_lints rules)
- `flutter test` - Run unit tests
- `flutter test test/widget_test.dart` - Run specific test file

### App Icon Generation
- `flutter pub get` - Install dependencies including flutter_launcher_icons
- `dart run flutter_launcher_icons` - Generate app icons from assets/logo.png for all platforms

## Architecture Overview

### Core Structure
The app follows a standard Flutter architecture with clear separation of concerns:

- **Pages**: Main UI screens implementing specific functionality
- **Models**: Data classes representing API responses and entities
- **Services**: Business logic and API communication
- **Widgets**: Reusable UI components
- **Utils**: Cross-platform utilities (download functionality)

### Key Components

#### Navigation Structure
The app uses a bottom navigation pattern implemented in `MainScaffold`:
- **RankPage**: Display illustration rankings with various modes (daily, weekly, monthly, etc.)
- **SearchPage**: Search functionality for illustrations and artists
- **IdJumpPage**: Direct navigation to illustrations by ID
- **AboutPage**: App information and settings

#### API Service (`lib/services/api_service.dart`)
Handles all communication with the Pixivel API:
- Base URL: `https://api.pixivel.art:443/v3`
- Implements load balancing across proxy servers
- Manages image URL generation with different quality levels
- Supports various ranking modes and content types

#### Models
Core data structures:
- **Illust**: Main illustration entity with metadata, tags, and statistics
- **User**: Artist profile information with image assets
- **ApiResponse**: Wrapper for paginated API responses
- **UgoiraData**: Animated illustration metadata

#### Key Widgets
- **WaterfallGrid**: Pinterest-style grid layout for illustrations using `flutter_staggered_grid_view`
- **ShimmerLoading**: Loading placeholder animations
- **IdJumpDialog**: Quick navigation dialog

### Theme and Localization
- Material 3 design with custom color scheme (primary: #0096FA)
- Google Fonts integration with CJK fallbacks
- Multi-language support: English, Chinese (CN/TW), Japanese
- Platform-adaptive scroll behavior

### Platform-Specific Features
- **Download functionality**: Conditional exports for web vs native platforms
- **Permission handling**: Gallery access for saving images
- **Hero animations**: Shared element transitions between screens (ensure unique hero tags)

### Image Management
Uses `cached_network_image` for:
- Automatic caching and memory management
- Progressive loading with placeholders
- Error handling with fallback icons
- Memory cache height optimization for performance

## Development Notes

### Hero Widget Usage
When working with Hero widgets, ensure unique tags to avoid "multiple heroes that share the same tag" errors. Use descriptive prefixes like:
- `illust_${id}` for illustration images
- `user_avatar_${userId}` for user avatars
- `background_image_${context}_${userId}` for background images

### API Integration
The ApiService handles image URL construction with different quality levels:
- `original`: Full resolution
- `regular`: 1200px master quality
- `small`: 540x540 compressed
- `thumb_mini`: 128x128 thumbnails

### Cross-Platform Considerations
- Download functionality uses conditional exports
- Universal platform detection for platform-specific features
- Responsive layout considerations for different screen sizes