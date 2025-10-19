# 🪦 Hobby Graveyard Smart Contracts

## Overview
This PR introduces two complementary smart contracts that form the core archaeological survey system for abandoned hobbies and dusty starter kits.

## New Contracts

### 1. Enthusiasm Half-Life Calculator (`enthusiasm-half-life-calculator.clar`)
A predictive analytics contract that tracks enthusiasm decay patterns for registered hobbies.

**Key Features:**
- ✨ Track hobby enthusiasm levels over time (1-100 scale)
- 📊 Calculate decay rates based on usage patterns
- 🔮 Predict abandonment probability with risk assessment
- 📈 Generate detailed hobby lifecycle statistics
- 🏷️ Categorize enthusiasm levels (critical-low to obsessive)

**Core Functions:**
- `register-hobby()` - Initialize a new hobby with enthusiasm tracking
- `update-enthusiasm()` - Record enthusiasm changes with notes
- `get-enthusiasm-prediction()` - Get abandonment risk assessment
- `mark-hobby-abandoned()` - Officially retire a hobby
- `get-contract-stats()` - View overall abandonment statistics

### 2. Starter Kit Depreciation Tracker (`starter-kit-depreciation-tracker.clar`)
A valuation system for hobby equipment gathering creative dust in storage locations.

**Key Features:**
- 💰 Track purchase prices and depreciation over time
- 📦 Monitor condition and usage frequency
- 🏠 Score storage location creativity (garage to "custom locations")
- 📉 Calculate resale values and regret levels
- 📋 Generate equipment portfolio summaries

**Core Functions:**
- `add-equipment()` - Register new hobby equipment with location
- `update-condition-and-usage()` - Track wear and usage patterns
- `get-equipment-valuation()` - Get current value and depreciation
- `relocate-storage()` - Update storage location creativity score
- `get-storage-creativity-ranking()` - View creativity leaderboards

## Technical Implementation

### Architecture
- **Clean Design**: No cross-contract calls or complex trait implementations
- **Gas Efficient**: Optimized data structures and minimal computation
- **User-Centric**: All functions are owner-protected for personal hobby tracking
- **Scalable**: Support for 100+ hobbies and 200+ equipment items per user

### Data Management
- Comprehensive maps for hobby and equipment storage
- Historical tracking with timestamped entries
- Statistical aggregation for community insights
- Creative storage location scoring system

### Error Handling
- Comprehensive error codes for all edge cases
- Input validation for enthusiasm levels, prices, and conditions
- Owner verification for all write operations

## Testing & Validation
- Contracts validated with Clarity syntax checker
- 300+ lines of combined implementation
- Handles edge cases for calculations and data management
- Ready for integration testing

## Impact
This system provides both entertainment value and practical functionality for hobby enthusiasts who want to:
- Track their hobby journey scientifically
- Understand equipment depreciation patterns
- Gamify storage organization creativity
- Build community insights around hobby abandonment

The contracts serve as a humorous yet functional tool for the universal experience of accumulating hobby equipment and gradually losing interest over time.

## Files Added
- `contracts/enthusiasm-half-life-calculator.clar` (301 lines)
- `contracts/starter-kit-depreciation-tracker.clar` (386 lines)
- Updated `Clarinet.toml` with new contract configurations
- Test scaffolding files for both contracts

---
*"Where hobbies go to rest in peace, and starter kits gather digital dust."*