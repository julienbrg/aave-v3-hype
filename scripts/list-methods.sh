#!/bin/bash

echo "📋 Extracting all methods from deployed contracts..."
echo ""

# Get unique contract names from all deployment files
CONTRACTS=$(find broadcast -name "run-latest.json" -exec jq -r '.transactions[] | select(.contractName != null) | .contractName' {} \; | sort -u)

for contract in $CONTRACTS; do
    echo "================================================"
    echo "📦 $contract"
    echo "================================================"

    # Find the contract's ABI file
    ABI_FILE=$(find out -name "$contract.json" -type f | head -n 1)

    if [ -z "$ABI_FILE" ]; then
        echo "⚠️  ABI not found for $contract"
        echo ""
        continue
    fi

    # Get deployed address
    ADDRESS=$(find broadcast -name "run-latest.json" -exec jq -r ".transactions[] | select(.contractName == \"$contract\") | .contractAddress" {} \; | head -n 1)
    if [ ! -z "$ADDRESS" ]; then
        echo "📍 Address: $ADDRESS"
        echo ""
    fi

    echo "🔧 Functions:"
    jq -r '.abi[] | select(.type == "function") |
        "  • \(.name)(\([.inputs[] | .type] | join(", "))) → \([.outputs[] | .type] | join(", "))"
        ' "$ABI_FILE" | sort

    echo ""
    echo "📢 Events:"
    jq -r '.abi[] | select(.type == "event") |
        "  • \(.name)(\([.inputs[] | .type] | join(", ")))"
        ' "$ABI_FILE" | sort

    echo ""
done

echo "✅ Done!"
