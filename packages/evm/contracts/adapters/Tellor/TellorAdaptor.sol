// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ITellor } from "./ITellor.sol";
import { BlockHashOracleAdapter } from "../BlockHashOracleAdapter.sol";

contract TellorAdapter is BlockHashOracleAdapter {
    ITellor public tellor;

    error BlockHashNotAvailable();

    constructor(address _tellorAddress) {
        tellor = ITellor(_tellorAddress);
    }

    /// @dev Stores the block header for a given block.
    /// @param chainId Network identifier for the chain on which the block was mined.
    /// @param blockNumber Identifier for the block for which to set the header.
    function storeHash(uint256 chainId, uint256 blockNumber) public {
        bytes memory _queryData = abi.encode("EVMHeader", abi.encode(chainId, blockNumber));
        bytes32 _queryId = keccak256(_queryData);
        // delay 15 minutes to allow for disputes to be raised if bad value is submitted
        // (the longer the stronger the security)
        (bool retrieved, bytes memory _hashValue, ) = tellor.getDataBefore(_queryId, block.timestamp - 15 minutes);
        if (!retrieved) revert BlockHashNotAvailable();
        _storeHash(chainId, blockNumber, bytes32(_hashValue));
    }

    /// @dev Stores multiple block hashes for their corresponding block numbers.
    /// @param chainId Network identifier for the chain on which the block was mined.
    /// @param blockNumbers List of block identifiers for which to store block hashes.
    function storeHashes(uint256 chainId, uint256[] calldata blockNumbers) public {
        bytes memory _queryData = abi.encode("EVMHeaderslist", abi.encode(chainId, blockNumbers));
        bytes32 _queryId = keccak256(_queryData);
        // delay 15 minutes to allow for disputes to be raised if bad value is submitted
        // (the longer the stronger the security)
        (bool retrieved, bytes memory _hashValue, ) = tellor.getDataBefore(_queryId, block.timestamp - 15 minutes);
        if (!retrieved) revert BlockHashNotAvailable();
        bytes32[] memory _hashes = abi.decode(_hashValue, (bytes32[]));
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            _storeHash(chainId, blockNumbers[i], _hashes[i]);
        }
    }
}
