using FiatTokenV2_1 as usdc
using AaveTokenV2 as aave

methods {
    convertUSDCAmountToAAVE(uint256 usdcAmount) returns uint256 envfree
    decimals() returns uint8 => DISPATCHER(true)
    usdc.decimals() returns uint8 envfree
    aave.decimals() returns uint8 envfree
}

rule conversionAdditive(uint amt1, uint amt2) {
    require amt1 + amt2 <= max_uint256;
    require usdc.decimals() == 6;
    require aave.decimals() == 18;
    uint sumOfConversions = convertUSDCAmountToAAVE(amt1) + convertUSDCAmountToAAVE(amt2);
    uint conversionOfSum = convertUSDCAmountToAAVE(amt1 + amt2);
    uint delta = 1;
    assert sumOfConversions - delta <= conversionOfSum && conversionOfSum <= sumOfConversions + delta;
} 

rule conversionAdditivePrecise(uint amt1, uint amt2) {
    require amt1 + amt2 <= max_uint256;
    require usdc.decimals() == 6;
    require aave.decimals() == 18;
    uint sumOfConversions = convertUSDCAmountToAAVE(amt1) + convertUSDCAmountToAAVE(amt2);
    uint conversionOfSum = convertUSDCAmountToAAVE(amt1 + amt2);
    assert sumOfConversions == conversionOfSum;
} 


/*
invariant decimlasUSDC() usdc.decimals() == 6
invariant decimalsAAVE() aave.decimals() == 18
*/