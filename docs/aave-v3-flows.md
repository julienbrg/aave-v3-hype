# Aave V3 Protocol Flows

Complete documentation of the main user interactions with Aave V3 lending protocol.

---

## 1. 📥 User Lends (Supply)

### Entry Point

```solidity
Pool.supply(
    address asset,      // Token to supply (e.g., USDC)
    uint256 amount,     // Amount to supply
    address onBehalfOf, // Who receives aTokens (usually msg.sender)
    uint16 referralCode // Referral code (0 if none)
)
```

### Complete Flow

```
1. User approves tokens
   IERC20(asset).approve(pool, amount)
   ↓
2. User calls Pool.supply()
   ↓
3. ValidationLogic.validateSupply()
   - Check reserve is active
   - Check amount > 0
   - Check supply cap not exceeded
   ↓
4. ReserveLogic.updateState()
   - Accrue interest since last update
   - Update liquidity index
   - Update variable borrow index
   ↓
5. Transfer tokens to aToken contract
   IERC20(asset).transferFrom(user, aToken, amount)
   ↓
6. AToken.mint(onBehalfOf, amount, liquidityIndex)
   - Calculate scaled amount = amount / liquidityIndex
   - Update user's scaled balance
   ↓
7. ReserveLogic.updateInterestRates()
   - Calculate new utilization rate
   - Update liquidity rate
   - Update borrow rates
   ↓
8. Emit Supply event
```

### State Changes

| Before                  | After                            |
| ----------------------- | -------------------------------- |
| User Token Balance: X   | User Token Balance: X - amount   |
| User aToken Balance: Y  | User aToken Balance: Y + amount  |
| Pool Total Liquidity: L | Pool Total Liquidity: L + amount |

### Events Emitted

- `Supply(reserve, user, onBehalfOf, amount, referralCode)`
- `Transfer(address(0), onBehalfOf, amount)` [from AToken]
- `ReserveDataUpdated(reserve, liquidityRate, variableBorrowRate, ...)`

### Example

```solidity
// Supply 1000 USDC
usdc.approve(pool, 1000e6);
pool.supply(
    usdcAddress,
    1000e6,
    msg.sender,
    0
);
// Result: Receive 1000 aUSDC (grows with interest over time)
```

---

## 2. 💰 User Borrows

### Entry Point

```solidity
Pool.borrow(
    address asset,          // Token to borrow
    uint256 amount,         // Amount to borrow
    uint256 interestRateMode, // 2 = variable (stable deprecated)
    uint16 referralCode,    // Referral code
    address onBehalfOf      // Who receives the debt (usually msg.sender)
)
```

### Complete Flow

```
1. User calls Pool.borrow()
   ↓
2. ValidationLogic.validateBorrow()
   - Check reserve is active and borrowing enabled
   - Check user has sufficient collateral
   - Check amount doesn't exceed borrow cap
   - Check Health Factor > 1 after borrow
   ↓
3. ReserveLogic.updateState()
   - Accrue interest
   - Update indices
   ↓
4. VariableDebtToken.mint(onBehalfOf, amount, borrowIndex)
   - Calculate scaled debt = amount / borrowIndex
   - Update user's debt balance
   ↓
5. Transfer borrowed tokens to user
   IAToken(aToken).transferUnderlyingTo(user, amount)
   ↓
6. ReserveLogic.updateInterestRates()
   - Increase utilization rate
   - Increase borrow/supply rates
   ↓
7. Emit Borrow event
```

### Prerequisites

- User must have supplied collateral first
- Health Factor must remain > 1.0 after borrow
- Collateral value × LTV ≥ Borrow amount

### Health Factor Formula

```
Health Factor = (Collateral in ETH × Liquidation Threshold) / Total Debt in ETH

Example:
- Supplied: 1000 USDC ($1000)
- USDC Liquidation Threshold: 85%
- Borrowed: 600 USDC ($600)
- Health Factor = (1000 × 0.85) / 600 = 1.42 ✅ (Safe)
```

### State Changes

| Before                      | After                                |
| --------------------------- | ------------------------------------ |
| User Debt: D                | User Debt: D + amount                |
| User Token Balance: X       | User Token Balance: X + amount       |
| Pool Available Liquidity: L | Pool Available Liquidity: L - amount |
| Health Factor: HF1          | Health Factor: HF2 (lower)           |

### Events Emitted

- `Borrow(reserve, user, onBehalfOf, amount, interestRateMode, borrowRate, referral)`
- `Transfer(address(0), onBehalfOf, amount)` [from DebtToken]
- `ReserveDataUpdated(...)`

### Example

```solidity
// Already supplied 1000 USDC as collateral (LTV 80%)
// Can borrow up to 800 USDC

pool.borrow(
    usdcAddress,
    500e6,      // Borrow 500 USDC
    2,          // Variable rate
    0,
    msg.sender
);
// Result: Receive 500 USDC, owe 500 USDC + interest
```

---

## 3. 💸 User Repays

### Entry Point

```solidity
Pool.repay(
    address asset,      // Token to repay
    uint256 amount,     // Amount to repay (type(uint256).max for full)
    uint256 interestRateMode, // 2 = variable
    address onBehalfOf  // Whose debt to repay (usually msg.sender)
)
```

### Complete Flow

```
1. User approves tokens
   IERC20(asset).approve(pool, amount)
   ↓
2. User calls Pool.repay()
   ↓
3. ValidationLogic.validateRepay()
   - Check user has debt
   - Check amount <= debt
   ↓
4. ReserveLogic.updateState()
   - Accrue interest on debt
   - Update indices
   ↓
5. Calculate actual payback amount
   - If amount > debt, cap at total debt
   - Include accrued interest
   ↓
6. Transfer tokens from user to aToken
   IERC20(asset).transferFrom(user, aToken, paybackAmount)
   ↓
7. VariableDebtToken.burn(onBehalfOf, paybackAmount, borrowIndex)
   - Reduce user's debt balance
   ↓
8. ReserveLogic.updateInterestRates()
   - Decrease utilization
   - Lower borrow/supply rates
   ↓
9. Emit Repay event
```

### Full Repayment

```solidity
// Repay all debt (including accrued interest)
usdc.approve(pool, type(uint256).max);
pool.repay(
    usdcAddress,
    type(uint256).max,  // Magic value for "repay all"
    2,
    msg.sender
);
```

### State Changes

| Before                      | After                                |
| --------------------------- | ------------------------------------ |
| User Debt: D                | User Debt: D - amount                |
| User Token Balance: X       | User Token Balance: X - amount       |
| Pool Available Liquidity: L | Pool Available Liquidity: L + amount |
| Health Factor: HF1          | Health Factor: HF2 (higher)          |

### Events Emitted

- `Repay(reserve, user, repayer, amount, useATokens)`
- `Transfer(onBehalfOf, address(0), amount)` [from DebtToken]
- `ReserveDataUpdated(...)`

### Example

```solidity
// Borrowed 500 USDC, now owes 510 USDC with interest
usdc.approve(pool, 510e6);
pool.repay(
    usdcAddress,
    510e6,
    2,
    msg.sender
);
// Result: Debt cleared, Health Factor improved
```

---

## 4. 🏧 User Withdraws

### Entry Point

```solidity
Pool.withdraw(
    address asset,      // Token to withdraw
    uint256 amount,     // Amount to withdraw (type(uint256).max for all)
    address to          // Recipient address
)
```

### Complete Flow

```
1. User calls Pool.withdraw()
   ↓
2. ValidationLogic.validateWithdraw()
   - Check user has supplied balance
   - Check amount <= available balance
   - If user has debt: check Health Factor > 1 after withdrawal
   ↓
3. ReserveLogic.updateState()
   - Accrue interest
   - Update indices
   ↓
4. AToken.burn(user, to, amount, liquidityIndex)
   - Reduce user's aToken balance
   - Transfer underlying tokens to recipient
   ↓
5. Check Health Factor (if user has debt)
   - Ensure HF > 1.0 after withdrawal
   - Revert if would cause liquidation
   ↓
6. ReserveLogic.updateInterestRates()
   - Increase utilization (less liquidity)
   - Adjust rates accordingly
   ↓
7. Emit Withdraw event
```

### Withdrawal Limits

- **No Debt**: Can withdraw 100% of supplied amount + interest
- **Has Debt**: Can only withdraw if Health Factor remains > 1.0

### Calculation Example

```
Supplied: 1000 USDC (now worth 1050 with interest)
Borrowed: 600 USDC
LTV: 80%, Liquidation Threshold: 85%

Max Withdrawal Calculation:
- Required Collateral = 600 / 0.85 = 705.88 USDC
- Can Withdraw = 1050 - 705.88 = 344.12 USDC
```

### State Changes

| Before                  | After                                  |
| ----------------------- | -------------------------------------- |
| User aToken Balance: A  | User aToken Balance: A - amount        |
| User Token Balance: X   | User Token Balance: X + amount         |
| Pool Total Liquidity: L | Pool Total Liquidity: L - amount       |
| Health Factor: HF1      | Health Factor: HF2 (lower if has debt) |

### Events Emitted

- `Withdraw(reserve, user, to, amount)`
- `Transfer(user, address(0), amount)` [from AToken]
- `ReserveDataUpdated(...)`

### Example

```solidity
// Withdraw 200 USDC from supply
pool.withdraw(
    usdcAddress,
    200e6,
    msg.sender
);
// Result: Receive 200 USDC, aToken balance reduced

// Withdraw ALL supplied USDC
pool.withdraw(
    usdcAddress,
    type(uint256).max,
    msg.sender
);
```

---

## 5. ⚡ Liquidation

### Entry Point

```solidity
Pool.liquidationCall(
    address collateralAsset,  // Collateral to seize
    address debtAsset,        // Debt to repay
    address user,             // User being liquidated
    uint256 debtToCover,      // Amount of debt to repay
    bool receiveAToken        // Receive aToken or underlying
)
```

### When Can Liquidation Occur?

```
Health Factor < 1.0

Health Factor = (Total Collateral × Liquidation Threshold) / Total Debt

Example triggering liquidation:
- Collateral: 1000 USDC ($1000), threshold 85%
- Debt: 900 USDC ($900)
- HF = (1000 × 0.85) / 900 = 0.944 < 1.0 ❌ LIQUIDATABLE
```

### Complete Flow

```
1. Liquidator calls Pool.liquidationCall()
   ↓
2. ValidationLogic.validateLiquidationCall()
   - Check user's Health Factor < 1.0
   - Check liquidator has debt tokens
   - Check debtToCover <= 50% of user's debt (if HF < 0.95)
   ↓
3. ReserveLogic.updateState() [for both assets]
   - Update collateral reserve
   - Update debt reserve
   ↓
4. Calculate liquidation amounts
   maxDebtToCover = min(debtToCover, userDebt × 0.5)
   collateralToSeize = debtToCover × liquidationBonus
   ↓
5. Transfer debt tokens from liquidator
   IERC20(debtAsset).transferFrom(liquidator, aToken, debtToCover)
   ↓
6. Burn user's debt
   DebtToken.burn(user, debtToCover, borrowIndex)
   ↓
7. Transfer collateral to liquidator
   If receiveAToken:
     aToken.transferFrom(user, liquidator, collateralToSeize)
   Else:
     aToken.burn(user, liquidator, collateralToSeize, index)
   ↓
8. Update interest rates for both reserves
   ↓
9. Emit LiquidationCall event
```

### Liquidation Bonus

Liquidators receive a bonus (typically 5-10%) as incentive:

```
Example:
- User debt: 900 USDC
- Liquidation bonus: 5%
- Liquidator repays: 450 USDC (50% max)
- Liquidator receives: 450 × 1.05 = 472.50 USDC worth of collateral
- Liquidator profit: 22.50 USDC
```

### Liquidation Limits

| Health Factor    | Max Liquidation                 |
| ---------------- | ------------------------------- |
| < 0.95           | 50% of debt                     |
| < 1.0 but ≥ 0.95 | 100% of debt (full liquidation) |

### State Changes

| Entity                 | Before | After                |
| ---------------------- | ------ | -------------------- |
| User Debt              | D      | D - debtToCover      |
| User Collateral        | C      | C - collateralSeized |
| User Health Factor     | <1.0   | >1.0 (ideally)       |
| Liquidator Debt Tokens | X      | X - debtToCover      |
| Liquidator Collateral  | Y      | Y + collateralSeized |

### Events Emitted

- `LiquidationCall(collateral, debt, user, debtToCover, collateralSeized, liquidator, receiveAToken)`
- `Repay(...)` [for debt repayment]
- `Transfer(...)` [for collateral transfer]
- `ReserveDataUpdated(...)` [for both reserves]

### Example Liquidation

```solidity
// User's position:
// - Collateral: 1000 USDC ($1000)
// - Debt: 900 USDC ($900)
// - Liquidation threshold: 85%
// - Health Factor: 0.944 < 1.0 ❌

// Liquidator action:
usdc.approve(pool, 450e6);
pool.liquidationCall(
    usdcAddress,        // collateral
    usdcAddress,        // debt
    userAddress,        // user to liquidate
    450e6,              // repay 450 USDC (50% of debt)
    false               // receive underlying USDC
);

// Result:
// - Liquidator pays: 450 USDC
// - Liquidator receives: 472.50 USDC (with 5% bonus)
// - Liquidator profit: 22.50 USDC
// - User's new debt: 450 USDC
// - User's new HF: ~1.89 ✅ (safe again)
```

---

## Summary Table

| Action        | Main Function       | Prerequisites                                                 | Result                               |
| ------------- | ------------------- | ------------------------------------------------------------- | ------------------------------------ |
| **Supply**    | `supply()`          | - Token approval                                              | Receive aTokens, earn interest       |
| **Borrow**    | `borrow()`          | - Collateral supplied<br>- HF > 1 after borrow                | Receive tokens, accrue debt          |
| **Repay**     | `repay()`           | - Token approval<br>- Active debt                             | Reduce/clear debt, improve HF        |
| **Withdraw**  | `withdraw()`        | - Supplied balance<br>- HF > 1 after withdrawal (if has debt) | Receive tokens, reduce supply        |
| **Liquidate** | `liquidationCall()` | - Target HF < 1<br>- Token approval                           | Repay debt, seize collateral + bonus |

---

## Important Notes

### Interest Accrual

All operations trigger `updateState()` which:

- Accrues interest since last interaction
- Updates liquidity and borrow indices
- Recalculates rates based on new utilization

### Gas Optimization

- Use `type(uint256).max` to repay/withdraw all (saves gas on calculation)
- Batch operations when possible
- Monitor gas prices for liquidations

### Safety Checks

- Always maintain Health Factor > 1.0 when borrowing/withdrawing
- Monitor your positions regularly
- Set up alerts for HF thresholds
- Consider partial repayments to improve HF

### Your HyperEVM Deployment

All these functions are available on your deployment:

- Pool: `0xf4438C3554d0360ECDe4358232821354e71C59e9`
- USDC: `0xDF1B2c6007D810FaCBD84686C6e27CE03C2C4056`
- Network: HyperEVM Testnet (Chain ID: 998)
