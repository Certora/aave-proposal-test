// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;
interface IAaveGov {
    struct ProposalWithoutVotes {
        uint256 id;
        address creator;
        address executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        bool[] withDelegatecalls;
        uint256 startBlock;
        uint256 endBlock;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        bytes32 ipfsHash;
    }

    enum ProposalState {
        Pending,
        Canceled,
        Active,
        Failed,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    struct SPropCreateParams {
        address executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        bool[] withDelegatecalls;
        bytes32 ipfsHash;
    }

    function create(
        address executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls,
        bytes32 ipfsHash
    ) external returns (uint256);

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external payable;

    function submitVote(uint256 proposalId, bool support) external;

    function getProposalById(uint256 proposalId)
        external
        view
        returns (ProposalWithoutVotes memory);

    function getProposalState(uint256 proposalId)
        external
        view
        returns (ProposalState);
}
