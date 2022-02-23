// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import {IAaveGov} from "./IAaveGov.sol";
import {IERC20} from "../IERC20.sol";
import {BaseTest, console} from "./base/BaseTest.sol";
import {LibPropConstants} from "../LibPropConstants.sol";
import {PayloadCertoraProposal} from "../PayloadCertoraProposal.sol";

contract PayloadCertoraProposalTest is BaseTest {
    function setUp() public {}

    /// @dev Check conversion of units
    function testConversion() public {
        PayloadCertoraProposal testContract = new PayloadCertoraProposal();
        assertEq(testContract.convertUSDCAmountToAAVE(LibPropConstants.AAVE_VEST_USDC_WORTH)/1e18, 4424);
        assertEq(testContract.convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH)/1e18, 1264);
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
        pass61();
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

        uint256 recipientUsdcBefore = IERC20(LibPropConstants.USDC_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 recipientWethBefore = IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );

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
/*
        _validatePhaseIFunds(recipientUsdcBefore, recipientWethBefore);
        address newControllerOfCollector = _validateNewCollector();
        _validateNewControllerOfCollector(ICollector(newControllerOfCollector));*/
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
