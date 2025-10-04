// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-console */
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {ATokenInstance} from '../src/contracts/instances/ATokenInstance.sol';
import {VariableDebtTokenInstance} from '../src/contracts/instances/VariableDebtTokenInstance.sol';
import {IPool} from '../src/contracts/interfaces/IPool.sol';

contract DeployTokenImplementations is Script {
  // Vos contrats déjà déployés
  address public constant POOL = 0xf4438C3554d0360ECDe4358232821354e71C59e9;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    address deployer = vm.addr(deployerPrivateKey);

    console.log('================================');
    console.log('Deploying Token Implementations');
    console.log('================================');
    console.log('Deployer:', deployer);
    console.log('Pool:', POOL);
    console.log('');

    vm.startBroadcast(deployerPrivateKey);

    // Deploy AToken implementation
    console.log('Step 1: Deploying AToken implementation...');
    ATokenInstance aTokenImpl = new ATokenInstance(
      IPool(POOL),
      address(0), // rewards controller (optionnel)
      deployer // treasury
    );
    console.log('  AToken implementation:', address(aTokenImpl));

    // Deploy VariableDebtToken implementation
    console.log('');
    console.log('Step 2: Deploying VariableDebtToken implementation...');
    VariableDebtTokenInstance debtTokenImpl = new VariableDebtTokenInstance(
      IPool(POOL),
      address(0) // rewards controller (optionnel)
    );
    console.log('  VariableDebtToken implementation:', address(debtTokenImpl));

    vm.stopBroadcast();

    console.log('');
    console.log('================================');
    console.log('Token Implementations Deployed!');
    console.log('================================');
    console.log('AToken implementation:', address(aTokenImpl));
    console.log('VariableDebtToken implementation:', address(debtTokenImpl));
    console.log('');
    console.log('================================');
    console.log('Next Step:');
    console.log('================================');
    console.log('Update ConfigureUSDC.s.sol with these addresses:');
    console.log('');
    console.log('address constant ATOKEN_IMPL =', address(aTokenImpl), ';');
    console.log('address constant DEBT_TOKEN_IMPL =', address(debtTokenImpl), ';');
    console.log('');
    console.log('Then change in initReserves:');
    console.log('  aTokenImpl: ATOKEN_IMPL');
    console.log('  variableDebtTokenImpl: DEBT_TOKEN_IMPL');
    console.log('================================');
  }
}
