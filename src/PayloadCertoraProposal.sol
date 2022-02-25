// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LibPropConstants} from "./LibPropConstants.sol";
import {IERC20} from "./IERC20.sol";
//import "./test/utils/console.sol";

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

interface IPool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract PayloadCertoraProposal {


    // formally verify me please :-)
    function convertUSDCAmountToAAVE(uint256 usdcAmount) public view returns (uint256) {
        uint8 usdcDecimals = IERC20(LibPropConstants.USDC_TOKEN).decimals();
        uint8 aaveDecimals = IERC20(LibPropConstants.AAVE_TOKEN).decimals();

        /**
            aave_amount = (usdcAmount / price) * aaveDecimals / usdcDecimals
         */
        uint256 aaveAmount = usdcAmount * 10**LibPropConstants.AAVE_PRICE_DECIMALS * 10**aaveDecimals 
                                / (LibPropConstants.AAVE_PRICE_USDC_6_DECIMALS * 10**usdcDecimals);
        return aaveAmount;
    }


    // LO: Consider using address(this) instead of SHORT_EXECUTOR - changed
    function execute() external {
        uint256 totalAaveAmount = convertUSDCAmountToAAVE(
                LibPropConstants.AAVE_VEST_USDC_WORTH + LibPropConstants.AAVE_FUND_USDC_WORTH
            );
        uint256 vestAaveAmount = convertUSDCAmountToAAVE(LibPropConstants.AAVE_VEST_USDC_WORTH);
        uint256 fundAaveAmount = convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH);
        require (totalAaveAmount - 1 <= vestAaveAmount + fundAaveAmount && vestAaveAmount + fundAaveAmount <= totalAaveAmount + 1, "not addditive");

        /**
            1. Transfer a total worth of $900,000 in AAVE tokens from the EcosystemReserve to the 
            ShortExecutor using the Ecosystem Reserve Controller contract at 0x1E506cbb6721B83B1549fa1558332381Ffa61A93.
        */
        IControllerAaveEcosystemReserve(LibPropConstants.ECOSYSTEM_RESERVE_CONTROLLER).transfer(
            IERC20(LibPropConstants.AAVE_TOKEN),
            address(this),
            totalAaveAmount
        );

        /**
            2. Approve $700,000 worth of AAVE tokens to Sablier. Future allowances should increment this to not override this vesting.
         */
        require(IERC20(LibPropConstants.AAVE_TOKEN).allowance(address(this), LibPropConstants.SABLIER) == 0, "Allowance to sablier is not zero");
        IERC20(LibPropConstants.AAVE_TOKEN).approve(LibPropConstants.SABLIER, vestAaveAmount);

        /**
            3. Create a Sablier stream with Certora as the beneficiary, to stream the $700,000 worth of Aave over 6 months.
         */
        uint currentTime = block.timestamp;
        uint duration = 6 * 30 days;
        uint actualAmount = (vestAaveAmount / duration) * duration; // rounding
        //console.logUint(vestAaveAmount-actualAmount); // 9935957
        require(vestAaveAmount - actualAmount < 1e18, "losing more than 1 AAVE due to rounding");
        uint streamIdAaveVest = ISablier(LibPropConstants.SABLIER).createStream(
            LibPropConstants.CERTORA_BENEFICIARY,
            actualAmount,
            LibPropConstants.AAVE_TOKEN,
            currentTime,
            currentTime + duration
        );
        require (streamIdAaveVest > 0, "invalid stream id");

        /**
            4. Transfer $200,000 worth of AAVE to a multisig co-controlled by Aave and Certora teams.
         */
        //IERC20(LibPropConstants.AAVE_TOKEN).transfer(LibPropConstants.CERTORA_AAVE_MULTISIG, fundAaveAmount); // xxx

        /**
            5. Transfer USDC 1,420,000 from the Aave Collector to the ShortExecutor - uses new controller after proposal 61,
            first transferring aUSDC and then withdrawing it from the pool to the executor.
         */
        uint totalUSDCAmount = LibPropConstants.USDC_V3 + LibPropConstants.USDC_VEST;
        ICollector(0x7AB1e5c406F36FE20Ce7eBa528E182903CA8bFC7 /* new controller after proposal 61*/).transfer(
            IERC20(LibPropConstants.AUSDC_TOKEN),
            address(this),
            totalUSDCAmount
        );

        IPool(LibPropConstants.POOL).withdraw(
            address(LibPropConstants.USDC_TOKEN),
            totalUSDCAmount,
            address(this)
        );

        /**
            6. Transfer USDC 420,000 directly to Certora.
         */
        IERC20(LibPropConstants.USDC_TOKEN).transfer(LibPropConstants.CERTORA_BENEFICIARY, LibPropConstants.USDC_V3);

        /**
            7. Approve USDC 1,000,000 to Sablier. Future allowances should increment this to not override this vesting.
         */
        require(IERC20(LibPropConstants.USDC_TOKEN).allowance(address(this), LibPropConstants.SABLIER) == 0, "Allowance to sablier is not zero");
        IERC20(LibPropConstants.USDC_TOKEN).approve(LibPropConstants.SABLIER, LibPropConstants.USDC_VEST);
        
        /**
            8. Create a Sablier stream with Certora as the beneficiary, to stream the USDC 1,000,000 over 6 months.
         */
        actualAmount = (LibPropConstants.USDC_VEST / duration) * duration; // rounding
        //console.logUint(LibPropConstants.USDC_VEST - actualAmount); // 6400000
        require(LibPropConstants.USDC_VEST - actualAmount < 10e6, "losing more than 10 USDC due to rounding");
        uint streamIdUSDCVest = ISablier(LibPropConstants.SABLIER).createStream(
            LibPropConstants.CERTORA_BENEFICIARY, 
            actualAmount,
            LibPropConstants.USDC_TOKEN,
            currentTime, 
            currentTime + duration
        );
        require (streamIdUSDCVest > 0, "invalid stream id");
    }
}
