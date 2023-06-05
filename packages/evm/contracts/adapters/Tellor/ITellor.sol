// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITellor {
    function getDataBefore(uint256 _queryId, uint256 _timestamp) external view returns (bool _available, bytes _value, uint256 _timestampRetrieved);
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
}