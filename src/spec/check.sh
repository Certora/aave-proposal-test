certoraRun src/PayloadCertoraProposal.sol src/imports/USDC/FiatTokenV2_1.sol src/imports/AaveTokenV2.sol \
    --verify PayloadCertoraProposal:src/spec/proposal.spec \
    --solc_map PayloadCertoraProposal=solc8.12,AaveTokenV2=solc7.5,FiatTokenV2_1=solc6.12