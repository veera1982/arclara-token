# Arclara Token (ARCL) - Smart Contract Documentation

## Overview
Production-ready ERC-20 token smart contract built with OpenZeppelin 5.x standards for Solidity ^0.8.20.

**Token Details:**
- **Name:** Arclara
- **Symbol:** ARCL
- **Total Supply:** 1,000,000,000 (1 Billion) - Fixed Supply
- **Decimals:** 18 (standard)

---

## Core Features

### 1. Deflationary Burn Mechanism
- **Default Rate:** 1% (100 BPS)
- **Behavior:** Automatically burns a percentage of every transfer by sending it to the dead address (`0x000000000000000000000000000000000000dEaD`)
- **Effect:** Reduces circulating supply with each transaction, creating deflationary pressure
- **Applies To:** All non-exempt transfers (including regular transfers, buys, and sells)

### 2. Treasury Tax (Auto-Liquidity)
- **Default Rate:** 2% (200 BPS)
- **Behavior:** Collects a percentage on buy/sell transactions only (when interacting with AMM pairs)
- **Destination:** Sent to the designated treasury wallet
- **Use Cases:** Marketing, development, token buybacks, liquidity provision
- **Applies To:** Only buy/sell transactions through AMM pairs (e.g., Uniswap, PancakeSwap)

### 3. Anti-Whale Protection
Two-tier protection system:

**a) Max Wallet Holding:**
- **Default:** 2% of total supply (20,000,000 ARCL)
- **Purpose:** Prevents any single wallet from accumulating too much supply
- **Enforcement:** Checked after each transfer to the recipient

**b) Max Sell Per Transaction:**
- **Default:** 1% of total supply (10,000,000 ARCL)
- **Purpose:** Prevents large dumps that could crash the price
- **Enforcement:** Checked on sell transactions only

### 4. Bot Protection (Cooldown Timer)
- **Default:** 30 seconds
- **Behavior:** Enforces a waiting period between transfers for the same wallet
- **Purpose:** Prevents sniper bots and rapid trading at launch
- **Applies To:** Both sender and receiver (except AMM pairs)
- **Error:** Reverts with `CooldownActive(remainingSeconds)` if triggered

### 5. Exemption System
- **Purpose:** Allows specific addresses to bypass all fees, limits, and cooldowns
- **Default Exemptions:**
  - Contract owner (deployer)
  - Contract itself
  - Treasury wallet
  - Dead address (burn address)
- **Use Cases:** Exchange wallets, DEX routers, bridges, team wallets

---

## Configuration Functions (Owner Only)

### Updating Fee Rates
```solidity
function setFeesInBps(uint256 _burnBps, uint256 _treasuryBps) external onlyOwner
```
**Parameters:**
- `_burnBps`: Burn fee in basis points (0-10000, where 10000 = 100%)
- `_treasuryBps`: Treasury fee in basis points (0-10000)

**Examples:**
- Set burn to 0.5%: `setFeesInBps(50, 200)` (50 BPS = 0.5%)
- Set treasury to 3%: `setFeesInBps(100, 300)` (300 BPS = 3%)
- Disable burn: `setFeesInBps(0, 200)`
- Disable both: `setFeesInBps(0, 0)`

### Updating Limits
```solidity
function setLimitsInBps(uint256 _maxWalletBps, uint256 _maxSellBps) external onlyOwner
```
**Parameters:**
- `_maxWalletBps`: Max wallet holding in BPS of total supply
- `_maxSellBps`: Max sell amount in BPS of total supply

**Examples:**
- Increase max wallet to 5%: `setLimitsInBps(500, 100)` (500 BPS = 5%)
- Increase max sell to 2%: `setLimitsInBps(200, 200)` (200 BPS = 2%)
- Remove limits: `setLimitsInBps(10000, 10000)` (100% = no limit)

### Updating Cooldown
```solidity
function setCooldown(uint256 _cooldownSeconds) external onlyOwner
```
**Parameters:**
- `_cooldownSeconds`: Cooldown period in seconds

**Examples:**
- Set to 1 minute: `setCooldown(60)`
- Set to 5 minutes: `setCooldown(300)`
- Disable cooldown: `setCooldown(0)`

### Updating Treasury Wallet
```solidity
function setTreasuryWallet(address _wallet) external onlyOwner
```
**Parameters:**
- `_wallet`: New treasury wallet address (cannot be zero address)

**Example:**
```solidity
setTreasuryWallet(0x1234567890123456789012345678901234567890)
```

### Managing AMM Pairs
```solidity
function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner
```
**Parameters:**
- `pair`: Address of the AMM pair (e.g., Uniswap V2 pair)
- `value`: `true` to mark as AMM pair, `false` to remove

**Examples:**
- Add Uniswap pair: `setAutomatedMarketMakerPair(0xPairAddress, true)`
- Remove pair: `setAutomatedMarketMakerPair(0xPairAddress, false)`

**Important:** You must set AMM pairs for the treasury tax to apply on buys/sells!

### Managing Exemptions
```solidity
function setExempt(address account, bool value) external onlyOwner
```
**Parameters:**
- `account`: Address to exempt or unexempt
- `value`: `true` to exempt, `false` to remove exemption

**Examples:**
- Exempt exchange wallet: `setExempt(0xExchangeWallet, true)`
- Exempt DEX router: `setExempt(0xRouterAddress, true)`
- Remove exemption: `setExempt(0xAddress, false)`

---

## Public View Functions

### Get Max Wallet Amount (in tokens)
```solidity
function maxWalletAmount() public view returns (uint256)
```
Returns the maximum number of tokens a wallet can hold (absolute value).

**Example:** With 2% limit and 1B supply, returns `20000000000000000000000000` (20M tokens with 18 decimals)

### Get Max Sell Amount (in tokens)
```solidity
function maxSellAmount() public view returns (uint256)
```
Returns the maximum number of tokens that can be sold in one transaction.

**Example:** With 1% limit and 1B supply, returns `10000000000000000000000000` (10M tokens with 18 decimals)

### Check Remaining Cooldown
```solidity
function remainingCooldown(address account) public view returns (uint256)
```
Returns the remaining cooldown time in seconds for a specific address.

**Returns:** `0` if no cooldown is active, otherwise the number of seconds remaining.

---

## Deployment Instructions

### Constructor Parameters
```solidity
constructor(address _treasuryWallet)
```

**Required:**
- `_treasuryWallet`: Address that will receive treasury taxes (cannot be zero address)

### Deployment Steps

1. **Prepare Treasury Wallet:**
   - Create or designate a secure wallet for receiving treasury taxes
   - This could be a multisig wallet, team wallet, or marketing wallet

2. **Deploy Contract:**
   ```solidity
   // Example deployment
   ArclaraToken token = new ArclaraToken(0xYourTreasuryWalletAddress);
   ```

3. **Initial Supply:**
   - The entire 1 billion token supply is minted to the deployer (owner)
   - Owner is automatically exempted from all fees and limits

4. **Post-Deployment Configuration:**
   - Set AMM pairs after creating liquidity pools
   - Add exemptions for DEX routers, exchanges, etc.
   - Adjust fees/limits if needed
   - Transfer ownership if required

### Example Deployment Scenario

```solidity
// 1. Deploy with treasury wallet
ArclaraToken token = new ArclaraToken(0xTreasuryAddress);

// 2. Create Uniswap V2 pair and add liquidity
// ... (use Uniswap router to create pair and add liquidity)

// 3. Set the Uniswap pair as AMM
token.setAutomatedMarketMakerPair(0xUniswapPairAddress, true);

// 4. Exempt Uniswap router from fees (optional, for smoother trading)
token.setExempt(0xUniswapV2Router, true);

// 5. Adjust settings if needed
token.setFeesInBps(100, 200); // 1% burn, 2% treasury
token.setLimitsInBps(200, 100); // 2% max wallet, 1% max sell
token.setCooldown(30); // 30 second cooldown
```

---

## Gas Optimization Features

1. **Custom Errors:** Uses custom errors instead of string messages (saves gas)
2. **Basis Points System:** Efficient percentage calculations using BPS
3. **Minimal Storage Reads:** Optimized to reduce SLOAD operations
4. **Efficient Logic Flow:** Early returns and conditional checks minimize unnecessary operations
5. **Packed Variables:** Uses appropriate data types to optimize storage

---

## Security Features

1. **Zero Address Checks:** Prevents setting critical addresses to zero
2. **BPS Validation:** Ensures fee rates cannot exceed 100%
3. **Ownable Access Control:** Only owner can modify critical parameters
4. **Reentrancy Protection:** Inherits OpenZeppelin's secure ERC20 implementation
5. **Fixed Supply:** No minting function - supply is permanently capped at 1 billion
6. **Overflow Protection:** Solidity 0.8.20 has built-in overflow/underflow checks

---

## Events

The contract emits events for all configuration changes:

```solidity
event FeesUpdated(uint256 burnBps, uint256 treasuryBps);
event LimitsUpdated(uint256 maxWalletBps, uint256 maxSellBps);
event CooldownUpdated(uint256 cooldownSeconds);
event TreasuryWalletUpdated(address indexed wallet);
event ExemptionUpdated(address indexed account, bool isExempt);
event AutomatedMarketMakerPairSet(address indexed pair, bool value);
```

These events allow off-chain monitoring and transparency.

---

## Common Use Cases

### Scenario 1: Launch Configuration
```solidity
// Strict settings for launch to prevent bots and whales
setFeesInBps(100, 300);      // 1% burn, 3% treasury
setLimitsInBps(100, 50);     // 1% max wallet, 0.5% max sell
setCooldown(60);             // 1 minute cooldown
```

### Scenario 2: Mature Project
```solidity
// Relaxed settings after successful launch
setFeesInBps(50, 200);       // 0.5% burn, 2% treasury
setLimitsInBps(500, 200);    // 5% max wallet, 2% max sell
setCooldown(10);             // 10 second cooldown
```

### Scenario 3: Disable All Restrictions
```solidity
// Remove all fees and limits (not recommended)
setFeesInBps(0, 0);          // No fees
setLimitsInBps(10000, 10000); // No limits
setCooldown(0);              // No cooldown
```

---

## Important Notes

### Understanding BPS (Basis Points)
- 1 BPS = 0.01%
- 100 BPS = 1%
- 1000 BPS = 10%
- 10000 BPS = 100%

### Fee Stacking
When both burn and treasury fees apply:
- **Regular Transfer:** Only burn fee (1%)
- **Buy Transaction:** Burn fee (1%) + Treasury fee (2%) = 3% total
- **Sell Transaction:** Burn fee (1%) + Treasury fee (2%) = 3% total

### Exemption Behavior
Exempt addresses bypass:
- ✅ Burn fees
- ✅ Treasury fees
- ✅ Max wallet limits
- ✅ Max sell limits
- ✅ Cooldown timers

### AMM Pair Detection
- **Buy:** `from` address is an AMM pair
- **Sell:** `to` address is an AMM pair
- **Regular Transfer:** Neither `from` nor `to` is an AMM pair

---

## Testing Checklist

Before mainnet deployment, test:

- [ ] Token deployment with valid treasury address
- [ ] Initial supply minted to owner
- [ ] Owner exemption works
- [ ] Regular transfers apply burn fee
- [ ] Buy transactions apply both fees
- [ ] Sell transactions apply both fees
- [ ] Max wallet limit enforced
- [ ] Max sell limit enforced
- [ ] Cooldown timer works correctly
- [ ] Exemption system functions properly
- [ ] All owner functions work (setFees, setLimits, etc.)
- [ ] Events are emitted correctly
- [ ] Custom errors revert as expected
- [ ] Gas costs are reasonable

---

## Contract Verification

After deployment, verify the contract on block explorers (Etherscan, BSCScan, etc.) using:
- Compiler version: `0.8.20`
- Optimization: Enabled (200 runs recommended)
- License: MIT
- Constructor arguments: Treasury wallet address

---

## Support & Modifications

### Changing Tax Rates
To modify burn or treasury rates after deployment, call `setFeesInBps()` with new values in basis points.

### Changing Limits
To modify wallet or sell limits after deployment, call `setLimitsInBps()` with new values in basis points.

### Adding New AMM Pairs
When listing on new exchanges, call `setAutomatedMarketMakerPair()` for each new pair address.

### Emergency Measures
If needed, the owner can:
- Set all fees to 0
- Set all limits to 10000 (100% = no limit)
- Set cooldown to 0
- Exempt specific addresses

---

## License
MIT License - See contract header for details.

---

## Audit Recommendations

Before mainnet deployment:
1. Conduct professional smart contract audit
2. Test on testnet extensively
3. Verify all calculations (BPS, limits, fees)
4. Test edge cases (zero transfers, max values, etc.)
5. Review ownership transfer procedures
6. Ensure treasury wallet is secure (consider multisig)

---

**Contract Version:** 1.0  
**Solidity Version:** ^0.8.20  
**OpenZeppelin Version:** 5.x  
**Last Updated:** January 14, 2026
