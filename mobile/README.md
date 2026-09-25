# React Native Mobile App

React Native mobile application with TypeScript for the shopping cart app.

## Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Configure API URL** (if needed):
   - For physical devices, update `API_BASE_URL` in `src/services/api.ts` to use your computer's local IP address instead of `localhost`

3. **iOS Setup**:
   ```bash
   cd ios
   bundle install
   bundle exec pod install
   cd ..
   npx react-native run-ios
   ```

4. **Android Setup**:
   ```bash
   npx react-native run-android
   ```

## Project Structure

```
src/
├── screens/          # App screens
│   ├── LoginScreen.tsx
│   ├── ProductListScreen.tsx
│   ├── ProductDetailScreen.tsx
│   ├── CartScreen.tsx
│   └── OrderHistoryScreen.tsx
├── components/       # Reusable components
│   ├── Button.tsx
│   ├── ProductCard.tsx
│   └── CartItem.tsx
├── services/         # API and authentication
│   ├── api.ts
│   └── auth.ts
├── context/          # React contexts
│   ├── AuthContext.tsx
│   └── CartContext.tsx
└── types/            # TypeScript types
    └── index.ts
```

## API Configuration

The API URL is configured in `src/services/api.ts`. By default, it uses `http://localhost:3000/api` which works for iOS simulator and Android emulator.

**For physical devices**, update the `API_BASE_URL` constant in `src/services/api.ts` to use your computer's local IP address:
```typescript
const API_BASE_URL = 'http://192.168.1.100:3000/api';
```

To find your local IP:
- **macOS/Linux**: `ifconfig | grep "inet "`
- **Windows**: `ipconfig`

## Running the App

### Development

```bash
# Start Metro bundler
npm start

# Run on iOS (in another terminal)
npm run ios

# Run on Android (in another terminal)
npm run android
```

### Building for Production

**iOS**:
```bash
cd ios
xcodebuild -workspace MobileApp.xcworkspace -scheme MobileApp -configuration Release
```

**Android**:
```bash
cd android
./gradlew assembleRelease
```

## Dependencies

- `@react-navigation/native` - Navigation
- `@react-navigation/stack` - Stack navigator
- `axios` - HTTP client
- `@react-native-async-storage/async-storage` - Local storage

## Features

- **Authentication**: Login/signup with JWT tokens
- **Product Browsing**: View all products and details
- **Shopping Cart**: Add, update, and remove items
- **Order Management**: Place orders and view history
- **State Management**: React Context for auth and cart
- **Type Safety**: Full TypeScript support

## Troubleshooting

### Metro Bundler Issues

```bash
# Clear cache and restart
npm start -- --reset-cache
```

### iOS Build Issues

```bash
cd ios
rm -rf Pods Podfile.lock
bundle exec pod install
cd ..
```

### Android Build Issues

```bash
cd android
./gradlew clean
cd ..
```

### Network Connection Issues

- Ensure backend is running
- Check API URL in `src/services/api.ts`
- For physical devices, use local IP instead of `localhost`
- Verify firewall settings allow connections

### TypeScript Errors

```bash
# Check for type errors
npx tsc --noEmit
```

## Development Tips

1. **Hot Reload**: Enabled by default in development
2. **Debugging**: Use React Native Debugger or Chrome DevTools
3. **Logging**: Use `console.log` (visible in Metro bundler)
4. **Error Boundaries**: Consider adding error boundaries for production
