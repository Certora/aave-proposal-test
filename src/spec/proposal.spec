using FiatTokenV2_1 as usdc
using AaveTokenV2 as aave
using ChainlinkHarness as oracle

methods {
    convertUSDCAmountToAAVE(uint256 usdcAmount) returns uint256
    decimals() returns uint8 => DISPATCHER(true)
    usdc.decimals() returns uint8 envfree
    aave.decimals() returns uint8 envfree
    oracle.decimals() returns uint8 envfree
}

function oracleAssumptions() {
    require oracle.decimals() <= 27;
}

rule sanity(method f) {
    oracleAssumptions();
    env e;
    calldataarg arg;
    f(e,arg);
    assert false;
}

rule conversionAdditive(uint amt1, uint amt2) {
    oracleAssumptions();
    env e;
    require amt1 + amt2 <= max_uint256;
    require usdc.decimals() == 6;
    require aave.decimals() == 18;
    uint sumOfConversions = convertUSDCAmountToAAVE(e, amt1) + convertUSDCAmountToAAVE(e, amt2);
    uint conversionOfSum = convertUSDCAmountToAAVE(e, amt1 + amt2);
    uint delta = 1;
    assert sumOfConversions - delta <= conversionOfSum && conversionOfSum <= sumOfConversions + delta;
} 

rule conversionAdditivePrecise(uint amt1, uint amt2) {
    oracleAssumptions();
    env e;
    require amt1 + amt2 <= max_uint256;
    require usdc.decimals() == 6;
    require aave.decimals() == 18;
    uint sumOfConversions = convertUSDCAmountToAAVE(e, amt1) + convertUSDCAmountToAAVE(e, amt2);
    uint conversionOfSum = convertUSDCAmountToAAVE(e, amt1 + amt2);
    assert sumOfConversions == conversionOfSum;
} 


/*
invariant decimlasUSDC() usdc.decimals() == 6
invariant decimalsAAVE() aave.decimals() == 18
*/