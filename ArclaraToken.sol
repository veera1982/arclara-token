// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
  Arclara (ARCL)

  Production-ready ERC20 with:
  - Deflationary burn (1% of every transfer)
  - Treasury tax on buys/sells (2% to treasury wallet)
  - Anti-whale (max wallet and max sell)
  - Bot protection cooldown per wallet
  - Exemption system (fees/limits/cooldown)

  All rates are expressed in basis points (BPS): 10000 = 100%.
  Solidity ^0.8.20 with OpenZeppelin 5.x.
*/

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ArclaraToken is ERC20, Ownable {
    // ============ Constants & Types ============

    // BPS denominator: 10000 = 100%
    uint256 public constant BPS_DENOMINATOR = 10_000;

    // Dead address used for deflationary burn
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // ============ Configuration (mutable, owner-controlled) ============

    // Deflationary burn applied on EVERY non-exempt transfer
    // Default 1% = 100 BPS
    uint256 public burnBps = 100; // 1%

    // Treasury tax applied ONLY on buys and sells (AMM pair interactions)
    // Default 2% = 200 BPS
    uint256 public treasuryBps = 200; // 2%

    // Max wallet limit: 2% of total supply by default
    uint256 public maxWalletBps = 200; // 2%

    // Max sell limit per transaction: 1% of total supply by default
    uint256 public maxSellBps = 100; // 1%

    // Cooldown between transfers per wallet (in seconds)
    // Default 30 seconds
    uint256 public cooldownSeconds = 30;

    // Treasury wallet (receives treasury tax on buys/sells)
    address public treasuryWallet;

    // Automated Market Maker (AMM) pairs mapping (e.g., Uniswap pair)
    mapping(address => bool) public automatedMarketMakerPairs;

    // Addresses excluded from fees, limits, and cooldown (global exemption)
    mapping(address => bool) public isExempt;

    // Last transfer timestamp used for cooldown tracking
    mapping(address => uint256) public lastTransferTimestamp;

    // ============ Events ============

    event FeesUpdated(uint256 burnBps, uint256 treasuryBps);
    event LimitsUpdated(uint256 maxWalletBps, uint256 maxSellBps);
    event CooldownUpdated(uint256 cooldownSeconds);
    event TreasuryWalletUpdated(address indexed wallet);
    event ExemptionUpdated(address indexed account, bool isExempt);
    event AutomatedMarketMakerPairSet(address indexed pair, bool value);

    // ============ Errors (gas efficient) ============

    error InvalidBps();
    error ZeroAddress();
    error ExceedsMaxWallet();
    error ExceedsMaxSell();
    error CooldownActive(uint256 remainingSeconds);

    // ============ Constructor ============

    /*
      Name: Arclara
      Symbol: ARCL
      Total supply: 1,000,000,000 (1B) tokens with 18 decimals
      Initial supply is minted to the deployer (owner).
    */
    constructor(address _treasuryWallet) ERC20("Arclara", "ARCL") Ownable(msg.sender) {
        if (_treasuryWallet == address(0)) revert ZeroAddress();
        treasuryWallet = _treasuryWallet;

        // Mint fixed supply to owner (1e9 * 1e18)
        _mint(msg.sender, 1_000_000_000 ether);

        // Default exemptions: owner, contract itself, treasury, and dead address
        isExempt[msg.sender] = true;
        isExempt[address(this)] = true;
        isExempt[_treasuryWallet] = true;
        isExempt[DEAD] = true;
    }

    // ============ Owner-Only Configuration ============

    /*
      Update the burn and treasury fees in BPS. Use values between 0 and 10000.
      - burnBps applies to all non-exempt transfers
      - treasuryBps applies only on buys/sells (i.e., if either side is an AMM pair)
      To change:
        setFeesInBps(newBurnBps, newTreasuryBps);
    */
    function setFeesInBps(uint256 _burnBps, uint256 _treasuryBps) external onlyOwner {
        if (_burnBps > BPS_DENOMINATOR || _treasuryBps > BPS_DENOMINATOR) revert InvalidBps();
        burnBps = _burnBps;
        treasuryBps = _treasuryBps;
        emit FeesUpdated(_burnBps, _treasuryBps);
    }

    /*
      Update max wallet and max sell limits expressed in BPS of total supply.
      Examples with 1B supply:
        - maxWalletBps = 200 means 20,000,000 ARCL per wallet
        - maxSellBps = 100 means 10,000,000 ARCL per sell transaction
      To change:
        setLimitsInBps(newMaxWalletBps, newMaxSellBps);
    */
    function setLimitsInBps(uint256 _maxWalletBps, uint256 _maxSellBps) external onlyOwner {
        if (_maxWalletBps > BPS_DENOMINATOR || _maxSellBps > BPS_DENOMINATOR) revert InvalidBps();
        maxWalletBps = _maxWalletBps;
        maxSellBps = _maxSellBps;
        emit LimitsUpdated(_maxWalletBps, _maxSellBps);
    }

    /*
      Update cooldown in seconds between transfers for a wallet.
      To change:
        setCooldown(newCooldownSeconds);
    */
    function setCooldown(uint256 _cooldownSeconds) external onlyOwner {
        cooldownSeconds = _cooldownSeconds;
        emit CooldownUpdated(_cooldownSeconds);
    }

    /*
      Set/replace the treasury wallet.
      To change:
        setTreasuryWallet(newWallet);
    */
    function setTreasuryWallet(address _wallet) external onlyOwner {
        if (_wallet == address(0)) revert ZeroAddress();
        treasuryWallet = _wallet;
        emit TreasuryWalletUpdated(_wallet);
    }

    /*
      Set or unset an address as an AMM pair. Used to detect buys/sells.
      - Buy: from == pair
      - Sell: to == pair
      To change:
        setAutomatedMarketMakerPair(pair, true/false);
    */
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        if (pair == address(0)) revert ZeroAddress();
        automatedMarketMakerPairs[pair] = value;
        emit AutomatedMarketMakerPairSet(pair, value);
    }

    /*
      Exempt or unexempt an address from ALL fees, limits, and cooldown.
      Use this for owner, exchanges, routers, bridges as needed.
      To change:
        setExempt(account, true/false);
    */
    function setExempt(address account, bool value) external onlyOwner {
        if (account == address(0)) revert ZeroAddress();
        isExempt[account] = value;
        emit ExemptionUpdated(account, value);
    }

    // ============ Public View Helpers ============

    // Returns max wallet amount in tokens (absolute number)
    function maxWalletAmount() public view returns (uint256) {
        return (totalSupply() * maxWalletBps) / BPS_DENOMINATOR;
    }

    // Returns max sell amount per transaction in tokens (absolute number)
    function maxSellAmount() public view returns (uint256) {
        return (totalSupply() * maxSellBps) / BPS_DENOMINATOR;
    }

    // Returns remaining cooldown for a wallet in seconds (0 if none)
    function remainingCooldown(address account) public view returns (uint256) {
        uint256 last = lastTransferTimestamp[account];
        if (block.timestamp <= last + cooldownSeconds) {
            return last + cooldownSeconds - block.timestamp;
        }
        return 0;
    }

    // ============ Core Transfer Logic ============

    /*
      We override ERC20._update (OpenZeppelin 5.x) to apply our rules on transfers.
      - Skip logic for minting (from == 0) and burning (to == 0) except standard ERC20 behavior.
      - Apply cooldowns, fees, and limits only to non-exempt addresses.
      - Burn fee applies to every transfer (non-exempt) and is sent to DEAD.
      - Treasury fee applies to buys/sells only (when either side is an AMM pair).
      - Enforce max wallet after transfer and max sell on sell transactions.
    */
    function _update(address from, address to, uint256 value) internal override {
        // Minting or burning uses default ERC20 behavior
        if (from == address(0) || to == address(0)) {
            super._update(from, to, value);
            return;
        }

        bool fromExempt = isExempt[from];
        bool toExempt = isExempt[to];

        bool isBuy = automatedMarketMakerPairs[from];
        bool isSell = automatedMarketMakerPairs[to];

        // ========== Cooldown checks ==========
        if (!fromExempt) {
            // Cooldown for sender on any transfer (including sell)
            uint256 remain = remainingCooldown(from);
            if (remain > 0) revert CooldownActive(remain);
        }
        if (!toExempt) {
            // Cooldown for receiver on any transfer (including buy)
            // Skip cooldown check for AMM pair itself to avoid blocking market ops
            if (!automatedMarketMakerPairs[to]) {
                uint256 remainTo = remainingCooldown(to);
                if (remainTo > 0) revert CooldownActive(remainTo);
            }
        }

        // ========== Fee calculations ==========
        uint256 burnFeeAmount = 0;
        uint256 treasuryFeeAmount = 0;

        if (!fromExempt && !toExempt) {
            // Burn fee on all non-exempt transfers
            if (burnBps > 0) {
                burnFeeAmount = (value * burnBps) / BPS_DENOMINATOR;
            }

            // Treasury fee only on buys/sells
            if (treasuryBps > 0 && (isBuy || isSell)) {
                treasuryFeeAmount = (value * treasuryBps) / BPS_DENOMINATOR;
            }
        }

        uint256 feesTotal = burnFeeAmount + treasuryFeeAmount;
        if (feesTotal > 0) {
            // Transfer fees first, then the net amount
            if (burnFeeAmount > 0) {
                super._update(from, DEAD, burnFeeAmount);
            }
            if (treasuryFeeAmount > 0) {
                // If treasury wallet is exempt or not is irrelevant for receipt
                super._update(from, treasuryWallet, treasuryFeeAmount);
            }
        }

        uint256 sendAmount = value - feesTotal;

        // ========== Limits ==========
        // Max sell applies only on sells and when sender is not exempt
        if (isSell && !fromExempt) {
            uint256 maxSell = maxSellAmount();
            if (sendAmount > maxSell) revert ExceedsMaxSell();
        }

        // Perform the main transfer
        super._update(from, to, sendAmount);

        // Enforce max wallet on receiver after transfer, when receiver is not exempt and not an AMM pair
        if (!toExempt && !automatedMarketMakerPairs[to]) {
            uint256 maxWallet = maxWalletAmount();
            if (balanceOf(to) > maxWallet) revert ExceedsMaxWallet();
        }

        // ========== Update cooldown timestamps ==========
        if (!fromExempt) {
            lastTransferTimestamp[from] = block.timestamp;
        }
        // For receiver, we set timestamp except when it's an AMM pair (not a "wallet")
        if (!toExempt && !automatedMarketMakerPairs[to]) {
            lastTransferTimestamp[to] = block.timestamp;
        }
    }
}
