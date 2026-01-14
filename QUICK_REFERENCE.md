# Arclara Token (ARCL) - Quick Reference Guide

## Contract Address
**Mainnet:** `[TO BE DEPLOYED]`  
**Testnet:** `[TO BE DEPLOYED]`

---

## Token Information
| Property | Value |
|----------|-------|
| Name | Arclara |
| Symbol | ARCL |
| Decimals | 18 |
| Total Supply | 1,000,000,000 (1 Billion) |
| Supply Type | Fixed (No Minting) |
| Solidity Version | ^0.8.20 |
| OpenZeppelin | 5.x |

---

## Default Configuration

### Fees (in Basis Points)
| Fee Type | Default | Percentage | Applies To |
|----------|---------|------------|------------|
| Burn Fee | 100 BPS | 1% | All transfers |
| Treasury Fee | 200 BPS | 2% | Buys/Sells only |

### Limits (in Basis Points)
| Limit Type | Default | Percentage | Token Amount |
|------------|---------|------------|--------------|
| Max Wallet | 200 BPS | 2% | 20,000,000 ARCL |
| Max Sell | 100 BPS | 1% | 10,000,000 ARCL |

### Bot Protection
| Setting | Default |
|---------|---------|
| Cooldown | 30 seconds |

---

## BPS Conversion Table

| BPS | Percentage | Example (1B Supply) |
|-----|------------|---------------------|
| 1 | 0.01% | 100,000 tokens |
| 10 | 0.1% | 1,000,000 tokens |
| 50 | 0.5% | 5,000,000 tokens |
| 100 | 1% | 10,000,000 tokens |
| 200 | 2% | 20,000,000 tokens |
| 300 | 3% | 30,000,000 tokens |
| 500 | 5% | 50,000,000 tokens |
| 1000 | 10% | 100,000,000 tokens |
| 2500 | 25% | 250,000,000 tokens |
| 5000 | 50% | 500,000,000 tokens |
| 10000 | 100% | 1,000,000,000 tokens |

**Formula:** `BPS = Percentage × 100`

---

## Owner Functions Cheat Sheet

### Update Fees
```solidity
setFeesInBps(uint256 burnBps, uint256 treasuryBps)
```
**Examples:**
- `setFeesInBps(100, 200)` → 1% burn, 2% treasury
- `setFeesInBps(50, 300)` → 0.5% burn, 3% treasury
- `setFeesInBps(0, 0)` → Disable all fees

### Update Limits
```solidity
setLimitsInBps(uint256 maxWalletBps, uint256 maxSellBps)
```
**Examples:**
- `setLimitsInBps(200, 100)` → 2% max wallet, 1% max sell
- `setLimitsInBps(500, 200)` → 5% max wallet, 2% max sell
- `setLimitsInBps(10000, 10000)` → Remove all limits

### Update Cooldown
```solidity
setCooldown(uint256 cooldownSeconds)
```
**Examples:**
- `setCooldown(30)` → 30 second cooldown
- `setCooldown(60)` → 1 minute cooldown
- `setCooldown(0)` → Disable cooldown

### Update Treasury Wallet
```solidity
setTreasuryWallet(address wallet)
```
**Example:**
- `setTreasuryWallet(0x1234...5678)` → Set new treasury

### Manage AMM Pairs
```solidity
setAutomatedMarketMakerPair(address pair, bool value)
```
**Examples:**
- `setAutomatedMarketMakerPair(0xPairAddress, true)` → Add pair
- `setAutomatedMarketMakerPair(0xPairAddress, false)` → Remove pair

### Manage Exemptions
```solidity
setExempt(address account, bool value)
```
**Examples:**
- `setExempt(0xRouterAddress, true)` → Exempt router
- `setExempt(0xExchangeWallet, true)` → Exempt exchange
- `setExempt(0xAddress, false)` → Remove exemption

---

## View Functions Cheat Sheet

### Get Max Wallet (in tokens)
```solidity
maxWalletAmount() → uint256
```
Returns absolute token amount (with 18 decimals)

### Get Max Sell (in tokens)
```solidity
maxSellAmount() → uint256
```
Returns absolute token amount (with 18 decimals)

### Check Cooldown
```solidity
remainingCooldown(address account) → uint256
```
Returns seconds remaining (0 if no cooldown)

### Check Configuration
```solidity
burnBps() → uint256
treasuryBps() → uint256
maxWalletBps() → uint256
maxSellBps() → uint256
cooldownSeconds() → uint256
treasuryWallet() → address
automatedMarketMakerPairs(address) → bool
isExempt(address) → bool
```

---

## Common Scenarios

### Launch Configuration (Strict)
```solidity
// High protection for launch
setFeesInBps(100, 300);      // 1% burn, 3% treasury
setLimitsInBps(100, 50);     // 1% max wallet, 0.5% max sell
setCooldown(60);             // 1 minute cooldown
```

### Post-Launch (Moderate)
```solidity
// Balanced settings after initial phase
setFeesInBps(100, 200);      // 1% burn, 2% treasury
setLimitsInBps(200, 100);    // 2% max wallet, 1% max sell
setCooldown(30);             // 30 second cooldown
```

### Mature Project (Relaxed)
```solidity
// Lighter restrictions for established token
setFeesInBps(50, 200);       // 0.5% burn, 2% treasury
setLimitsInBps(500, 200);    // 5% max wallet, 2% max sell
setCooldown(10);             // 10 second cooldown
```

### Emergency Disable
```solidity
// Remove all restrictions (use with caution)
setFeesInBps(0, 0);          // No fees
setLimitsInBps(10000, 10000); // No limits
setCooldown(0);              // No cooldown
```

---

## Fee Calculation Examples

### Regular Transfer (Wallet to Wallet)
**Amount:** 100,000 ARCL  
**Fees Applied:**
- Burn: 1% = 1,000 ARCL → Sent to dead address
- Treasury: 0% (not a buy/sell)

**Recipient Receives:** 99,000 ARCL

### Buy Transaction (AMM Pair to Wallet)
**Amount:** 100,000 ARCL  
**Fees Applied:**
- Burn: 1% = 1,000 ARCL → Sent to dead address
- Treasury: 2% = 2,000 ARCL → Sent to treasury

**Recipient Receives:** 97,000 ARCL

### Sell Transaction (Wallet to AMM Pair)
**Amount:** 100,000 ARCL  
**Fees Applied:**
- Burn: 1% = 1,000 ARCL → Sent to dead address
- Treasury: 2% = 2,000 ARCL → Sent to treasury

**Pair Receives:** 97,000 ARCL

---

## Default Exemptions

The following addresses are exempt by default at deployment:

1. **Contract Owner** (deployer)
2. **Contract Itself** (token contract address)
3. **Treasury Wallet** (specified in constructor)
4. **Dead Address** (`0x000000000000000000000000000000000000dEaD`)

Exempt addresses bypass:
- ✅ Burn fees
- ✅ Treasury fees
- ✅ Max wallet limits
- ✅ Max sell limits
- ✅ Cooldown timers

---

## Events Reference

```solidity
event FeesUpdated(uint256 burnBps, uint256 treasuryBps);
event LimitsUpdated(uint256 maxWalletBps, uint256 maxSellBps);
event CooldownUpdated(uint256 cooldownSeconds);
event TreasuryWalletUpdated(address indexed wallet);
event ExemptionUpdated(address indexed account, bool isExempt);
event AutomatedMarketMakerPairSet(address indexed pair, bool value);
```

---

## Error Messages

```solidity
error InvalidBps();                    // BPS value exceeds 10000
error ZeroAddress();                   // Address cannot be zero
error ExceedsMaxWallet();              // Recipient would exceed max wallet
error ExceedsMaxSell();                // Sell amount exceeds max sell
error CooldownActive(uint256 seconds); // Cooldown period still active
```

---

## Deployment Checklist

- [ ] Prepare secure treasury wallet address
- [ ] Deploy contract with treasury address
- [ ] Verify contract on block explorer
- [ ] Create liquidity pool on DEX
- [ ] Get AMM pair address
- [ ] Call `setAutomatedMarketMakerPair(pairAddress, true)`
- [ ] Exempt DEX router if needed: `setExempt(routerAddress, true)`
- [ ] Configure fees if different from defaults
- [ ] Configure limits if different from defaults
- [ ] Configure cooldown if different from default
- [ ] Test buy transaction
- [ ] Test sell transaction
- [ ] Test regular transfer
- [ ] Monitor events and transactions
- [ ] Consider transferring ownership to multisig

---

## Important Addresses

### Dead Address (Burn)
```
0x000000000000000000000000000000000000dEaD
```

### Common DEX Routers

**Ethereum Mainnet:**
- Uniswap V2: `0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D`
- Uniswap V3: `0xE592427A0AEce92De3Edee1F18E0157C05861564`
- SushiSwap: `0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F`

**BSC Mainnet:**
- PancakeSwap V2: `0x10ED43C718714eb63d5aA57B78B54704E256024E`
- PancakeSwap V3: `0x13f4EA83D0bd40E75C8222255bc855a974568Dd4`

**Polygon:**
- QuickSwap: `0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff`
- Uniswap V3: `0xE592427A0AEce92De3Edee1F18E0157C05861564`

---

## Gas Optimization Tips

1. **Batch Operations:** If setting multiple configurations, do them in one transaction
2. **Exemptions:** Exempt addresses that will trade frequently to save gas
3. **Disable Unused Features:** If you don't need cooldown, set it to 0
4. **AMM Pairs:** Only add pairs that are actively used

---

## Security Best Practices

1. **Multisig Ownership:** Transfer ownership to a multisig wallet
2. **Timelock:** Consider adding a timelock for parameter changes
3. **Audit:** Get professional audit before mainnet deployment
4. **Testnet:** Thoroughly test on testnet first
5. **Treasury Security:** Use a secure, preferably multisig treasury wallet
6. **Gradual Changes:** Make parameter changes gradually, not drastically
7. **Communication:** Announce parameter changes to community beforehand

---

## Support & Resources

- **Contract File:** `contracts/ArclaraToken.sol`
- **Full Documentation:** `CONTRACT_DOCUMENTATION.md`
- **README:** `README.md`
- **OpenZeppelin Docs:** https://docs.openzeppelin.com/contracts/5.x/
- **Solidity Docs:** https://docs.soliditylang.org/

---

**Last Updated:** January 14, 2026  
**Version:** 1.0
