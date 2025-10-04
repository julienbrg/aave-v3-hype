# Aave V3 Deployment Guide for HyperEVM Testnet

## Overview

This guide walks you through deploying Aave V3 to HyperEVM Testnet. Due to HyperEVM's dual-block architecture, large contracts require enabling "big blocks" (30M gas limit) instead of the default small blocks (2M gas limit).

## Prerequisites

- Foundry installed
- Python 3.7+ installed
- Private key with testnet HYPE tokens
- Your deployer address: `0x9a6586c563D56899d2d84a6b22729870126f62Fb`

## Network Information

- **Network**: HyperEVM Testnet
- **Chain ID**: 998
- **RPC URL**: `https://rpc.hyperliquid-testnet.xyz/evm`
- **Gas Token**: HYPE (18 decimals)
- **Block Explorer**: https://testnet.purrsec.com/

## Step 1: Enable Big Blocks

Aave contracts are too large for HyperEVM's small blocks (2M gas limit). You must enable big blocks first.

### Install Python SDK

```bash
pip install hyperliquid-python-sdk eth-account
```

### Create Enable Big Blocks Script

Create a file named `enable_big_blocks.py`:

```python
from hyperliquid.utils import constants
from hyperliquid.exchange import Exchange
from eth_account import Account

# Replace with your actual private key
PRIVATE_KEY = "YOUR_PRIVATE_KEY_HERE"

# Initialize account
account = Account.from_key(PRIVATE_KEY)
print(f"Using address: {account.address}")

# Connect to testnet
exchange = Exchange(account, constants.TESTNET_API_URL)

# Enable big blocks
try:
    result = exchange.update_user_settings({"usingBigBlocks": True})
    print("✅ Big blocks enabled successfully!")
    print(f"Result: {result}")
except Exception as e:
    print(f"❌ Error: {e}")
    print("\nNote: Your address must be a HyperCore user first.")
    print("Receive USDC or another Core asset to convert your EOA to a HyperCore user.")
```

### Run the Script

```bash
python enable_big_blocks.py
```

**Important**: Your address must have received a HyperCore asset (like USDC) at least once to become a HyperCore user. If you get an error, send yourself a small amount of USDC first.

## Step 2: Deploy Aave V3 Contracts

Once big blocks are enabled, deploy the contracts in sequence.

### Environment Setup

Create `.env` file in your project root:

```bash
PRIVATE_KEY=your_private_key_here
HYPEREVM_TESTNET_RPC_URL=https://rpc.hyperliquid-testnet.xyz/evm
```

### Deployment Sequence

#### Deploy Step 1: PoolAddressesProvider

```bash
forge script scripts/Deploy_Step1_Provider.s.sol:Deploy_Step1_Provider \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

**Save the PoolAddressesProvider address from the output.**

---

#### Deploy Step 2: Set ACL Admin

Update `PROVIDER` address in `Deploy_Step2_SetACLAdmin.s.sol` with the address from Step 1.

```bash
forge script scripts/Deploy_Step2_SetACLAdmin.s.sol:Deploy_Step2_SetACLAdmin \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

---

#### Deploy Step 3: ACLManager

Update `PROVIDER` address in `Deploy_Step3_ACLManager.s.sol` with the address from Step 1.

```bash
forge script scripts/Deploy_Step3_ACLManager.s.sol:Deploy_Step3_ACLManager \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

**Save the ACLManager address from the output.**

---

#### Deploy Step 4: Grant Roles

Update `ACL_MANAGER` address in `Deploy_Step4_GrantRoles.s.sol` with the address from Step 3.

```bash
forge script scripts/Deploy_Step4_GrantRoles.s.sol:Deploy_Step4_GrantRoles \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

---

#### Deploy Step 5: Interest Rate Strategy

Update `ADDRESSES_PROVIDER` in `DeployHyperEVM_Phase1B.s.sol` with the address from Step 1.

```bash
forge script scripts/DeployHyperEVM_Phase1B.s.sol:DeployHyperEVM_Phase1B \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

**Save the InterestRateStrategy address from the output.**

---

#### Deploy Step 6: Pool

Update addresses in `DeployHyperEVM_Phase2.s.sol`:

- `ADDRESSES_PROVIDER` from Step 1
- `INTEREST_RATE_STRATEGY` from Step 5

```bash
forge script scripts/DeployHyperEVM_Phase2.s.sol:DeployHyperEVM_Phase2 \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

---

#### Deploy Step 7: PoolConfigurator

Update `ADDRESSES_PROVIDER` in `DeployHyperEVM_Phase3.s.sol` with the address from Step 1.

```bash
forge script scripts/DeployHyperEVM_Phase3.s.sol:DeployHyperEVM_Phase3 \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

---

#### Deploy Step 8: Oracle & DataProvider

Update `ADDRESSES_PROVIDER` in `DeployHyperEVM_Phase4.s.sol` with the address from Step 1.

```bash
forge script scripts/DeployHyperEVM_Phase4.s.sol:DeployHyperEVM_Phase4 \
    --rpc-url https://rpc.hyperliquid-testnet.xyz/evm \
    --broadcast \
    --legacy \
    -vv
```

## Step 3: Disable Big Blocks (Optional)

After deployment, you may want to disable big blocks for regular transactions:

Create `disable_big_blocks.py`:

```python
from hyperliquid.utils import constants
from hyperliquid.exchange import Exchange
from eth_account import Account

PRIVATE_KEY = "YOUR_PRIVATE_KEY_HERE"

account = Account.from_key(PRIVATE_KEY)
exchange = Exchange(account, constants.TESTNET_API_URL)

result = exchange.update_user_settings({"usingBigBlocks": False})
print("✅ Big blocks disabled. Transactions will now use small blocks (faster).")
```

```bash
python disable_big_blocks.py
```

## Deployed Contract Addresses

Keep a record of all deployed addresses:

```
PoolAddressesProvider:
ACLManager:
InterestRateStrategy:
Pool (Proxy):
Pool (Implementation):
PoolConfigurator (Proxy):
PoolConfigurator (Implementation):
AaveOracle:
AaveProtocolDataProvider:
```

## Next Steps After Deployment

1. **Deploy Token Implementations** (AToken, VariableDebtToken, StableDebtToken)
2. **List Assets** (USDC, WETH, etc.) with proper parameters
3. **Configure Price Oracles** for each asset
4. **Set Interest Rate Parameters** per asset
5. **Configure Risk Parameters** (LTV, liquidation thresholds, reserve factors)

## Troubleshooting

### "exceeds block gas limit"

- Make sure big blocks are enabled via Python SDK
- Verify your address is a HyperCore user (has received USDC/Core asset)

### "rate limited"

- Wait 2-3 minutes between deployment attempts
- The RPC has rate limits; space out your deployments

### Python SDK Issues

- Ensure `hyperliquid-python-sdk` and `eth-account` are installed
- Use Python 3.7 or higher
- Check your private key format (should be 64 hex characters, with or without 0x prefix)

## HyperEVM Resources

- **Docs**: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm
- **Dual Block Architecture**: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm/dual-block-architecture
- **Explorer**: https://testnet.purrsec.com/
- **Faucet**: https://faucet.chainstack.com/hyperliquid-testnet-faucet

## Important Notes

- Small blocks: 2M gas limit, ~2 second block time
- Big blocks: 30M gas limit, ~60 second block time
- Big blocks are required for deploying large contracts like Aave
- Remember to disable big blocks after deployment for faster regular transactions
- HyperEVM is EVM-compatible but uses HYPE as the gas token (not ETH)
- All deployments are on testnet - use testnet HYPE tokens only
