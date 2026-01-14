// Hardhat Deployment Script for Arclara Token (ARCL)
// Usage: npx hardhat run scripts/deploy-hardhat.js --network <network-name>

const hre = require("hardhat");

async function main() {
  console.log("\n=== Arclara Token Deployment ===");
  console.log("Network:", hre.network.name);
  
  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer address:", deployer.address);
  
  // Check deployer balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Deployer balance:", hre.ethers.formatEther(balance), "ETH");
  
  // ========================================
  // CONFIGURATION - UPDATE THESE VALUES
  // ========================================
  
  // Treasury wallet address - MUST BE SET!
  const TREASURY_WALLET = "0xYourTreasuryWalletAddressHere";
  
  // Validate treasury address
  if (TREASURY_WALLET === "0xYourTreasuryWalletAddressHere" || !hre.ethers.isAddress(TREASURY_WALLET)) {
    throw new Error("Please set a valid TREASURY_WALLET address in the deployment script!");
  }
  
  console.log("\nDeployment Configuration:");
  console.log("Treasury Wallet:", TREASURY_WALLET);
  
  // ========================================
  // DEPLOY CONTRACT
  // ========================================
  
  console.log("\nDeploying ArclaraToken...");
  
  const ArclaraToken = await hre.ethers.getContractFactory("ArclaraToken");
  const token = await ArclaraToken.deploy(TREASURY_WALLET);
  
  await token.waitForDeployment();
  
  const tokenAddress = await token.getAddress();
  console.log("\n✅ ArclaraToken deployed to:", tokenAddress);
  
  // ========================================
  // VERIFY DEPLOYMENT
  // ========================================
  
  console.log("\nVerifying deployment...");
  
  const name = await token.name();
  const symbol = await token.symbol();
  const decimals = await token.decimals();
  const totalSupply = await token.totalSupply();
  const ownerBalance = await token.balanceOf(deployer.address);
  
  console.log("Token Name:", name);
  console.log("Token Symbol:", symbol);
  console.log("Decimals:", decimals.toString());
  console.log("Total Supply:", hre.ethers.formatEther(totalSupply), "ARCL");
  console.log("Owner Balance:", hre.ethers.formatEther(ownerBalance), "ARCL");
  
  // Check configuration
  const burnBps = await token.burnBps();
  const treasuryBps = await token.treasuryBps();
  const maxWalletBps = await token.maxWalletBps();
  const maxSellBps = await token.maxSellBps();
  const cooldownSeconds = await token.cooldownSeconds();
  const treasuryWallet = await token.treasuryWallet();
  
  console.log("\nDefault Configuration:");
  console.log("Burn Fee:", burnBps.toString(), "BPS (" + (Number(burnBps) / 100) + "%)" );
  console.log("Treasury Fee:", treasuryBps.toString(), "BPS (" + (Number(treasuryBps) / 100) + "%)" );
  console.log("Max Wallet:", maxWalletBps.toString(), "BPS (" + (Number(maxWalletBps) / 100) + "%)" );
  console.log("Max Sell:", maxSellBps.toString(), "BPS (" + (Number(maxSellBps) / 100) + "%)" );
  console.log("Cooldown:", cooldownSeconds.toString(), "seconds");
  console.log("Treasury Wallet:", treasuryWallet);
  
  // Check exemptions
  const ownerExempt = await token.isExempt(deployer.address);
  const contractExempt = await token.isExempt(tokenAddress);
  const treasuryExempt = await token.isExempt(TREASURY_WALLET);
  
  console.log("\nDefault Exemptions:");
  console.log("Owner Exempt:", ownerExempt);
  console.log("Contract Exempt:", contractExempt);
  console.log("Treasury Exempt:", treasuryExempt);
  
  // ========================================
  // POST-DEPLOYMENT INSTRUCTIONS
  // ========================================
  
  console.log("\n=== Deployment Complete ===");
  console.log("\nNext Steps:");
  console.log("1. Verify contract on block explorer:");
  console.log("   npx hardhat verify --network", hre.network.name, tokenAddress, TREASURY_WALLET);
  console.log("\n2. Create liquidity pool on DEX (e.g., Uniswap)");
  console.log("\n3. Set AMM pair address:");
  console.log("   token.setAutomatedMarketMakerPair(pairAddress, true)");
  console.log("\n4. (Optional) Exempt DEX router:");
  console.log("   token.setExempt(routerAddress, true)");
  console.log("\n5. (Optional) Adjust fees/limits:");
  console.log("   token.setFeesInBps(burnBps, treasuryBps)");
  console.log("   token.setLimitsInBps(maxWalletBps, maxSellBps)");
  console.log("   token.setCooldown(seconds)");
  
  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    deployer: deployer.address,
    tokenAddress: tokenAddress,
    treasuryWallet: TREASURY_WALLET,
    deploymentTime: new Date().toISOString(),
    configuration: {
      burnBps: burnBps.toString(),
      treasuryBps: treasuryBps.toString(),
      maxWalletBps: maxWalletBps.toString(),
      maxSellBps: maxSellBps.toString(),
      cooldownSeconds: cooldownSeconds.toString()
    }
  };
  
  console.log("\nDeployment Info:");
  console.log(JSON.stringify(deploymentInfo, null, 2));
  
  // Optionally save to file
  const fs = require('fs');
  const deploymentPath = `./deployments/${hre.network.name}-deployment.json`;
  
  try {
    if (!fs.existsSync('./deployments')) {
      fs.mkdirSync('./deployments');
    }
    fs.writeFileSync(deploymentPath, JSON.stringify(deploymentInfo, null, 2));
    console.log("\n✅ Deployment info saved to:", deploymentPath);
  } catch (error) {
    console.log("\n⚠️  Could not save deployment info:", error.message);
  }
}

// Execute deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Deployment failed:", error);
    process.exit(1);
  });
