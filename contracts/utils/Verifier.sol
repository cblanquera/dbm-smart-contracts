// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

library Verifier {
  /**
   * @dev Verifies that the `author` signed the `message` with the given
   * `proof`.
   */
  function author(
    bytes memory message, 
    bytes memory proof
  ) internal pure returns(address) {
    return ECDSA.recover(
      // 2. Then convert to bytes32
      MessageHashUtils.toEthSignedMessageHash(
        // 1. Make a message hash
        keccak256(message)
      ),
      proof
    );
  }
}