# Vantage PD

A dice roller app for the Playdate console that supports various dice types and features.

## Features

- **Dice Types:**
  - Coin (Heads/Tails)
  - d4 (Triangle)
  - d6 (Square)
  - d8 (Octagon)
  - d10 (Pentagon)
  - d12 (Hexagon)
  - d20 (Decagon)
  - d100 (50-sided polygon)

- **Core Features:**
  - Visual representation of each die type using geometric shapes
  - Random number generation using uptime and accelerometer data
  - Sound effects for rolling and flipping with random playback rate variation
  - Advantage/Disadvantage mode for all dice except coin
  - Clean, modern UI with Roobert fonts
  - Configurable per-dice size and spacing
  - Robust error handling and nil checks

- **Controls:**
  - A: Roll/Flip
  - Left/Right: Change dice type
  - Up: Toggle advantage mode
  - Down: Toggle disadvantage mode

- **UI Elements:**
  - Dice type indicator at top
  - Result display in center
  - Button prompts at bottom
  - Exclamation mark indicator for advantage/disadvantage mode
  - Dual result display when advantage/disadvantage is active

## Recent Updates

- Added comprehensive nil checks and error handling
- Improved variable initialization and scope management
- Centralized configuration for easy customization
- Added per-dice size and spacing configuration
- Enhanced shape drawing with proper error handling
- Improved font loading and error recovery
- Optimized sound effect loading and playback
- Added early returns for missing resources

## Configuration

The app's main configuration is centralized at the top of `main.lua` for easy customization:

- **Dice Visuals:** Configure size and spacing for each die type
- **Sound Effects:** Adjust playback rate variation and file paths
- **Animation:** Customize roll/flip animation durations
- **Fonts:** Set font paths and sizes
- **UI Text:** Customize button prompts and messages

## Development

This project is built using the Playdate SDK and Lua programming language. The app is designed to be simple yet feature-rich, providing a satisfying dice rolling experience on the Playdate console.

### Code Organization

- **Configuration:** All configurable values are at the top of `main.lua`
- **Error Handling:** Comprehensive nil checks and error recovery
- **Resource Management:** Proper loading and error handling for fonts and sounds
- **Performance:** Optimized drawing and update functions

## License

This project is licensed under the MIT License - see the LICENSE file for details.
