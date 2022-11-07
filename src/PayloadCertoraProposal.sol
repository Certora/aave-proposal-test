// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibPropConstants} from "./LibPropConstants.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IStreamable} from "./interfaces/IStreamable.sol";
import {IAaveEcosystemReserveController} from "./interfaces/IAaveEcosystemReserveController.sol";
import {ICollector} from "./interfaces/ICollector.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

contract PayloadCertoraProposal {

    // formally verify me please :-)
    function convertUSDCAmountToAAVE(uint256 usdcAmount)
        public
        view
        returns (uint256)
    {
        uint256 aaveDecimals = IERC20(LibPropConstants.AAVE_TOKEN).decimals();
        uint256 aaveAmount = usdcAmount / LibPropConstants.AAVE_AVG_PRICE_30D_USDC * 
            10**aaveDecimals;
        return aaveAmount;
    }

    // LO: Consider using address(this) instead of SHORT_EXECUTOR - changed
    function execute() external {
        uint256 totalAaveAmount = convertUSDCAmountToAAVE(
            LibPropConstants.AAVE_VEST_USDC_WORTH
        );
        uint256 vestAaveAmount = convertUSDCAmountToAAVE(
            LibPropConstants.AAVE_VEST_USDC_WORTH
        );
        require(
            totalAaveAmount - 1 <= vestAaveAmount &&
                vestAaveAmount <= totalAaveAmount + 1,
            "not addditive"
        );

        /**
            1. Create a stream with Certora as the beneficiary, to stream the USDC worth of Aave over the defined period of vesting.
         */
        uint256 currentTime = block.timestamp;
        uint256 duration = LibPropConstants.DURATION;
        uint256 actualAmount = (vestAaveAmount / duration) * duration; // rounding
        require(
            vestAaveAmount - actualAmount < 1e18,
            "losing more than 1 AAVE due to rounding"
        );
        uint256 streamIdAaveVest = IAaveEcosystemReserveController(
            LibPropConstants.STREAMER
        ).createStream(
                LibPropConstants.ECOSYSTEM_RESERVE,
                LibPropConstants.CERTORA_BENEFICIARY,
                actualAmount,
                IERC20(LibPropConstants.AAVE_TOKEN),
                currentTime,
                currentTime + duration
            );
        require(streamIdAaveVest > 0, "invalid stream id");

        /**
            2. Create a stream with Certora as the beneficiary, to stream the aUSDC amount over the period of vesting.
         */
        uint256 totalUSDCAmount = LibPropConstants.USDC_VEST;
        actualAmount = (totalUSDCAmount / duration) * duration; // rounding
        require(
            totalUSDCAmount - actualAmount < 10e6,
            "losing more than 10 USDC due to rounding"
        );
        uint256 streamIdUSDCVest = IAaveEcosystemReserveController(
            LibPropConstants.STREAMER
        ).createStream(
                LibPropConstants.AAVE_COLLECTOR,
                LibPropConstants.CERTORA_BENEFICIARY,
                actualAmount,
                IERC20(LibPropConstants.AUSDC_TOKEN),
                currentTime,
                currentTime + duration
            );
        require(streamIdUSDCVest > 0, "invalid stream id");
    }
}
