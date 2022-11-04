// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibPropConstants} from "./LibPropConstants.sol";
import {IERC20} from "./IERC20.sol";

interface IStreamable {
    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function withdrawFromStream(uint256 streamId, uint256 funds)
        external
        returns (bool);

    function getNextStreamId() external view returns (uint256);
}

interface IAaveEcosystemReserveController {
    /**
     * @notice Proxy function for ERC20's approve(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Allowance's recipient
     * @param amount Allowance to approve
     **/
    function approve(
        address collector,
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Proxy function for ERC20's transfer(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Transfer's recipient
     * @param amount Amount to transfer
     **/
    function transfer(
        address collector,
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Proxy function to create a stream of token on a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param recipient The recipient of the stream of token
     * @param deposit Total amount to be streamed
     * @param tokenAddress The ERC20 token to use as streaming asset
     * @param startTime The unix timestamp for when the stream starts
     * @param stopTime The unix timestamp for when the stream stops
     * @return uint256 The stream id created
     **/
    function createStream(
        address collector,
        address recipient,
        uint256 deposit,
        IERC20 tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256);

    /**
     * @notice Proxy function to withdraw from a stream of token on a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param streamId The id of the stream to withdraw tokens from
     * @param funds Amount to withdraw
     * @return bool If the withdrawal finished properly
     **/
    function withdrawFromStream(
        address collector,
        uint256 streamId,
        uint256 funds
    ) external returns (bool);

    /**
     * @notice Proxy function to cancel a stream of token on a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param streamId The id of the stream to cancel
     * @return bool If the cancellation happened correctly
     **/
    function cancelStream(address collector, uint256 streamId)
        external
        returns (bool);
}

interface ICollector {
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PayloadCertoraProposal {
    // Return the price of AAVE in USDC using the Oracle's decimals, and the decimals used
    function getPriceOfAAVEinUSDC() public view returns (uint256, uint8) {
        AggregatorV3Interface oracle = AggregatorV3Interface(
            LibPropConstants.AAVE_USD_CHAINLINK_ORACLE
        );
        (, int256 aavePrice, uint256 startedAt, , ) = oracle.latestRoundData();
        uint256 freshTime = 3 * /* days */
            24 * /* hours */
            60 * /* minutes */
            60; /* seconds */ // using "days" leads to "Expected primary expression" error
        require(startedAt > block.timestamp - freshTime, "price is not fresh");
        require(aavePrice > 0, "aave price must be positive");

        uint8 priceDecimals = oracle.decimals();
        return (uint256(aavePrice), priceDecimals);
    }

    // formally verify me please :-)
    function convertUSDCAmountToAAVE(uint256 usdcAmount)
        public
        view
        returns (uint256)
    {
        uint8 usdcDecimals = IERC20(LibPropConstants.USDC_TOKEN).decimals();
        uint8 aaveDecimals = IERC20(LibPropConstants.AAVE_TOKEN).decimals();

        (uint256 aavePrice, uint8 priceDecimals) = getPriceOfAAVEinUSDC();

        /**
            aave_amount = ((usdcAmount / 10**usdcDecimals) * 10**aaveDecimals )/  (aavePrice / 10**oracleDecimals )
         */
        uint256 aaveAmount = (usdcAmount *
            10**priceDecimals *
            10**aaveDecimals) / (aavePrice * 10**usdcDecimals);
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
