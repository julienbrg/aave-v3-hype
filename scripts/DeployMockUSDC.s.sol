// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-console */
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {MockUSDC} from '../src/MockUSDC.sol';

contract DeployMockUSDC is Script {
  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    address deployer = vm.addr(deployerPrivateKey);

    console.log('================================');
    console.log('Deploying Mock USDC');
    console.log('================================');
    console.log('Deployer:', deployer);
    console.log('');

    vm.startBroadcast(deployerPrivateKey);

    // Deploy Mock USDC (automatically mints 1M USDC to deployer)
    MockUSDC usdc = new MockUSDC();

    vm.stopBroadcast();

    console.log('================================');
    console.log('Mock USDC Deployed!');
    console.log('================================');
    console.log('Address:', address(usdc));
    console.log('Name:', usdc.name());
    console.log('Symbol:', usdc.symbol());
    console.log('Decimals:', usdc.decimals());
    console.log('Your balance:', usdc.balanceOf(deployer) / 1e6, 'USDC');
    console.log('================================');
    console.log('');
    console.log('SAVE THIS ADDRESS!');
    console.log('Update ConfigureUSDC.s.sol with:');
    console.log('address constant USDC =', address(usdc), ';');
    console.log('================================');
  }
}
