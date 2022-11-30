// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import {IERC20} from "./IERC20.sol";
interface ICollector {
    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}