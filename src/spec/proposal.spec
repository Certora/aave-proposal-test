methods {
    convertUSDCAmountToAAVE(uint256 usdcAmount) returns uint256 envfree
    decimals() returns uint8 => DISPATCHER(true)
}

rule conversionAdditive(uint amt1, uint amt2) {
    require amt1 + amt2 <= max_uint256;
    assert convertUSDCAmountToAAVE(amt1) + convertUSDCAmountToAAVE(amt2) == convertUSDCAmountToAAVE(amt1 + amt2);
} 