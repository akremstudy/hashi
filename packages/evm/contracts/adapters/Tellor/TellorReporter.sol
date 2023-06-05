// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITellor } from "./ITellor.sol";

contract TellorReporter {

    ITellor public tellor;

    constructor (address _tellorAddress) {
        tellor = ITellor(_tellorAddress);
    }
    
    /// @dev submitHashValue - submits a block hash to Tellor
    /// @param chainId - network identifier for the chain on which the block was mined
    /// @param blockNumber - block number for which to submit the hash
    //  presumes that reporter is staked with the stake amount required to submit a value in tellor contract
    // and they are not in reporter lock period
    function submitHashValue(uint256 chainId, uint256 blockNumber, bytes32 blockHash) external {
        // build query data according to Tellor's EVMHeader spec (see ./EVMHeader.md)
        bytes memory _queryData = abi.encode("EVMHeader", abi.encode(chainId, blockNumber));
        bytes32 _queryId = keccak256(_queryData);
        tellor.submitValue(_queryId, abi.encode(blockHash), 0, _queryData);
    }
}