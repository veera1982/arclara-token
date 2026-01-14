# Arclara Token (ARCL) - Deployment Guide

This guide walks you through deploying the Arclara Token smart contract to Ethereum mainnet or any EVM-compatible blockchain.

---

## Pre-Deployment Checklist

### 1. Prepare Treasury Wallet
- [ ] Create or designate a secure wallet for receiving treasury taxes
- [ ] Consider using a multisig wallet (e.g., Gnosis Safe) for added security
- [ ] Record the treasury wallet address

### 2. Prepare Deployer Wallet
- [ ] Ensure deployer wallet has sufficient ETH/native tokens for gas
- [ ] Recommended: 0.1-0.5 ETH for Ethereum mainnet
- [ ] Secure the private key (never share or commit to version control)

### 3. Development Environment
- [ ] Install Node.js 18+ or Foundry
- [ ] Install dependencies (OpenZeppelin 5.x)
- [ ] Test contract on testnet first
- [ ] Verify all contract code

### 4. Configuration Decisions
Decide on initial parameters (can be changed later by owner):
- [ ] Burn fee (default: 1% / 100 BPS)
- [ ] Treasury fee (default: 2% / 200 BPS)
- [ ] Max wallet (default: 2% / 200 BPS)
- [ ] Max sell (default: 1% / 100 BPS)
- [ ] Cooldown (default: 30 seconds)

---

## Deployment Methods

### Method 1: Using Hardhat

#### Step 1: Install Dependencies

```bash
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts@^5
npx hardhat
```

#### Step 2: Configure Hardhat

Create `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // Ethereum Mainnet
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 1
    },
    // Sepolia Testnet
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111
    },
    // BSC Mainnet
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 56
    },
    // Polygon Mainnet
    polygon: {
      url: "https://polygon-rpc.com/",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 137
    }
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      bsc: process.env.BSCSCAN_API_KEY,
      polygon: process.env.POLYGONSCAN_API_KEY
    }
  }
};
```

#### Step 3: Create .env File

```bash
# .env
PRIVATE_KEY=your_private_key_here
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
ETHERSCAN_API_KEY=your_etherscan_api_key
BSCSCAN_API_KEY=your_bscscan_api_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

**Important:** Add `.env` to `.gitignore`!

#### Step 4: Update Deployment Script

Edit `scripts/deploy-hardhat.js` and set your treasury wallet address:

```javascript
const TREASURY_WALLET = "0xYourTreasuryWalletAddress";
```

#### Step 5: Compile Contract

```bash
npx hardhat compile
```

#### Step 6: Deploy to Testnet (Recommended First)

```bash
npx hardhat run scripts/deploy-hardhat.js --network sepolia
```

#### Step 7: Deploy to Mainnet

```bash
npx hardhat run scripts/deploy-hardhat.js --network mainnet
```

#### Step 8: Verify Contract

```bash
npx hardhat verify --network mainnet <CONTRACT_ADDRESS> <TREASURY_WALLET>
```

---

### Method 2: Using Foundry

#### Step 1: Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

#### Step 2: Initialize Project

```bash
forge init arclara-token
cd arclara-token
forge install OpenZeppelin/openzeppelin-contracts@v5.0.0
```

#### Step 3: Copy Contract

Copy `ArclaraToken.sol` to `src/` directory.

#### Step 4: Create foundry.toml

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.20"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
sepolia = "${SEPOLIA_RPC_URL}"
bsc = "https://bsc-dataseed.binance.org/"
polygon = "https://polygon-rpc.com/"

[etherscan]
mainnet = { key = "${ETHERSCAN_API_KEY}" }
sepolia = { key = "${ETHERSCAN_API_KEY}" }
bsc = { key = "${BSCSCAN_API_KEY}" }
polygon = { key = "${POLYGONSCAN_API_KEY}" }
```

#### Step 5: Set Environment Variables

```bash
export PRIVATE_KEY=your_private_key
export TREASURY_WALLET=0xYourTreasuryWalletAddress
export MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
export ETHERSCAN_API_KEY=your_etherscan_api_key
```

#### Step 6: Build Contract

```bash
forge build
```

#### Step 7: Deploy to Testnet

```bash
forge create src/ArclaraToken.sol:ArclaraToken \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY \
  --constructor-args $TREASURY_WALLET \
  --verify
```

#### Step 8: Deploy to Mainnet

```bash
forge create src/ArclaraToken.sol:ArclaraToken \
  --rpc-url mainnet \
  --private-key $PRIVATE_KEY \
  --constructor-args $TREASURY_WALLET \
  --verify
```

Or using the deployment script:

```bash
forge script scripts/deploy-foundry.s.sol:DeployArclaraToken \
  --rpc-url mainnet \
  --broadcast \
  --verify
```

---

## Post-Deployment Steps

### 1. Verify Contract on Block Explorer

If not auto-verified during deployment:

**Hardhat:**
```bash
npx hardhat verify --network mainnet <CONTRACT_ADDRESS> <TREASURY_WALLET>
```

**Foundry:**
```bash
forge verify-contract <CONTRACT_ADDRESS> \
  src/ArclaraToken.sol:ArclaraToken \
  --chain-id 1 \
  --constructor-args $(cast abi-encode "constructor(address)" $TREASURY_WALLET)
```

### 2. Create Liquidity Pool

#### Using Uniswap V2

1. Go to [Uniswap Interface](https://app.uniswap.org/)
2. Connect your wallet (deployer wallet with all tokens)
3. Navigate to "Pool" → "Add Liquidity"
4. Select ARCL token (paste contract address)
5. Select pair token (usually ETH or USDC)
6. Enter amounts (e.g., 500M ARCL + 10 ETH)
7. Approve ARCL token
8. Add liquidity
9. **Save the pair address** from the transaction

#### Using Uniswap V3

Similar process but you'll need to set a price range.

### 3. Configure AMM Pair

After creating the liquidity pool, you must set the pair address:

```javascript
// Using ethers.js
const token = await ethers.getContractAt("ArclaraToken", tokenAddress);
await token.setAutomatedMarketMakerPair(pairAddress, true);
```

```bash
# Using cast (Foundry)
cast send $TOKEN_ADDRESS \
  "setAutomatedMarketMakerPair(address,bool)" \
  $PAIR_ADDRESS true \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 4. Exempt DEX Router (Optional)

If you want the DEX router to bypass fees and limits:

```javascript
// Uniswap V2 Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
await token.setExempt("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", true);
```

### 5. Adjust Configuration (Optional)

If you want different settings than defaults:

```javascript
// Set fees (burn: 0.5%, treasury: 3%)
await token.setFeesInBps(50, 300);

// Set limits (max wallet: 3%, max sell: 1.5%)
await token.setLimitsInBps(300, 150);

// Set cooldown (1 minute)
await token.setCooldown(60);
```

### 6. Transfer Ownership to Multisig (Recommended)

For production, transfer ownership to a multisig wallet:

```javascript
// Transfer ownership
await token.transferOwnership(multisigAddress);
```

### 7. Announce Launch

- Update website with contract address
- Post on social media
- Update documentation
- List on token tracking sites (CoinGecko, CoinMarketCap)

---

## Testing on Testnet

Before mainnet deployment, thoroughly test on Sepolia or Goerli:

### Test Scenarios

1. **Basic Transfer**
   - Transfer tokens between wallets
   - Verify 1% burn fee is applied
   - Check balances

2. **Buy Transaction**
   - Buy tokens from DEX
   - Verify 1% burn + 2% treasury fees
   - Check treasury wallet received fees

3. **Sell Transaction**
   - Sell tokens to DEX
   - Verify fees applied
   - Test max sell limit

4. **Anti-Whale Limits**
   - Try to exceed max wallet
   - Try to sell more than max sell
   - Verify transactions revert

5. **Cooldown**
   - Make a transfer
   - Try immediate second transfer
   - Verify cooldown error
   - Wait 30 seconds and retry

6. **Exemptions**
   - Exempt an address
   - Verify no fees/limits apply
   - Remove exemption
   - Verify fees/limits apply again

7. **Configuration Changes**
   - Change fees
   - Change limits
   - Change cooldown
   - Verify new settings work

---

## Gas Estimates

### Deployment Costs (Ethereum Mainnet)

| Gas Price | Estimated Cost |
|-----------|----------------|
| 20 gwei | ~0.05 ETH |
| 50 gwei | ~0.12 ETH |
| 100 gwei | ~0.25 ETH |

### Transaction Costs

| Action | Gas Used | Cost @ 50 gwei |
|--------|----------|----------------|
| Regular Transfer | ~80,000 | ~0.004 ETH |
| Buy (with fees) | ~120,000 | ~0.006 ETH |
| Sell (with fees) | ~130,000 | ~0.0065 ETH |
| Set AMM Pair | ~45,000 | ~0.00225 ETH |
| Set Exemption | ~45,000 | ~0.00225 ETH |
| Update Fees | ~30,000 | ~0.0015 ETH |

---

## Troubleshooting

### Deployment Fails

**Error: Insufficient funds**
- Solution: Add more ETH to deployer wallet

**Error: Invalid treasury address**
- Solution: Ensure treasury address is valid and not zero address

**Error: Compilation failed**
- Solution: Check Solidity version (0.8.20) and OpenZeppelin version (5.x)

### Post-Deployment Issues

**Treasury fees not being collected**
- Solution: Ensure AMM pair is set using `setAutomatedMarketMakerPair()`

**Transactions reverting with "ExceedsMaxWallet"**
- Solution: Either exempt the address or increase max wallet limit

**Transactions reverting with "CooldownActive"**
- Solution: Wait for cooldown period or exempt the address

**Can't verify contract**
- Solution: Ensure constructor arguments match deployment
- Use `--constructor-args` flag with correct treasury address

---

## Security Recommendations

### Before Mainnet Deployment

1. **Professional Audit**
   - Hire reputable audit firm (CertiK, OpenZeppelin, etc.)
   - Address all findings
   - Publish audit report

2. **Bug Bounty**
   - Consider launching bug bounty program
   - Use platforms like Immunefi

3. **Testnet Testing**
   - Test for at least 1-2 weeks on testnet
   - Simulate all scenarios
   - Test edge cases

### After Deployment

1. **Multisig Ownership**
   - Transfer to 3/5 or 4/7 multisig
   - Use Gnosis Safe

2. **Timelock**
   - Consider adding timelock for parameter changes
   - Gives community time to react

3. **Monitoring**
   - Set up alerts for large transactions
   - Monitor treasury wallet
   - Track burn rate

4. **Communication**
   - Announce all parameter changes in advance
   - Maintain transparency
   - Regular updates to community

---

## Network-Specific Guides

### Ethereum Mainnet

**RPC Providers:**
- Alchemy: https://www.alchemy.com/
- Infura: https://infura.io/
- QuickNode: https://www.quicknode.com/

**Block Explorer:** https://etherscan.io/

**DEX:** Uniswap V2/V3

### BSC (Binance Smart Chain)

**RPC:** https://bsc-dataseed.binance.org/

**Block Explorer:** https://bscscan.com/

**DEX:** PancakeSwap V2/V3

### Polygon

**RPC:** https://polygon-rpc.com/

**Block Explorer:** https://polygonscan.com/

**DEX:** QuickSwap, Uniswap V3

---

## Checklist Summary

### Pre-Deployment
- [ ] Treasury wallet prepared
- [ ] Deployer wallet funded
- [ ] Contract tested on testnet
- [ ] Configuration decided
- [ ] RPC provider set up
- [ ] Block explorer API key obtained

### Deployment
- [ ] Contract deployed
- [ ] Contract verified on explorer
- [ ] Deployment info saved

### Post-Deployment
- [ ] Liquidity pool created
- [ ] AMM pair address set
- [ ] DEX router exempted (if needed)
- [ ] Configuration adjusted (if needed)
- [ ] Ownership transferred to multisig
- [ ] Launch announced

### Ongoing
- [ ] Monitor transactions
- [ ] Track treasury balance
- [ ] Respond to community
- [ ] Plan parameter adjustments

---

## Support

For issues or questions:
- Review contract documentation
- Check troubleshooting section
- Test on testnet first
- Consult with blockchain developers

---

**Last Updated:** January 14, 2026  
**Version:** 1.0
