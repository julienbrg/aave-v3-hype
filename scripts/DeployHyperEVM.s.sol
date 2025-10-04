// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-console */
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {PoolAddressesProvider} from '../src/contracts/protocol/configuration/PoolAddressesProvider.sol';
import {PoolInstance} from '../src/contracts/instances/PoolInstance.sol';
import {PoolConfiguratorInstance} from '../src/contracts/instances/PoolConfiguratorInstance.sol';
import {AaveOracle} from '../src/contracts/misc/AaveOracle.sol';
import {ACLManager} from '../src/contracts/protocol/configuration/ACLManager.sol';
import {AaveProtocolDataProvider} from '../src/contracts/helpers/AaveProtocolDataProvider.sol';
import {DefaultReserveInterestRateStrategyV2} from '../src/contracts/misc/DefaultReserveInterestRateStrategyV2.sol';
import {IPoolAddressesProvider} from '../src/contracts/interfaces/IPoolAddressesProvider.sol';
import {IReserveInterestRateStrategy} from '../src/contracts/interfaces/IReserveInterestRateStrategy.sol';

contract DeployHyperEVM is Script {
  address public deployer;

  // Core Protocol Contracts
  PoolAddressesProvider public addressesProvider;
  ACLManager public aclManager;
  PoolInstance public poolImpl;
  PoolConfiguratorInstance public configuratorImpl;
  AaveOracle public oracle;
  AaveProtocolDataProvider public protocolDataProvider;
  DefaultReserveInterestRateStrategyV2 public defaultInterestRateStrategy;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    deployer = vm.addr(deployerPrivateKey);

    console.log('=================================');
    console.log('Deploying Aave V3 to HyperEVM Testnet');
    console.log('=================================');
    console.log('Deployer address:', deployer);
    console.log('Chain ID: 998');
    console.log('');

    vm.startBroadcast(deployerPrivateKey);

    // Step 1: Deploy PoolAddressesProvider
    console.log('1. Deploying PoolAddressesProvider...');
    addressesProvider = new PoolAddressesProvider(
      'HyperEVM Aave Market', // Market ID
      deployer // Owner
    );
    console.log('   PoolAddressesProvider:', address(addressesProvider));

    // Step 1.5: Set ACL Admin (required before deploying ACLManager)
    console.log('1.5. Setting ACL Admin...');
    addressesProvider.setACLAdmin(deployer);
    console.log('   ACL Admin set to:', deployer);

    // Step 2: Deploy ACLManager
    console.log('2. Deploying ACLManager...');
    aclManager = new ACLManager(IPoolAddressesProvider(address(addressesProvider)));
    addressesProvider.setACLManager(address(aclManager));
    console.log('   ACLManager:', address(aclManager));

    // Step 3: Deploy Default Interest Rate Strategy
    console.log('3. Deploying Default Interest Rate Strategy...');
    // Note: Interest rate parameters are set per reserve during asset listing
    defaultInterestRateStrategy = new DefaultReserveInterestRateStrategyV2(
      address(addressesProvider)
    );
    console.log('   DefaultInterestRateStrategy:', address(defaultInterestRateStrategy));

    // Step 4: Deploy Pool Implementation
    console.log('4. Deploying Pool Implementation...');
    poolImpl = new PoolInstance(
      IPoolAddressesProvider(address(addressesProvider)),
      IReserveInterestRateStrategy(address(defaultInterestRateStrategy))
    );
    addressesProvider.setPoolImpl(address(poolImpl));
    console.log('   Pool Implementation:', address(poolImpl));
    console.log('   Pool Proxy:', addressesProvider.getPool());

    // Step 5: Deploy PoolConfigurator Implementation
    console.log('5. Deploying PoolConfigurator Implementation...');
    configuratorImpl = new PoolConfiguratorInstance();
    addressesProvider.setPoolConfiguratorImpl(address(configuratorImpl));
    console.log('   PoolConfigurator Implementation:', address(configuratorImpl));
    console.log('   PoolConfigurator Proxy:', addressesProvider.getPoolConfigurator());

    // Step 6: Deploy AaveOracle
    console.log('6. Deploying AaveOracle...');
    address[] memory assets = new address[](0);
    address[] memory sources = new address[](0);
    address fallbackOracle = address(0);
    address baseCurrency = address(0); // ETH/native token
    uint256 baseCurrencyUnit = 1e18;

    oracle = new AaveOracle(
      IPoolAddressesProvider(address(addressesProvider)),
      assets,
      sources,
      fallbackOracle,
      baseCurrency,
      baseCurrencyUnit
    );
    addressesProvider.setPriceOracle(address(oracle));
    console.log('   AaveOracle:', address(oracle));

    // Step 7: Deploy AaveProtocolDataProvider
    console.log('7. Deploying AaveProtocolDataProvider...');
    protocolDataProvider = new AaveProtocolDataProvider(
      IPoolAddressesProvider(address(addressesProvider))
    );
    console.log('   AaveProtocolDataProvider:', address(protocolDataProvider));

    // Step 8: Grant roles to deployer
    console.log('8. Setting up roles...');
    aclManager.addPoolAdmin(deployer);
    aclManager.addEmergencyAdmin(deployer);
    aclManager.addAssetListingAdmin(deployer);
    console.log('   Roles granted to deployer');

    vm.stopBroadcast();

    // Print deployment summary
    console.log('');
    console.log('=================================');
    console.log('Deployment Summary');
    console.log('=================================');
    console.log('Network: HyperEVM Testnet');
    console.log('Chain ID: 998');
    console.log('RPC: https://rpc.hyperliquid-testnet.xyz/evm');
    console.log('');
    console.log('Core Contracts:');
    console.log('  PoolAddressesProvider:', address(addressesProvider));
    console.log('  ACLManager:', address(aclManager));
    console.log('  Pool (Proxy):', addressesProvider.getPool());
    console.log('  Pool (Implementation):', address(poolImpl));
    console.log('  PoolConfigurator (Proxy):', addressesProvider.getPoolConfigurator());
    console.log('  PoolConfigurator (Implementation):', address(configuratorImpl));
    console.log('  AaveOracle:', address(oracle));
    console.log('  AaveProtocolDataProvider:', address(protocolDataProvider));
    console.log('  DefaultInterestRateStrategy:', address(defaultInterestRateStrategy));
    console.log('');
    console.log('Admin:');
    console.log('  Owner/Admin:', deployer);
    console.log('');
    console.log('=================================');
    console.log('Next Steps:');
    console.log('=================================');
    console.log('1. Deploy reserve tokens (aTokens, debt tokens)');
    console.log('2. List assets (USDC, WETH, etc.)');
    console.log('3. Configure price oracles for each asset');
    console.log('4. Set interest rate strategies per asset');
    console.log('5. Configure risk parameters (LTV, liquidation thresholds)');
    console.log('=================================');
    console.log('');
    console.log('SAVE THESE ADDRESSES!');
  }
}
