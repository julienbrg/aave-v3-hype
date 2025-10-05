# Récap - Déploiement Aave V3 sur HyperEVM Testnet

## Adresses des contrats déployés

### Infrastructure Core Aave

```
PoolAddressesProvider:     0x3097BDC98DCCC8B8b56E478972a645705E756785
ACLManager:                0x96FB5950755e25F4e1CBFA994698345738e705a2
Pool (Proxy):              0xf4438C3554d0360ECDe4358232821354e71C59e9
Pool (Implementation):     0xe9509119aEF8e40B58D5607A63042C9dAF6aA8dc
PoolConfigurator (Proxy):  0x26A91A34a033d414EDB461fDFBA275e5dcCbB972
PoolConfigurator (Impl):   0x71D3e5Ef02440E2D39D6142f75EAAB921EA070DB
AaveOracle:                0xd215fdfE86E9836a80E2ab2c2DF52dd0AdDaacDe
AaveProtocolDataProvider:  0x4002F5C8aab325C22874963c61625A65D08744DC
DefaultInterestRateStrategy: 0xDbA07E77C393662e0628a25642D511e60ca9f90A
```

### Token Implementations

```
AToken Implementation:           0x2DE2C76e35c2202eAf7e98db214618caC3eda1a3
VariableDebtToken Implementation: 0xcDE6e1df7751Dc95B55014f2b678b0F563cc42dD
```

### Assets & Tokens

```
Mock USDC:                 0xDF1B2c6007D810FaCBD84686C6e27CE03C2C4056
aHypUSDC (aToken Proxy):   0x052650F4173d7f1252E82b94ccD0Ea0a21Bb6a98
variableDebtHypUSDC:       0x1DC1c40FeB8B363B21B8815Ef7377E929A33C199
MockPriceOracle (USDC):    [Déployé lors de ConfigureUSDC]
```

### Votre adresse

```
Deployer/User: 0x9a6586c563D56899d2d84a6b22729870126f62Fb
```

---

## Étapes accomplies

### 1. Setup initial

- Activé big blocks sur HyperEVM pour le déploiement
- Obtenu HYPE pour le gas via Arbitrum bridge

### 2. Déploiement infrastructure (DeployHyperEVM.s.sol)

- Déployé PoolAddressesProvider
- Configuré ACLManager
- Déployé Pool + PoolConfigurator (avec proxies)
- Déployé Oracle et DataProvider
- Déployé stratégie de taux d'intérêt par défaut
- Accordé les rôles admin

### 3. Déploiement Mock USDC (DeployMockUSDC.s.sol)

- Créé un ERC20 avec 6 décimales (changé à 18 finalement)
- Minté 1,000,000 USDC pour tests

### 4. Déploiement Token Implementations (DeployTokenImplementations.s.sol)

- Déployé ATokenInstance (pour représenter les dépôts)
- Déployé VariableDebtTokenInstance (pour représenter les emprunts)

### 5. Configuration USDC dans Aave (ConfigureUSDC.s.sol)

- Initialisé la réserve USDC avec:
  - Implémentations aToken et debtToken
  - Paramètres de taux: 90% utilisation optimale, 0% base rate, 4% slope1, 60% slope2
- Configuré comme collatéral: 80% LTV, 85% liquidation threshold, 5% bonus
- Activé l'emprunt
- Défini reserve factor à 10%
- Activé la réserve
- Déployé et configuré oracle de prix ($1.00)

### 6. Test Supply (SupplyUSDC.s.sol)

- Approuvé 1000 USDC au Pool
- Déposé 1000 USDC
- Reçu 1000 aHypUSDC en retour

---

## Configuration USDC finale

**Paramètres de collatéral:**

- LTV: 80% (peut emprunter jusqu'à 80% de la valeur déposée)
- Liquidation Threshold: 85% (liquidé si dette > 85% du collatéral)
- Liquidation Bonus: 5% (liquidateur reçoit 5% de bonus)

**Paramètres de taux d'intérêt:**

- Utilisation optimale: 90%
- Taux de base: 0%
- Pente 1 (0-90%): 4%
- Pente 2 (90-100%): 60%

**État actuel:**

- Vous avez déposé: 1000 USDC
- Vous possédez: 1000 aHypUSDC (génère des intérêts)
- Prix oracle: $1.00

---

## Scripts créés

1. `scripts/DeployHyperEVM.s.sol` - Infrastructure Aave
2. `src/MockUSDC.sol` + `scripts/DeployMockUSDC.s.sol` - Token de test
3. `scripts/DeployTokenImplementations.s.sol` - Implémentations aToken/debtToken
4. `scripts/ConfigureUSDC.s.sol` - Configuration complète USDC
5. `scripts/SupplyUSDC.s.sol` - Test de dépôt

Votre pool Aave V3 est maintenant fonctionnel sur HyperEVM testnet avec USDC comme premier asset.
