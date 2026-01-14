// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ArclaraToken} from "../contracts/ArclaraToken.sol";

/**
 * Foundry Deployment Script for Arclara Token (ARCL)
 * 
 * Usage:
 * 1. Set environment variables:
 *    export PRIVATE_KEY=your_private_key
 *    export RPC_URL=your_rpc_url
 *    export TREASURY_WALLET=your_treasury_address
 * 
 * 2. Deploy:
 *    forge script scripts/deploy-foundry.s.sol:DeployArclaraToken --rpc-url $RPC_URL --broadcast --verify
 * 
 * Or deploy directly with constructor args:
 *    forge create src/ArclaraToken.sol:ArclaraToken \
 *      --rpc-url $RPC_URL \
 *      --private-key $PRIVATE_KEY \
 *      --constructor-args $TREASURY_WALLET
 */
contract DeployArclaraToken is Script {
    
    function run() external {
        // Get treasury wallet from environment variable
        address treasuryWallet = vm.envAddress("TREASURY_WALLET");
        
        console.log("\n=== Arclara Token Deployment ===");
        console.log("Deployer:", msg.sender);
        console.log("Treasury Wallet:", treasuryWallet);
        
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy the token
        ArclaraToken token = new ArclaraToken(treasuryWallet);
        
        console.log("\n✅ ArclaraToken deployed to:", address(token));
        
        // Verify deployment
        console.log("\nToken Information:");
        console.log("Name:", token.name());
        console.log("Symbol:", token.symbol());
        console.log("Decimals:", token.decimals());
        console.log("Total Supply:", token.totalSupply() / 1e18, "ARCL");
        
        console.log("\nDefault Configuration:");
        console.log("Burn Fee:", token.burnBps(), "BPS");
        console.log("Treasury Fee:", token.treasuryBps(), "BPS");
        console.log("Max Wallet:", token.maxWalletBps(), "BPS");
        console.log("Max Sell:", token.maxSellBps(), "BPS");
        console.log("Cooldown:", token.cooldownSeconds(), "seconds");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("\nNext Steps:");
        console.log("1. Create liquidity pool on DEX");
        console.log("2. Set AMM pair: token.setAutomatedMarketMakerPair(pairAddress, true)");
        console.log("3. (Optional) Exempt router: token.setExempt(routerAddress, true)");
    }
}
