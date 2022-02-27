contract ChainlinkHarness {
    uint8 _decimals;
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    
    mapping(uint => int256) timeToAnswer;
    mapping(uint => uint256) timeToStartedAt;
    uint80 _roundId;
    uint _updatedAt;
    uint80 _answeredInRound;

    function latestRoundData()
        external
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
        ) {
            return (_roundId, timeToAnswer[block.timestamp], timeToStartedAt[block.timestamp], _updatedAt, _answeredInRound);
        }
}