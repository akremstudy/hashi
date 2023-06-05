// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITellor } from "./ITellor.sol";
import { BlockHashOracleAdapter } from "../BlockHashOracleAdapter.sol";

contract TellorAdapter is BlockHashOracleAdapter {
    ITellor public tellor;

    error BlockHashNotAvailable();
    constructor(address payable _tellorAddress) {
        tellor = ITellor(_tellorAddress);
    }

    /// @dev Stores the block header for a given block.
    /// @param chainId Network identifier for the chain on which the block was mined.
    /// @param blockNumber Identifier for the block for which to set the header.
    function storeHash(uint256 chainId, uint256 blockNumber) public {
        bytes memory _queryData = abi.encode("EVMHeader", abi.encode(chainId, blockNumber));
        bytes32 _queryId = keccak256(_queryData);
        // delay 15 minutes to allow for disputes to be raised if bad value is submitted (the longer the stronger the security)
        (bool retrieved, bytes memory _hashValue, uint256 _timestampRetrieved) = tellor.getDataBefore(_queryId, block.timestamp - 15 minutes);
        if (!retrieved) revert BlockHashNotAvailable();
        _storeHash(chainId, blockNumber, bytes32(_hashValue));
    }
}
