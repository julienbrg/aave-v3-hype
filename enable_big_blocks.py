from hyperliquid.utils import constants
from hyperliquid.exchange import Exchange
from eth_account import Account

# Your private key - remove 0x if it has one
PRIVATE_KEY = "my_pk"

# Remove 0x prefix if present
if PRIVATE_KEY.startswith("0x"):
    PRIVATE_KEY = PRIVATE_KEY[2:]

# Initialize account
account = Account.from_key(PRIVATE_KEY)
print(f"Using address: {account.address}")

# Connect to TESTNET (important!)
exchange = Exchange(account, constants.TESTNET_API_URL)

# Enable big blocks
try:
    result = exchange.use_big_blocks(True)
    print("✅ Big blocks enabled successfully!")
    print(f"Result: {result}")
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
