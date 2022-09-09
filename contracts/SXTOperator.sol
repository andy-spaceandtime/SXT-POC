// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@chainlink/contracts/src/v0.7/Operator.sol";
import "./Operator.sol";

contract SXTOperator is Operator {
    constructor(address _link, address _owner) Operator(_link, _owner) {}
}
