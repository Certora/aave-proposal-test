// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IAaveGov} from "./IAaveGov.sol";
import {IERC20} from "../IERC20.sol";
import {BaseTest, console} from "./base/BaseTest.sol";
import {LibPropConstants} from "../LibPropConstants.sol";
import {PayloadCertoraProposal} from "../PayloadCertoraProposal.sol";
import {IAaveEcosystemReserveController,IStreamable} from "../PayloadCertoraProposal.sol";
import "./utils/console.sol";


interface IPool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract PayloadCertoraProposalTest is BaseTest {
    function setUp() public {}

    address constant payload = address(0x0); // todo, was 0x879A89D30b04b481Bcd54f474533d3D6A27cFd7D
    uint constant proposalId = 0; // todo, was 66

    function aaveVestAmount(PayloadCertoraProposal proposal) internal view returns (uint256) {
        return proposal.convertUSDCAmountToAAVE(LibPropConstants.AAVE_VEST_USDC_WORTH);
    }

    /// @dev Check conversion of units
    function testConversion() public {
        PayloadCertoraProposal testContract = new PayloadCertoraProposal();
        (uint price, ) = testContract.getPriceOfAAVEinUSDC();
        console.log(price);
        // todo update numbers
        // price is expected to be around $90
        // 9308377059
        uint vestAmount = aaveVestAmount(testContract)/1e18;
        // 8500 <= vestAmount <= 9500
        assertGe(vestAmount, 8500);
        assertLe(vestAmount, 9500);
    }

    /// @dev First deploys a fresh payload, then tests everything using it
    function testProposalPrePayload() public {
        address _payload = address(new PayloadCertoraProposal());
        _testProposal(_payload, 0);
    }

    /// @dev Uses an already deployed payload on the target network
    function done_testProposalPostPayload() public {
        // todo check after contract is deployed and update address and proposal id
        _testProposal(payload, proposalId);
    }

    function done_testProposalQueueAndExec() public {
        vm.startPrank(LibPropConstants.CERTORA_BENEFICIARY);
        uint256 endBlock = GOV.getProposalById(proposalId).endBlock;
        console.log(endBlock);
        vm.roll(endBlock + 1);
        GOV.queue(proposalId);
        uint256 executionTime = GOV.getProposalById(proposalId).executionTime;
        console.log(executionTime);
        vm.warp(executionTime + 1);
        GOV.execute(proposalId);
        vm.stopPrank();
        validateVesting(payload);
    }

    function done_testProposalRawQueueAndExec() public {
        vm.startPrank(LibPropConstants.CERTORA_BENEFICIARY);
        (bool success, ) = address(GOV).call{value:0}(
            (hex'ddf0b0090000000000000000000000000000000000000000000000000000000000000042')
        );
        require(success);
        uint256 executionTime = GOV.getProposalById(proposalId).executionTime;
        console.log(executionTime);
        vm.warp(executionTime + 1);
        GOV.execute(proposalId);
        vm.stopPrank();
        validateVesting(payload);
    }

   
    function done_testProposalExec() public {
        // assumes we're past the execution time
        //uint256 executionTime = 1647163996;
        //vm.warp(executionTime);
        // todo check after contract is deployed and update address and proposal id
        vm.startPrank(LibPropConstants.CERTORA_BENEFICIARY);
        (bool success, ) = address(GOV).call{value:0}(
            (hex'fe0d94c10000000000000000000000000000000000000000000000000000000000000042')
        );
        require(success);
        vm.stopPrank();
        validateVesting(payload);
    }

    IAaveGov GOV = IAaveGov(LibPropConstants.AAVE_GOVERNANCE);

    function _testProposal(address _payload, uint existing) internal {
        uint256 _proposalId = existing;
        if (_proposalId == 0) {
            address[] memory targets = new address[](1);
            targets[0] = _payload;
            uint256[] memory values = new uint256[](1);
            values[0] = 0;
            string[] memory signatures = new string[](1);
            signatures[0] = "execute()";
            bytes[] memory calldatas = new bytes[](1);
            calldatas[0] = "";
            bool[] memory withDelegatecalls = new bool[](1);
            withDelegatecalls[0] = true;
            
            _proposalId = _createProposal(
                IAaveGov.SPropCreateParams({
                    executor: LibPropConstants.SHORT_EXECUTOR,
                    targets: targets,
                    values: values,
                    signatures: signatures,
                    calldatas: calldatas,
                    withDelegatecalls: withDelegatecalls,
                    // todo update ipfs hash
                    ipfsHash: bytes32(0x8f54769ae1c70e337e25314b0118ec69c439dfe701e6d0b3bb9ae28c7ae2655d)
                }),
                _proposalId
            );
        }

        vm.deal(LibPropConstants.ECOSYSTEM_RESERVE, 1 ether);
        vm.startPrank(LibPropConstants.ECOSYSTEM_RESERVE);
        vm.roll(block.number + 7200 + 1);
        console.log("Proposal state");
        console.log(uint(GOV.getProposalState(_proposalId)));
        GOV.submitVote(_proposalId, true);
        uint256 endBlock = GOV.getProposalById(_proposalId).endBlock;
        vm.roll(endBlock + 1);
        GOV.queue(_proposalId);
        uint256 executionTime = GOV.getProposalById(_proposalId).executionTime;
        vm.warp(executionTime + 1);
        GOV.execute(_proposalId);
        vm.stopPrank();

        validateVesting(_payload);
    }

    function tbd_test_currentBalance() public view {
       
        console.log("Streamer balance in aave");
        uint aaveStreamId = 102894; // todo
        console.log(IStreamable(LibPropConstants.ECOSYSTEM_RESERVE).balanceOf(aaveStreamId, LibPropConstants.CERTORA_BENEFICIARY));

        console.log("Sablier balance in ausdc");
        uint usdcStreamId = 102895; // todo
        console.log(IStreamable(LibPropConstants.AAVE_COLLECTOR).balanceOf(usdcStreamId, LibPropConstants.CERTORA_BENEFICIARY));

    }

    function validateVesting(address _payload) internal {
        uint duration = LibPropConstants.DURATION;
        uint256 usdcBefore = IERC20(LibPropConstants.USDC_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 aaveBefore = IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 aaveToBeVested = (aaveVestAmount(PayloadCertoraProposal(_payload)) / duration) * duration;

        // wrap to end of vesting
        vm.warp(block.timestamp + duration + 1 days);

        vm.startPrank(LibPropConstants.CERTORA_BENEFICIARY);
        uint aaveStreamId = IStreamable(LibPropConstants.ECOSYSTEM_RESERVE).getNextStreamId() - 1;
        uint aaveBalanceToWithdraw = IStreamable(LibPropConstants.ECOSYSTEM_RESERVE).balanceOf(aaveStreamId, LibPropConstants.CERTORA_BENEFICIARY);
        console.log("aave to be vested");
        console.log(aaveToBeVested);
        require (aaveBalanceToWithdraw == aaveToBeVested, "unexpected stream balance of aave");
        require(IStreamable(LibPropConstants.ECOSYSTEM_RESERVE).withdrawFromStream(aaveStreamId, aaveBalanceToWithdraw), "aave withdraw failed");

        uint usdcStreamId = IStreamable(LibPropConstants.AAVE_COLLECTOR).getNextStreamId() - 1;
        uint usdcBalanceToWithdraw = IStreamable(LibPropConstants.AAVE_COLLECTOR).balanceOf(usdcStreamId, LibPropConstants.CERTORA_BENEFICIARY);
        uint vestedUSDCAmount = LibPropConstants.USDC_VEST;
        require (usdcBalanceToWithdraw == (vestedUSDCAmount / duration) * duration, "unexpected sablier balance of usdc");
        uint actualUSDCBalance = IERC20(LibPropConstants.AUSDC_TOKEN).balanceOf(LibPropConstants.ECOSYSTEM_RESERVE);
        console.log("Actual aUSDC balance");
        console.log(actualUSDCBalance);
        require(IStreamable(LibPropConstants.AAVE_COLLECTOR).withdrawFromStream(usdcStreamId, usdcBalanceToWithdraw), "usdc withdraw failed");
        
         IPool(LibPropConstants.POOL).withdraw(
            address(LibPropConstants.USDC_TOKEN),
            usdcBalanceToWithdraw,
            LibPropConstants.CERTORA_BENEFICIARY
        );
        
        vm.stopPrank();

        uint256 usdcAfter = IERC20(LibPropConstants.USDC_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );
        uint256 aaveAfter = IERC20(LibPropConstants.AAVE_TOKEN).balanceOf(
            LibPropConstants.CERTORA_BENEFICIARY
        );

        require (aaveAfter == aaveBefore + aaveBalanceToWithdraw, "not withdrawn all aave after duration");
        require (usdcAfter == usdcBefore + usdcBalanceToWithdraw, "not withdrawn all usdc after duration");
    }

    function _createProposal(IAaveGov.SPropCreateParams memory params, uint256 _proposalId)
        internal
        returns (uint256)
    {
        vm.deal(LibPropConstants.ECOSYSTEM_RESERVE, 1 ether);
        vm.startPrank(LibPropConstants.ECOSYSTEM_RESERVE);
        if (_proposalId != 0) {
            // we know what proposalId we expect, we check the payload itself beforehand
            // todo: update
            (bool success, ) = address(GOV).call{value:0}(
                (hex'f8741a9c000000000000000000000000ee56e2b3d491590b5b31738cc34d5232f378a8d500000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000002408f54769ae1c70e337e25314b0118ec69c439dfe701e6d0b3bb9ae28c7ae2655d0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000879a89d30b04b481bcd54f474533d3d6a27cfd7d00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000009657865637574652829000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001')
            );
            require(success);
        } else {
            _proposalId = GOV.create(  
                params.executor,
                params.targets,
                params.values,
                params.signatures,
                params.calldatas,
                params.withDelegatecalls,
                params.ipfsHash
            );
        }
        vm.stopPrank();
        return _proposalId;
    }

}
