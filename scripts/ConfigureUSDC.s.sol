// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-console */
import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {IPoolConfigurator} from '../src/contracts/interfaces/IPoolConfigurator.sol';
import {IAaveOracle} from '../src/contracts/interfaces/IAaveOracle.sol';
import {ConfiguratorInputTypes} from '../src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {IDefaultInterestRateStrategyV2} from '../src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol';

contract ConfigureUSDC is Script {
  address constant POOL_CONFIGURATOR = 0x26A91A34a033d414EDB461fDFBA275e5dcCbB972;
  address constant ORACLE = 0xd215fdfE86E9836a80E2ab2c2DF52dd0AdDaacDe;
  address constant DEFAULT_INTEREST_RATE = 0xDbA07E77C393662e0628a25642D511e60ca9f90A;

  // Token implementations
  address constant ATOKEN_IMPL = 0x2DE2C76e35c2202eAf7e98db214618caC3eda1a3;
  address constant DEBT_TOKEN_IMPL = 0xcDE6e1df7751Dc95B55014f2b678b0F563cc42dD;

  // Mock USDC
  address constant USDC = 0xDF1B2c6007D810FaCBD84686C6e27CE03C2C4056;

  function run() external {
    uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
    address deployer = vm.addr(deployerPrivateKey);

    console.log('================================');
    console.log('Configuring Mock USDC');
    console.log('================================');
    console.log('USDC:', USDC);
    console.log('Deployer:', deployer);
    console.log('');

    vm.startBroadcast(deployerPrivateKey);

    IPoolConfigurator configurator = IPoolConfigurator(POOL_CONFIGURATOR);

    // Step 1: Initialize USDC reserve
    console.log('Step 1: Initializing USDC reserve...');
    ConfiguratorInputTypes.InitReserveInput[]
      memory input = new ConfiguratorInputTypes.InitReserveInput[](1);

    // Interest rate configuration for stablecoin (values in basis points)
    // optimalUsageRatio: 90% = 9000 bps
    // baseVariableBorrowRate: 0% = 0 bps
    // variableRateSlope1: 4% = 400 bps (slope until optimal usage)
    // variableRateSlope2: 60% = 6000 bps (slope after optimal usage)
    IDefaultInterestRateStrategyV2.InterestRateData memory rateData = IDefaultInterestRateStrategyV2
      .InterestRateData({
        optimalUsageRatio: 9000,
        baseVariableBorrowRate: 0,
        variableRateSlope1: 400,
        variableRateSlope2: 6000
      });

    input[0] = ConfiguratorInputTypes.InitReserveInput({
      aTokenImpl: ATOKEN_IMPL,
      variableDebtTokenImpl: DEBT_TOKEN_IMPL,
      underlyingAsset: USDC,
      aTokenName: 'Aave HyperEVM USDC',
      aTokenSymbol: 'aHypUSDC',
      variableDebtTokenName: 'Aave HyperEVM Variable Debt USDC',
      variableDebtTokenSymbol: 'variableDebtHypUSDC',
      params: bytes(''),
      interestRateData: abi.encode(rateData)
    });

    configurator.initReserves(input);
    console.log('  Reserve initialized!');

    // Step 2: Configure as collateral
    console.log('');
    console.log('Step 2: Configuring collateral parameters...');
    configurator.configureReserveAsCollateral(
      USDC,
      8000, // 80% LTV
      8500, // 85% Liquidation Threshold
      10500 // 5% Liquidation Bonus
    );
    console.log('  Collateral configured!');

    // Step 3: Enable borrowing
    console.log('');
    console.log('Step 3: Enabling borrowing...');
    configurator.setReserveBorrowing(USDC, true);
    console.log('  Borrowing enabled!');

    // Step 4: Set reserve factor
    console.log('');
    console.log('Step 4: Setting reserve factor...');
    configurator.setReserveFactor(USDC, 1000); // 10%
    console.log('  Reserve factor set!');

    // Step 5: Activate reserve
    console.log('');
    console.log('Step 5: Activating reserve...');
    configurator.setReserveActive(USDC, true);
    console.log('  Reserve activated!');

    // Step 6: Set oracle price
    console.log('');
    console.log('Step 6: Setting oracle price...');
    IAaveOracle oracle = IAaveOracle(ORACLE);

    // Deploy mock oracle
    MockPriceOracle mockOracle = new MockPriceOracle();
    console.log('  MockOracle deployed:', address(mockOracle));

    address[] memory assets = new address[](1);
    address[] memory sources = new address[](1);
    assets[0] = USDC;
    sources[0] = address(mockOracle);

    oracle.setAssetSources(assets, sources);

    // Verify price
    uint256 price = oracle.getAssetPrice(USDC);
    console.log('  Oracle configured! USDC price:', price);

    vm.stopBroadcast();

    console.log('');
    console.log('================================');
    console.log('USDC Configuration Complete!');
    console.log('================================');
    console.log('You can now:');
    console.log('1. Supply USDC to earn interest');
    console.log('2. Use USDC as collateral');
    console.log('3. Borrow against USDC');
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
