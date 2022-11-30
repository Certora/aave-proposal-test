// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
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