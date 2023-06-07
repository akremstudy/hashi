// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITellor {
    function getDataBefore(
        bytes32 _queryId,
        uint256 _timestamp
    ) external view returns (bool _available, bytes memory _value, uint256 _timestampRetrieved);
}
