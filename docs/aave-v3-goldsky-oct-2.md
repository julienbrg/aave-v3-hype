# Aave V3 HyperEVM - Goldsky Indexer Setup

Complete guide to deploy a Goldsky subgraph indexer for your Aave V3 deployment on HyperEVM testnet.

---

## Directory Structure

```
aave-v3-subgraph/
├── subgraph.yaml
├── schema.graphql
├── src/
│   └── mapping.ts
├── abis/
│   ├── Pool.json
│   ├── AToken.json
│   └── AaveOracle.json
└── package.json
```

---

## 1. subgraph.yaml

```yaml
specVersion: 0.0.5
schema:
  file: ./schema.graphql
dataSources:
  # Pool - Main lending pool contract
  - kind: ethereum
    name: Pool
    network: hyperevm-testnet
    source:
      address: "0xf4438C3554d0360ECDe4358232821354e71C59e9"
      abi: Pool
      startBlock: 0 # Replace with your actual deployment block
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Reserve
        - User
        - UserReserve
        - SupplyEvent
        - WithdrawEvent
        - BorrowEvent
        - RepayEvent
        - LiquidationEvent
      abis:
        - name: Pool
          file: ./abis/Pool.json
        - name: AToken
          file: ./abis/AToken.json
        - name: AaveOracle
          file: ./abis/AaveOracle.json
      eventHandlers:
        - event: Supply(indexed address,address,indexed address,uint256,indexed uint16)
          handler: handleSupply
        - event: Withdraw(indexed address,indexed address,indexed address,uint256)
          handler: handleWithdraw
        - event: Borrow(indexed address,address,indexed address,uint256,uint8,uint256,indexed uint16)
          handler: handleBorrow
        - event: Repay(indexed address,indexed address,indexed address,uint256,bool)
          handler: handleRepay
        - event: LiquidationCall(indexed address,indexed address,indexed address,uint256,uint256,address,bool)
          handler: handleLiquidationCall
        - event: ReserveDataUpdated(indexed address,uint256,uint256,uint256,uint256,uint256)
          handler: handleReserveDataUpdated
      file: ./src/mapping.ts

  # AaveOracle - Price oracle
  - kind: ethereum
    name: AaveOracle
    network: hyperevm-testnet
    source:
      address: "0xd215fdfE86E9836a80E2ab2c2DF52dd0AdDaacDe"
      abi: AaveOracle
      startBlock: 0 # Replace with your actual deployment block
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Reserve
        - PriceUpdate
      abis:
        - name: AaveOracle
          file: ./abis/AaveOracle.json
      eventHandlers:
        - event: AssetPriceUpdated(address,uint256,uint256)
          handler: handleAssetPriceUpdated
      file: ./src/mapping.ts
```

---

## 2. schema.graphql

```graphql
type Reserve @entity {
  id: ID! # asset address
  symbol: String!
  name: String!
  decimals: Int!

  # Supply metrics
  totalLiquidity: BigInt!
  availableLiquidity: BigInt!
  totalSupplied: BigInt!

  # Borrow metrics
  totalBorrowed: BigInt!
  totalBorrowedVariable: BigInt!

  # Rates (in Ray - 27 decimals)
  liquidityRate: BigInt!
  variableBorrowRate: BigInt!
  liquidityIndex: BigInt!
  variableBorrowIndex: BigInt!

  # Oracle price (in USD, 8 decimals)
  priceInUSD: BigInt!
  lastUpdateTimestamp: BigInt!

  # Collateral params
  ltv: BigInt!
  liquidationThreshold: BigInt!
  liquidationBonus: BigInt!
  reserveFactor: BigInt!

  # Status flags
  isActive: Boolean!
  isFrozen: Boolean!
  borrowingEnabled: Boolean!
  usageAsCollateralEnabled: Boolean!

  # aToken
  aTokenAddress: Bytes!
  variableDebtTokenAddress: Bytes!

  # Relationships
  supplies: [SupplyEvent!]! @derivedFrom(field: "reserve")
  withdraws: [WithdrawEvent!]! @derivedFrom(field: "reserve")
  borrows: [BorrowEvent!]! @derivedFrom(field: "reserve")
  repays: [RepayEvent!]! @derivedFrom(field: "reserve")
  liquidations: [LiquidationEvent!]! @derivedFrom(field: "collateralReserve")
  userReserves: [UserReserve!]! @derivedFrom(field: "reserve")
}

type User @entity {
  id: ID! # user address
  # Aggregate metrics
  totalSuppliedUSD: BigInt!
  totalBorrowedUSD: BigInt!
  totalCollateralUSD: BigInt!
  healthFactor: BigInt!

  # Relationships
  reserves: [UserReserve!]! @derivedFrom(field: "user")
  supplies: [SupplyEvent!]! @derivedFrom(field: "user")
  withdraws: [WithdrawEvent!]! @derivedFrom(field: "user")
  borrows: [BorrowEvent!]! @derivedFrom(field: "user")
  repays: [RepayEvent!]! @derivedFrom(field: "user")
  liquidations: [LiquidationEvent!]! @derivedFrom(field: "user")
}

type UserReserve @entity {
  id: ID! # user address + reserve address
  user: User!
  reserve: Reserve!

  # Balances
  currentATokenBalance: BigInt!
  currentVariableDebt: BigInt!

  # Scaled balances
  scaledATokenBalance: BigInt!
  scaledVariableDebt: BigInt!

  # Indexes at last update
  liquidityRate: BigInt!
  variableBorrowRate: BigInt!
  lastUpdateTimestamp: BigInt!

  # Usage as collateral
  usageAsCollateralEnabledOnUser: Boolean!
}

type SupplyEvent @entity {
  id: ID! # tx hash + log index
  user: User!
  reserve: Reserve!
  onBehalfOf: Bytes!
  amount: BigInt!
  referral: Int!
  timestamp: BigInt!
  txHash: Bytes!
}

type WithdrawEvent @entity {
  id: ID! # tx hash + log index
  user: User!
  reserve: Reserve!
  to: Bytes!
  amount: BigInt!
  timestamp: BigInt!
  txHash: Bytes!
}

type BorrowEvent @entity {
  id: ID! # tx hash + log index
  user: User!
  reserve: Reserve!
  onBehalfOf: Bytes!
  amount: BigInt!
  borrowRateMode: Int! # 1 = stable, 2 = variable
  borrowRate: BigInt!
  referral: Int!
  timestamp: BigInt!
  txHash: Bytes!
}

type RepayEvent @entity {
  id: ID! # tx hash + log index
  user: User!
  reserve: Reserve!
  repayer: Bytes!
  amount: BigInt!
  useATokens: Boolean!
  timestamp: BigInt!
  txHash: Bytes!
}

type LiquidationEvent @entity {
  id: ID! # tx hash + log index
  user: User!
  collateralReserve: Reserve!
  debtReserve: Reserve!
  debtToCover: BigInt!
  liquidatedCollateralAmount: BigInt!
  liquidator: Bytes!
  receiveAToken: Boolean!
  timestamp: BigInt!
  txHash: Bytes!
}

type PriceUpdate @entity {
  id: ID! # tx hash + log index
  asset: Bytes!
  price: BigInt!
  timestamp: BigInt!
  txHash: Bytes!
}

type Protocol @entity {
  id: ID! # "1"
  # Global metrics
  totalValueLockedUSD: BigInt!
  totalBorrowedUSD: BigInt!
  totalUsers: Int!
  totalSupplies: Int!
  totalBorrows: Int!
  totalRepays: Int!
  totalWithdraws: Int!
  totalLiquidations: Int!
}
```

---

## 3. src/mapping.ts

```typescript
import { BigInt, Address, Bytes } from "@graphprotocol/graph-ts";
import {
  Supply,
  Withdraw,
  Borrow,
  Repay,
  LiquidationCall,
  ReserveDataUpdated,
} from "../generated/Pool/Pool";
import { AssetPriceUpdated } from "../generated/AaveOracle/AaveOracle";
import {
  Reserve,
  User,
  UserReserve,
  SupplyEvent,
  WithdrawEvent,
  BorrowEvent,
  RepayEvent,
  LiquidationEvent,
  PriceUpdate,
  Protocol,
} from "../generated/schema";
import { AToken } from "../generated/Pool/AToken";
import { Pool } from "../generated/Pool/Pool";

// Constants
const POOL_ADDRESS = "0xf4438C3554d0360ECDe4358232821354e71C59e9";
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_BI = BigInt.fromI32(0);
const ONE_BI = BigInt.fromI32(1);

// Helper functions
function getOrCreateReserve(asset: Address): Reserve {
  let reserve = Reserve.load(asset.toHexString());

  if (reserve == null) {
    reserve = new Reserve(asset.toHexString());
    reserve.symbol = "";
    reserve.name = "";
    reserve.decimals = 18;
    reserve.totalLiquidity = ZERO_BI;
    reserve.availableLiquidity = ZERO_BI;
    reserve.totalSupplied = ZERO_BI;
    reserve.totalBorrowed = ZERO_BI;
    reserve.totalBorrowedVariable = ZERO_BI;
    reserve.liquidityRate = ZERO_BI;
    reserve.variableBorrowRate = ZERO_BI;
    reserve.liquidityIndex = ZERO_BI;
    reserve.variableBorrowIndex = ZERO_BI;
    reserve.priceInUSD = ZERO_BI;
    reserve.lastUpdateTimestamp = ZERO_BI;
    reserve.ltv = ZERO_BI;
    reserve.liquidationThreshold = ZERO_BI;
    reserve.liquidationBonus = ZERO_BI;
    reserve.reserveFactor = ZERO_BI;
    reserve.isActive = false;
    reserve.isFrozen = false;
    reserve.borrowingEnabled = false;
    reserve.usageAsCollateralEnabled = false;
    reserve.aTokenAddress = Bytes.fromHexString(ZERO_ADDRESS);
    reserve.variableDebtTokenAddress = Bytes.fromHexString(ZERO_ADDRESS);
    reserve.save();
  }

  return reserve;
}

function getOrCreateUser(address: Address): User {
  let user = User.load(address.toHexString());

  if (user == null) {
    user = new User(address.toHexString());
    user.totalSuppliedUSD = ZERO_BI;
    user.totalBorrowedUSD = ZERO_BI;
    user.totalCollateralUSD = ZERO_BI;
    user.healthFactor = ZERO_BI;
    user.save();

    // Update protocol user count
    let protocol = getOrCreateProtocol();
    protocol.totalUsers = protocol.totalUsers + 1;
    protocol.save();
  }

  return user;
}

function getOrCreateUserReserve(
  userAddress: Address,
  reserveAddress: Address
): UserReserve {
  let id = userAddress.toHexString() + "-" + reserveAddress.toHexString();
  let userReserve = UserReserve.load(id);

  if (userReserve == null) {
    userReserve = new UserReserve(id);
    userReserve.user = userAddress.toHexString();
    userReserve.reserve = reserveAddress.toHexString();
    userReserve.currentATokenBalance = ZERO_BI;
    userReserve.currentVariableDebt = ZERO_BI;
    userReserve.scaledATokenBalance = ZERO_BI;
    userReserve.scaledVariableDebt = ZERO_BI;
    userReserve.liquidityRate = ZERO_BI;
    userReserve.variableBorrowRate = ZERO_BI;
    userReserve.lastUpdateTimestamp = ZERO_BI;
    userReserve.usageAsCollateralEnabledOnUser = false;
    userReserve.save();
  }

  return userReserve;
}

function getOrCreateProtocol(): Protocol {
  let protocol = Protocol.load("1");

  if (protocol == null) {
    protocol = new Protocol("1");
    protocol.totalValueLockedUSD = ZERO_BI;
    protocol.totalBorrowedUSD = ZERO_BI;
    protocol.totalUsers = 0;
    protocol.totalSupplies = 0;
    protocol.totalBorrows = 0;
    protocol.totalRepays = 0;
    protocol.totalWithdraws = 0;
    protocol.totalLiquidations = 0;
    protocol.save();
  }

  return protocol;
}

// Event Handlers

export function handleSupply(event: Supply): void {
  let reserve = getOrCreateReserve(event.params.reserve);
  let user = getOrCreateUser(event.params.user);
  let userReserve = getOrCreateUserReserve(
    event.params.user,
    event.params.reserve
  );

  // Create supply event
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let supply = new SupplyEvent(id);
  supply.user = user.id;
  supply.reserve = reserve.id;
  supply.onBehalfOf = event.params.onBehalfOf;
  supply.amount = event.params.amount;
  supply.referral = event.params.referral;
  supply.timestamp = event.block.timestamp;
  supply.txHash = event.transaction.hash;
  supply.save();

  // Update user reserve balance
  let aTokenContract = AToken.bind(Address.fromBytes(reserve.aTokenAddress));
  let balanceResult = aTokenContract.try_balanceOf(event.params.user);
  if (!balanceResult.reverted) {
    userReserve.currentATokenBalance = balanceResult.value;
  }
  userReserve.lastUpdateTimestamp = event.block.timestamp;
  userReserve.save();

  // Update protocol stats
  let protocol = getOrCreateProtocol();
  protocol.totalSupplies = protocol.totalSupplies + 1;
  protocol.save();
}

export function handleWithdraw(event: Withdraw): void {
  let reserve = getOrCreateReserve(event.params.reserve);
  let user = getOrCreateUser(event.params.user);
  let userReserve = getOrCreateUserReserve(
    event.params.user,
    event.params.reserve
  );

  // Create withdraw event
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let withdraw = new WithdrawEvent(id);
  withdraw.user = user.id;
  withdraw.reserve = reserve.id;
  withdraw.to = event.params.to;
  withdraw.amount = event.params.amount;
  withdraw.timestamp = event.block.timestamp;
  withdraw.txHash = event.transaction.hash;
  withdraw.save();

  // Update user reserve balance
  let aTokenContract = AToken.bind(Address.fromBytes(reserve.aTokenAddress));
  let balanceResult = aTokenContract.try_balanceOf(event.params.user);
  if (!balanceResult.reverted) {
    userReserve.currentATokenBalance = balanceResult.value;
  }
  userReserve.lastUpdateTimestamp = event.block.timestamp;
  userReserve.save();

  // Update protocol stats
  let protocol = getOrCreateProtocol();
  protocol.totalWithdraws = protocol.totalWithdraws + 1;
  protocol.save();
}

export function handleBorrow(event: Borrow): void {
  let reserve = getOrCreateReserve(event.params.reserve);
  let user = getOrCreateUser(event.params.user);
  let userReserve = getOrCreateUserReserve(
    event.params.user,
    event.params.reserve
  );

  // Create borrow event
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let borrow = new BorrowEvent(id);
  borrow.user = user.id;
  borrow.reserve = reserve.id;
  borrow.onBehalfOf = event.params.onBehalfOf;
  borrow.amount = event.params.amount;
  borrow.borrowRateMode = event.params.interestRateMode;
  borrow.borrowRate = event.params.borrowRate;
  borrow.referral = event.params.referral;
  borrow.timestamp = event.block.timestamp;
  borrow.txHash = event.transaction.hash;
  borrow.save();

  // Update user reserve debt
  userReserve.currentVariableDebt = userReserve.currentVariableDebt.plus(
    event.params.amount
  );
  userReserve.lastUpdateTimestamp = event.block.timestamp;
  userReserve.save();

  // Update protocol stats
  let protocol = getOrCreateProtocol();
  protocol.totalBorrows = protocol.totalBorrows + 1;
  protocol.save();
}

export function handleRepay(event: Repay): void {
  let reserve = getOrCreateReserve(event.params.reserve);
  let user = getOrCreateUser(event.params.user);
  let userReserve = getOrCreateUserReserve(
    event.params.user,
    event.params.reserve
  );

  // Create repay event
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let repay = new RepayEvent(id);
  repay.user = user.id;
  repay.reserve = reserve.id;
  repay.repayer = event.params.repayer;
  repay.amount = event.params.amount;
  repay.useATokens = event.params.useATokens;
  repay.timestamp = event.block.timestamp;
  repay.txHash = event.transaction.hash;
  repay.save();

  // Update user reserve debt
  if (userReserve.currentVariableDebt.gt(event.params.amount)) {
    userReserve.currentVariableDebt = userReserve.currentVariableDebt.minus(
      event.params.amount
    );
  } else {
    userReserve.currentVariableDebt = ZERO_BI;
  }
  userReserve.lastUpdateTimestamp = event.block.timestamp;
  userReserve.save();

  // Update protocol stats
  let protocol = getOrCreateProtocol();
  protocol.totalRepays = protocol.totalRepays + 1;
  protocol.save();
}

export function handleLiquidationCall(event: LiquidationCall): void {
  let collateralReserve = getOrCreateReserve(event.params.collateralAsset);
  let debtReserve = getOrCreateReserve(event.params.debtAsset);
  let user = getOrCreateUser(event.params.user);

  // Create liquidation event
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let liquidation = new LiquidationEvent(id);
  liquidation.user = user.id;
  liquidation.collateralReserve = collateralReserve.id;
  liquidation.debtReserve = debtReserve.id;
  liquidation.debtToCover = event.params.debtToCover;
  liquidation.liquidatedCollateralAmount =
    event.params.liquidatedCollateralAmount;
  liquidation.liquidator = event.params.liquidator;
  liquidation.receiveAToken = event.params.receiveAToken;
  liquidation.timestamp = event.block.timestamp;
  liquidation.txHash = event.transaction.hash;
  liquidation.save();

  // Update protocol stats
  let protocol = getOrCreateProtocol();
  protocol.totalLiquidations = protocol.totalLiquidations + 1;
  protocol.save();
}

export function handleReserveDataUpdated(event: ReserveDataUpdated): void {
  let reserve = getOrCreateReserve(event.params.reserve);

  reserve.liquidityRate = event.params.liquidityRate;
  reserve.variableBorrowRate = event.params.variableBorrowRate;
  reserve.liquidityIndex = event.params.liquidityIndex;
  reserve.variableBorrowIndex = event.params.variableBorrowIndex;
  reserve.lastUpdateTimestamp = event.block.timestamp;
  reserve.save();
}

export function handleAssetPriceUpdated(event: AssetPriceUpdated): void {
  let reserve = getOrCreateReserve(event.params.asset);

  reserve.priceInUSD = event.params.price;
  reserve.lastUpdateTimestamp = event.block.timestamp;
  reserve.save();

  // Create price update event
  let id =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let priceUpdate = new PriceUpdate(id);
  priceUpdate.asset = event.params.asset;
  priceUpdate.price = event.params.price;
  priceUpdate.timestamp = event.block.timestamp;
  priceUpdate.txHash = event.transaction.hash;
  priceUpdate.save();
}
```

---

## 4. package.json

```json
{
  "name": "aave-v3-hyperevm-subgraph",
  "version": "1.0.0",
  "description": "Aave V3 subgraph for HyperEVM testnet",
  "scripts": {
    "codegen": "graph codegen",
    "build": "graph build",
    "deploy": "goldsky subgraph deploy aave-v3-hyperevm/v1.0.0 --path .",
    "create-local": "graph create --node http://localhost:8020/ aave-v3-hyperevm",
    "deploy-local": "graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 aave-v3-hyperevm"
  },
  "dependencies": {
    "@graphprotocol/graph-cli": "^0.56.0",
    "@graphprotocol/graph-ts": "^0.31.0"
  }
}
```

---

## 5. Export ABIs from Foundry

Run these commands in your Foundry project to extract the ABIs:

```bash
# Create abis directory in your subgraph folder
mkdir -p aave-v3-subgraph/abis

# Extract Pool ABI
jq '.abi' out/Pool.sol/Pool.json > aave-v3-subgraph/abis/Pool.json

# Extract AToken ABI
jq '.abi' out/AToken.sol/AToken.json > aave-v3-subgraph/abis/AToken.json

# Extract AaveOracle ABI
jq '.abi' out/AaveOracle.sol/AaveOracle.json > aave-v3-subgraph/abis/AaveOracle.json
```

---

## 6. Deployment Steps

### Install Goldsky CLI

```bash
npm install -g @goldsky/cli
```

### Login to Goldsky

```bash
goldsky login
```

### Install dependencies

```bash
cd aave-v3-subgraph
npm install
```

### Generate code from schema

```bash
npm run codegen
```

### Build the subgraph

```bash
npm run build
```

### Deploy to Goldsky

```bash
goldsky subgraph deploy aave-v3-hyperevm/v1.0.0 --path .
```

---

## 7. Important Notes

### Find Your Deployment Block

You need to replace `startBlock: 0` in `subgraph.yaml` with the actual block where you deployed your contracts. You can find this by:

```bash
cast block-number --rpc-url https://api.hyperliquid-testnet.xyz/evm
```

Or check the transaction hash from your deployment and get the block number.

### Network Configuration

If HyperEVM testnet is not yet supported by Goldsky, you may need to:

1. Contact Goldsky support to add HyperEVM testnet
2. Or deploy to Goldsky's "Instant Subgraphs" feature
3. Or use The Graph's hosted service if they support custom networks

### Testing Queries

Once deployed, you can query your subgraph:

```graphql
# Get all reserves
{
  reserves {
    id
    symbol
    totalSupplied
    totalBorrowed
    liquidityRate
    variableBorrowRate
  }
}

# Get user positions
{
  user(id: "0x9a6586c563d56899d2d84a6b22729870126f62fb") {
    totalSuppliedUSD
    totalBorrowedUSD
    reserves {
      reserve {
        symbol
      }
      currentATokenBalance
      currentVariableDebt
    }
  }
}

# Get recent supply events
{
  supplyEvents(first: 10, orderBy: timestamp, orderDirection: desc) {
    user {
      id
    }
    reserve {
      symbol
    }
    amount
    timestamp
  }
}
```

---

## 8. Next Steps

1. **Deploy the subgraph** following the steps above
2. **Test your queries** using the GraphQL playground
3. **Build a frontend** that consumes this data
4. **Add more data sources** as needed (e.g., PoolConfigurator events for config changes)
5. **Set up monitoring** for indexing health

Your Aave V3 deployment will now have a powerful indexing layer for querying historical data and building analytics dashboards!
