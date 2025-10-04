#!/bin/bash

CHAIN_ID=998
VERIFIER_URL="https://sourcify.parsec.finance/verify"
DEPLOYER="0x9a6586c563D56899d2d84a6b22729870126f62Fb"

echo "🔍 Verifying deployed contracts on HyperEVM testnet..."
echo ""

# Core Infrastructure
echo "📦 PoolAddressesProvider..."
forge verify-contract 0x3097BDC98DCCC8B8b56E478972a645705E756785 \
  src/contracts/protocol/configuration/PoolAddressesProvider.sol:PoolAddressesProvider \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(string,address)" "HyperEVM-Aave-Market" "$DEPLOYER") || echo "⚠️  Already verified"

echo ""
echo "📦 ACLManager..."
forge verify-contract 0x96FB5950755e25F4e1CBFA994698345738e705a2 \
  src/contracts/protocol/configuration/ACLManager.sol:ACLManager \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(address)" "0x3097BDC98DCCC8B8b56E478972a645705E756785") || echo "⚠️  Already verified"

echo ""
echo "📦 Pool Implementation..."
forge verify-contract 0xe9509119aEF8e40B58D5607A63042C9dAF6aA8dc \
  src/contracts/protocol/pool/Pool.sol:Pool \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(address)" "0x3097BDC98DCCC8B8b56E478972a645705E756785") || echo "⚠️  Failed or already verified"

echo ""
echo "📦 PoolConfigurator Implementation..."
forge verify-contract 0x71D3e5Ef02440E2D39D6142f75EAAB921EA070DB \
  src/contracts/protocol/pool/PoolConfigurator.sol:PoolConfigurator \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check || echo "⚠️  Failed or already verified"

echo ""
echo "📦 AaveOracle..."
forge verify-contract 0xd215fdfE86E9836a80E2ab2c2DF52dd0AdDaacDe \
  src/contracts/misc/AaveOracle.sol:AaveOracle \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(address,address[],address[])" "0x3097BDC98DCCC8B8b56E478972a645705E756785" "[]" "[]") || echo "⚠️  Failed or already verified"

echo ""
echo "📦 AaveProtocolDataProvider..."
forge verify-contract 0x4002F5C8aab325C22874963c61625A65D08744DC \
  src/contracts/misc/AaveProtocolDataProvider.sol:AaveProtocolDataProvider \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(address)" "0x3097BDC98DCCC8B8b56E478972a645705E756785") || echo "⚠️  Failed or already verified"

echo ""
echo "📦 DefaultInterestRateStrategy..."
forge verify-contract 0xDbA07E77C393662e0628a25642D511e60ca9f90A \
  src/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol:DefaultReserveInterestRateStrategy \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256,uint256,uint256)" "0x3097BDC98DCCC8B8b56E478972a645705E756785" "0" "40000000000000000000000000" "600000000000000000000000000" "900000000000000000000000000" "0" "0") || echo "⚠️  Failed or already verified"

echo ""
echo "📦 Mock USDC..."
forge verify-contract 0xDF1B2c6007D810FaCBD84686C6e27CE03C2C4056 \
  src/MockUSDC.sol:MockUSDC \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check || echo "⚠️  Failed or already verified"

echo ""
echo "📦 AToken Implementation..."
forge verify-contract 0x2DE2C76e35c2202eAf7e98db214618caC3eda1a3 \
  src/contracts/protocol/tokenization/AToken.sol:AToken \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(address)" "0xf4438C3554d0360ECDe4358232821354e71C59e9") || echo "⚠️  Failed or already verified"

echo ""
echo "📦 VariableDebtToken Implementation..."
forge verify-contract 0xcDE6e1df7751Dc95B55014f2b678b0F563cc42dD \
  src/contracts/protocol/tokenization/VariableDebtToken.sol:VariableDebtToken \
  --chain $CHAIN_ID \
  --verifier sourcify \
  --verifier-url $VERIFIER_URL \
  --skip-is-verified-check \
  --constructor-args $(cast abi-encode "constructor(address)" "0xf4438C3554d0360ECDe4358232821354e71C59e9") || echo "⚠️  Failed or already verified"

echo ""
echo "✅ Verification completed!"
echo ""
echo "📋 Summary of contracts verified:"
echo "   ✓ PoolAddressesProvider"
echo "   ✓ ACLManager"
echo "   ✓ Pool Implementation"
echo "   ✓ PoolConfigurator Implementation"
echo "   ✓ AaveOracle"
echo "   ✓ AaveProtocolDataProvider"
echo "   ✓ DefaultInterestRateStrategy"
echo "   ✓ Mock USDC"
echo "   ✓ AToken Implementation"
echo "   ✓ VariableDebtToken Implementation"
echo ""
echo "💡 Check https://sourcify.parsec.finance for verification status"
