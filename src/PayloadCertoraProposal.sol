// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {LibPropConstants} from "./LibPropConstants.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals()
        external
        view
        returns (uint8);
}

interface IControllerAaveEcosystemReserve {
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}

interface ISablier {
    function createStream(
        address recipient, 
        uint256 deposit, 
        address tokenAddress, 
        uint256 startTime, 
        uint256 stopTime
    ) external returns (uint256);
}

interface ICollector {
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}


contract PayloadCertoraProposal {


    // formally verify me please :-)
    function convertUSDCAmountToAAVE(uint256 usdcAmount) internal view returns (uint256) {
        uint8 usdcDecimals = IERC20(LibPropConstants.USDC_TOKEN).decimals();
        uint8 aaveDecimals = IERC20(LibPropConstants.AAVE_TOKEN_PROXY).decimals();

        /**
            aave_amount = (usdcAmount / price) * aaveDecimals / usdcDecimals
         */
        uint256 aaveAmount = usdcAmount * 10**LibPropConstants.AAVE_PRICE_DECIMALS * aaveDecimals 
                                / (LibPropConstants.AAVE_PRICE_USDC_6_DECIMALS * usdcDecimals);
        return aaveAmount;
    }

    function execute() external {
        uint256 totalAaveAmount = convertUSDCAmountToAAVE(
                LibPropConstants.AAVE_VEST_USDC_WORTH + LibPropConstants.AAVE_FUND_USDC_WORTH
            );
        uint256 vestAaveAmount = convertUSDCAmountToAAVE(LibPropConstants.AAVE_VEST_USDC_WORTH);
        uint256 fundAaveAmount = convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH);
        require (totalAaveAmount - 1 <= vestAaveAmount + fundAaveAmount && vestAaveAmount + fundAaveAmount <= totalAaveAmount + 1, "not addditive");

        /**
            1. Transfer a total worth of $900,000 in AAVE tokens from the EcosystemReserve to the ShortExecutor using the Ecosystem Reserve Controller contract at 0x1E506cbb6721B83B1549fa1558332381Ffa61A93.
        */
        IControllerAaveEcosystemReserve(LibPropConstants.ECOSYSTEM_RESERVE_CONTROLLER).transfer(
            IERC20(LibPropConstants.AAVE_TOKEN_PROXY),
            LibPropConstants.SHORT_EXECUTOR,
            totalAaveAmount
        );

        /**
            2. Approve $700,000 worth of AAVE tokens to Sablier.
         */
        IERC20(AAVE_TOKEN_PROXY).approve(LibPropConstants.SABLIER, vestAaveAmount);

        /**
            3. Create a Sablier stream with Certora as the beneficiary, to stream the $700,000 worth of Aave over 6 months.
         */
        uint currentTime = block.timestamp;
        ISablier(LibPropConstants.SABLIER).createStream(
            LibPropConstants.CERTORA_BENEFICIARY, 
            vestAaveAmount, 
            LibPropConstants.AAVE_TOKEN_PROXY, 
            currentTime, 
            currentTime + 6*30 days
        );

        /**
            4. Transfer $200,000 worth of AAVE to a multisig co-controlled by Aave and Certora teams.
         */
        IERC20(LibPropConstants.AAVE_TOKEN_PROXY).transfer(LibPropConstants.CERTORA_AAVE_MULTISIG, fundAaveAmount);

        /**
            5. Transfer USDC 1,420,000 from the Aave Collector to the ShortExecutor (exact mechanism TBD).
         */
        ICollector(LibPropConstants.AAVE_COLLECTOR).transfer(
            IERC20(LibPropConstants.USDC_TOKEN),
            LibPropConstants.SHORT_EXECUTOR,
            LibPropConstants.USDC_V3 + LibPropConstants.USDC_VEST
        );

        /**
            6. Transfer USDC 420,000 directly to Certora.
         */
        IERC20(LibPropConstants.USDC_TOKEN).transfer(LibPropConstants.CERTORA_BENEFICIARY, LibPropConstants.USDC_V3);

        /**
            7. Approve USDC 1,000,000 to Sablier.
         */
         IERC20(LibPropConstants.USDC_TOKEN).approve(LibPropConstants.SABLIER, LibPropConstants.USDC_VEST);
        
        /**
            8. Create a Sablier stream with Certora as the beneficiary, to stream the USDC 1,000,000 over 6 months.
         */
        ISablier(LibPropConstants.SABLIER).createStream(
            LibPropConstants.CERTORA_BENEFICIARY, 
            LibPropConstants.USDC_VEST, 
            LibPropConstants.USDC_TOKEN, 
            currentTime, 
            currentTime + 6*30 days
        );

    }
}
