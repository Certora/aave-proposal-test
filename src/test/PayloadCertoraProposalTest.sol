// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IAaveGov} from "./IAaveGov.sol";
import {IERC20} from "../IERC20.sol";
import {BaseTest, console} from "./base/BaseTest.sol";
import {LibPropConstants} from "../LibPropConstants.sol";
import {PayloadCertoraProposal} from "../PayloadCertoraProposal.sol";
import {ISablier} from "../PayloadCertoraProposal.sol";
import "./utils/console.sol";

contract PayloadCertoraProposalTest is BaseTest {
    function setUp() public {}

    function aaveVestAmount(PayloadCertoraProposal proposal) internal view returns (uint256) {
        return proposal.convertUSDCAmountToAAVE(LibPropConstants.AAVE_VEST_USDC_WORTH);
    }

    /// @dev Check conversion of units
    function testConversion() public {
        PayloadCertoraProposal testContract = new PayloadCertoraProposal();
        (uint price, uint8 decimals) = testContract.getPriceOfAAVEinUSDC();
        console.log(price);
        // price is expected to be around $130-140
        // 13,520,978,414
        uint vestAmount = aaveVestAmount(testContract)/1e18;
        // 5000 <= vestAmount <= 5400
        assertGe(vestAmount, 5000);
        assertLe(vestAmount, 5400);
        uint fundAmount = testContract.convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH)/1e18;
        // 1426 <= fundAmount <= 1536
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
    function testProposalPostPayload() public {
        address payload = 0x879A89D30b04b481Bcd54f474533d3D6A27cFd7D;
        _testProposal(payload);
    }

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

        validateFunds(multisigAaveBefore, payload);
        validateVesting(payload);
    }

    function validateVesting(address payload) internal {
        uint duration = 6 * 30 days;
        uint256 usdcBefore = IERC20(LibPropConstants.USDC_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 aaveBefore = IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 aaveToBeVested = (aaveVestAmount(PayloadCertoraProposal(payload)) / duration) * duration;

        // wrap to end of vesting
        vm.warp(block.timestamp + duration + 1 days);

        vm.startPrank(LibPropConstants.CERTORA_BENEFICIARY);
        uint aaveStreamId = ISablier(LibPropConstants.SABLIER).nextStreamId() - 2;
        uint aaveBalanceToWithdraw = ISablier(LibPropConstants.SABLIER).balanceOf(aaveStreamId, LibPropConstants.CERTORA_BENEFICIARY);
        require (aaveBalanceToWithdraw == aaveToBeVested, "unexpected sablier balance of aave");
        require(ISablier(LibPropConstants.SABLIER).withdrawFromStream(aaveStreamId, aaveBalanceToWithdraw), "aave withdraw failed");

        uint usdcStreamId = aaveStreamId + 1;
        uint usdcBalanceToWithdraw = ISablier(LibPropConstants.SABLIER).balanceOf(usdcStreamId, LibPropConstants.CERTORA_BENEFICIARY);
        uint vestedUSDCAmount = LibPropConstants.USDC_VEST;
        require (usdcBalanceToWithdraw == (vestedUSDCAmount / duration) * duration, "unexpected sablier balance of usdc");
        require(ISablier(LibPropConstants.SABLIER).withdrawFromStream(usdcStreamId, usdcBalanceToWithdraw), "usdc withdraw failed");
        vm.stopPrank();

        uint256 usdcAfter = IERC20(LibPropConstants.USDC_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 aaveAfter = IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );

        require (usdcAfter == usdcBefore + usdcBalanceToWithdraw, "not withdrawn all usdc after 6 months");
        require (aaveAfter == aaveBefore + aaveBalanceToWithdraw, "not withdrawn all aave after 6 months");
    }

    function validateFunds(uint multisigAaveBefore, address payload) internal view {
        uint256 multisigAaveAfter = IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_AAVE_MULTISIG
        );

        require(multisigAaveAfter - multisigAaveBefore == (PayloadCertoraProposal(payload)).convertUSDCAmountToAAVE(LibPropConstants.AAVE_FUND_USDC_WORTH), "invalid transfer of fund to multisig");
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
