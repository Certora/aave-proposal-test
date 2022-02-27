// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IAaveGov} from "./IAaveGov.sol";
import {IERC20} from "../IERC20.sol";
import {BaseTest, console} from "./base/BaseTest.sol";
import {LibPropConstants} from "../LibPropConstants.sol";
import {PayloadCertoraProposal} from "../PayloadCertoraProposal.sol";
import "./utils/console.sol";

contract PayloadCertoraProposalTest is BaseTest {
    function setUp() public {}

    /// @dev Check conversion of units
    function testConversion() public {
        PayloadCertoraProposal testContract = new PayloadCertoraProposal();
        console.log(testContract.getPriceOfAAVEinUSDC());
        // price is expected to be around $130-140
        // 13,520,978,414
        uint vestAmount = testContract.convertUSDCAmountToAAVE(LibPropConstants.AAVE_VEST_USDC_WORTH)/1e18;
        // 5000 <= vestAmount <= 5400
        assertGe(vestAmount, 5000);
        assertLe(vestAmount, 5400);
        uint fundAmount = testContract.convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH)/1e18;
        /// 1426 <= fundAmount <= 1536
        assertGe(fundAmount, 1426);
        assertLe(fundAmount, 1536);
    }

    function pass61() internal {
        uint proposalId = 61;
        vm.deal(LibPropConstants.ECOSYSTEM_RESERVE, 1 ether);
        vm.startPrank(LibPropConstants.ECOSYSTEM_RESERVE);
        vm.roll(block.number + 1);
        GOV.submitVote(proposalId, true);
        uint256 endBlock = GOV.getProposalById(proposalId).endBlock;
        vm.roll(endBlock + 1);
        GOV.queue(proposalId);
        uint256 executionTime = GOV.getProposalById(proposalId).executionTime;
        vm.warp(executionTime + 1);
        GOV.execute(proposalId);
        vm.stopPrank();
    }

    /// @dev First deploys a fresh payload, then tests everything using it
    function testProposalPrePayload() public {
        // imagine proposal 61 has passed
        // pass61(); // passed
        address payload = address(new PayloadCertoraProposal());
        _testProposal(payload);
    }

    /// @dev Uses an already deployed payload on the target network
    /*function testProposalPostPayload() public {
        address payload = address(0x0); // xxx
        _testProposal(payload);
    }*/

    IAaveGov GOV = IAaveGov(LibPropConstants.AAVE_GOVERNANCE);

    function _testProposal(address payload) internal {
        address[] memory targets = new address[](1);
        targets[0] = payload;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

        uint256 proposalId = _createProposal(
            IAaveGov.SPropCreateParams({
                executor: LibPropConstants.SHORT_EXECUTOR,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                withDelegatecalls: withDelegatecalls,
                ipfsHash: bytes32(0)
            })
        );

        uint256 recipientUSDCBefore = IERC20(LibPropConstants.USDC_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 multisigAaveBefore = 0 /*IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_AAVE_MULTISIG
        )*/;

        vm.deal(LibPropConstants.ECOSYSTEM_RESERVE, 1 ether);
        vm.startPrank(LibPropConstants.ECOSYSTEM_RESERVE);
        vm.roll(block.number + 1);
        GOV.submitVote(proposalId, true);
        uint256 endBlock = GOV.getProposalById(proposalId).endBlock;
        vm.roll(endBlock + 1);
        GOV.queue(proposalId);
        uint256 executionTime = GOV.getProposalById(proposalId).executionTime;
        vm.warp(executionTime + 1);
        GOV.execute(proposalId);
        vm.stopPrank();

        validateFunds(recipientUSDCBefore, multisigAaveBefore);
    }

    function validateFunds(uint recipientUSDCBefore, uint multisigAaveBefore) internal view {
        uint256 recipientUSDCAfter = IERC20(LibPropConstants.USDC_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 multisigAaveAfter = 0 /*IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_AAVE_MULTISIG
        )*/;

        require (recipientUSDCAfter - recipientUSDCBefore == LibPropConstants.USDC_V3, "invalid transfer of V3 services");
        // require(multisigAaveAfter - multisigAaveBefore == (new PayloadCertoraProposal()).convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH), "invalid transfer of fund to multisig");
    }

    function _createProposal(IAaveGov.SPropCreateParams memory params)
        internal
        returns (uint256)
    {
        vm.deal(LibPropConstants.ECOSYSTEM_RESERVE, 1 ether);
        vm.startPrank(LibPropConstants.ECOSYSTEM_RESERVE);
        uint256 proposalId = GOV.create(
            params.executor,
            params.targets,
            params.values,
            params.signatures,
            params.calldatas,
            params.withDelegatecalls,
            params.ipfsHash
        );
        vm.stopPrank();
        return proposalId;
    }

}
