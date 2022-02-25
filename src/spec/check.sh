certoraRun src/PayloadCertoraProposal.sol src/imports/USDC/FiatTokenV2_1.sol src/imports/AaveTokenV2.sol \
    --verify PayloadCertoraProposal:src/spec/proposal.spec \
    --solc_map PayloadCertoraProposal=solc8.12,AaveTokenV2=solc7.5,FiatTokenV2_1=solc6.12 \
    --address AaveTokenV2:0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9 FiatTokenV2_1:0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 \
    --rule_sanity --cloud