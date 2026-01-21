# ⚡️ Token Presale Core

![Foundry](https://img.shields.io/badge/Built%20with-Foundry-orange?style=flat-square&logo=c)
![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.20-363636?style=flat-square&logo=solidity)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Tests](https://img.shields.io/badge/Tests-Passing-success?style=flat-square)

A high-performance, gas-optimized Smart Contract suite meant to handle **Token Presales (ICO/IDO)**. This project leverages the **Foundry** framework to ensure robust security through fuzzing and invariant testing strategies.

## 🧠 Project Overview

This repository contains the logic for a secure fundraising mechanism. It manages the entire lifecycle of a token sale, prioritizing capital safety and fair distribution.

### 🔄 Logic Flow

1.  **Initialization:** The Admin deploys the contract defining the **Exchange Rate**, **Hard Cap**, and **Wallet Limits** (Min/Max contribution).
2.  **Contribution:** Users send ETH (or native coin) to purchase tokens.
    *   *Validation:* Checks if the sale is active and within limits.
    *   *Accounting:* Updates user balances and total raised amount.
3.  **Finalization:** Once the cap is reached or time expires:
    *   Admin withdraws raised funds.
    *   Token distribution is enabled.
4.  **Claiming:** Investors withdraw their tokens. Support for vesting schedules (linear or staged release) can be configured.

## 🧪 Testing Strategy

We utilize **Foundry** to go beyond simple unit testing. The test suite located in `test/` ensures the contract behaves correctly under all conditions.

| Test Type | Objective | Command |
| :--- | :--- | :--- |
| **Unit Tests** | Verify standard user flows (Buy, Claim, Withdraw) and error handling. | `forge test` |
| **Fuzz Testing** | Injects thousands of random inputs to detect edge cases (e.g., overflow issues with massive values). | `forge test --fuzz-runs 5000` |
| **Invariant Tests** | Assertions that must *always* be true (e.g., "Contract ETH balance must equal Total Raised"). | `forge test --invariant` |
| **Gas Snapshots** | Optimization checks to ensure low transaction costs for users. | `forge snapshot` |

## 📂 Project Structure


├── src/            # Smart Contracts (Presale logic, Interfaces)
├── script/         # Deployment and interaction scripts (Solidity)
├── test/           # Foundry test suite (Unit, Fuzz, Invariant)
└── foundry.toml    # Framework configuration
## 🚀 Quick Start
1. Prerequisites
Ensure you have Foundry installed.

2. Build & Test

# Install dependencies
forge install

# Build contracts
forge build

# Run all tests with traces
forge test -vvvv
3. Deployment
To deploy to a network (e.g., Sepolia):

Create a .env file based on .env.example.
Run the deployment script:


forge script script/DeployPresale.s.sol:DeployPresale \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
## 🛡 Security Features
Reentrancy Protection: Prevents recursive attacks on withdrawal functions.
Access Control: Strict ownership management for admin-only functions.
Safe Math: Built-in overflow protection (Solidity 0.8+).
<p align="center"> <sub>Created by <a href="https://github.com/SRubio27">SRubio27</a></sub> </p> ```
