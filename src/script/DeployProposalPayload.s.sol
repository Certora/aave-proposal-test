// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@forge-std/console.sol";
import {Script} from "@forge-std/Script.sol";
import {PayloadCertoraProposal} from "../PayloadCertoraProposal.sol";

contract DeployProposalPayload is Script {
    function run() external {
        vm.startBroadcast();
        PayloadCertoraProposal proposalPayload = new PayloadCertoraProposal();
        console.log("Proposal Payload address", address(proposalPayload));
        vm.stopBroadcast();
    }
}