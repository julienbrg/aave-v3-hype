// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-console */
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';

// Absolutely minimal contract for testing deployment
contract TinyTest {
  uint256 public value = 42;
}

contract Deploy_MinimalTest is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    address deployer = vm.addr(deployerPrivateKey);

    console.log('Minimal Test Deployment');
    console.log('Deployer:', deployer);

    vm.startBroadcast(deployerPrivateKey);

    TinyTest test = new TinyTest();

    vm.stopBroadcast();

    console.log('TinyTest deployed at:', address(test));
    console.log('Gas used should be minimal (~100k)');
  }
}
