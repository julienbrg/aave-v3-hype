// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-console */
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';

interface IPool {
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract SupplyUSDC is Script {
  address public constant POOL = 0xf4438C3554d0360ECDe4358232821354e71C59e9;
  address public constant USDC = 0xDF1B2c6007D810FaCBD84686C6e27CE03C2C4056;
  uint256 public constant AMOUNT = 1000 * 1e18; // 1000 USDC (18 decimals)

  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    address deployer = vm.addr(deployerPrivateKey);

    console.log('================================');
    console.log('Supplying USDC to Aave');
    console.log('================================');

    vm.startBroadcast(deployerPrivateKey);

    IERC20 usdc = IERC20(USDC);
    IPool pool = IPool(POOL);

    uint256 balance = usdc.balanceOf(deployer);
    console.log('Your USDC balance:', balance / 1e18, 'USDC');

    require(balance >= AMOUNT, 'Insufficient balance');

    console.log('Approving USDC...');
    usdc.approve(POOL, AMOUNT);

    console.log('Supplying to Aave...');
    pool.supply(USDC, AMOUNT, deployer, 0);

    console.log('');
    console.log('Success! Supplied', AMOUNT / 1e18, 'USDC');
    console.log('You are now earning interest!');

    vm.stopBroadcast();
  }
}
