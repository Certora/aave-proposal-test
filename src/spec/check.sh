certoraRun src/PayloadCertoraProposal.sol src/imports/USDC/FiatTokenV2_1.sol src/imports/AaveTokenV2.sol src/spec/ChainlinkHarness.sol \
    --verify PayloadCertoraProposal:src/spec/proposal.spec \
    --solc_map PayloadCertoraProposal=solc8.12,AaveTokenV2=solc7.5,FiatTokenV2_1=solc6.12,ChainlinkHarness=solc8.12 \
    --address AaveTokenV2:0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9 FiatTokenV2_1:0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 ChainlinkHarness:0x547a514d5e3769680Ce22B2361c10Ea13619e8a9 \
    --rule_sanity --cloud