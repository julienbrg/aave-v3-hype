// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-console */
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {IAaveOracle} from '../src/contracts/interfaces/IAaveOracle.sol';

contract ConfigureOracle is Script {
  // Deployed addresses from your recap
  address constant AAVE_ORACLE = 0xd215fdfE86E9836a80E2ab2c2DF52dd0AdDaacDe;
  address constant USDC = 0xDF1B2c6007D810FaCBD84686C6e27CE03C2C4056;

  function run() external {
    string memory privateKeyStr = vm.envString('PRIVATE_KEY');
    uint256 deployerPrivateKey;

    // Handle private key with or without 0x prefix
    if (bytes(privateKeyStr).length == 66) {
      // Has 0x prefix
      deployerPrivateKey = vm.parseUint(privateKeyStr);
    } else {
      // No prefix, add it
      deployerPrivateKey = vm.parseUint(string.concat('0x', privateKeyStr));
    }

    address deployer = vm.addr(deployerPrivateKey);

    console.log('================================');
    console.log('Configuring Oracle');
    console.log('================================');
    console.log('AaveOracle:', AAVE_ORACLE);
    console.log('Deployer:', deployer);
    console.log('');

    vm.startBroadcast(deployerPrivateKey);

    IAaveOracle oracle = IAaveOracle(AAVE_ORACLE);

    // Deploy mock oracle for USDC
    console.log('Step 1: Deploying MockPriceOracle for USDC...');
    MockPriceOracle mockOracle = new MockPriceOracle();
    console.log('  MockPriceOracle deployed:', address(mockOracle));
    console.log('  Price set to: $1.00');

    // Configure oracle
    console.log('');
    console.log('Step 2: Setting USDC price source in AaveOracle...');
    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);
    assets[0] = USDC;
    sources[0] = address(mockOracle);

    oracle.setAssetSources(assets, sources);
    console.log('  USDC price source configured!');

    // Verify configuration
    console.log('');
    console.log('Step 3: Verifying oracle configuration...');
    address retrievedSource = oracle.getSourceOfAsset(USDC);
    console.log('  USDC price source:', retrievedSource);

    uint256 price = oracle.getAssetPrice(USDC);
    console.log('  USDC price from oracle:', price);
    console.log('  (Expected: 1000000000000000000 = $1.00 with 18 decimals)');

    vm.stopBroadcast();

    console.log('');
    console.log('================================');
    console.log('Oracle Configuration Complete!');
    console.log('================================');
    console.log('MockPriceOracle (USDC):', address(mockOracle));
    console.log('AaveOracle:', AAVE_ORACLE);
    console.log('USDC Asset:', USDC);
    console.log('================================');
  }
}

// Mock Oracle that returns $1.00
contract MockPriceOracle {
  function latestAnswer() external pure returns (int256) {
    return 100000000; // $1.00 with 8 decimals (Chainlink format)
  }

  function decimals() external pure returns (uint8) {
    return 8;
  }
}
