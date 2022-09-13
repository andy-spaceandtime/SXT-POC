// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Operator.sol";

contract SXTOperator is Operator {
    constructor(address _sxt, address _owner) Operator(_sxt, _owner) {}
}
