// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.24;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { ERC721Utils } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Utils.sol";

/**
 * @dev An implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] 
 * Non-Fungible Token Standard.
 *
 * Same as OpenZepplin ERC721:5.4.0. Removed `_burn()`, `name()`, 
 * `symbol()` and `tokenURI()`.
 *
 * You must provide `name()` `symbol()` and `tokenURI(uint256 tokenId)`
 * to conform with IERC721Metadata
 */
abstract contract ERC721Spec is 
  Context, 
  ERC165, 
  IERC721, 
  IERC721Metadata, 
  IERC721Errors 
{
  using Strings for uint256;

  // ============ Storage ============

  // Mapping from token ID to owner address
  mapping(uint256 => address) internal _owners;
  // Mapping owner address to token count
  mapping(address => uint256) internal _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // ============ Read Methods ============

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) 
    public view virtual returns (uint256) 
  {
    if (owner == address(0)) {
      revert ERC721InvalidOwner(address(0));
    }
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual returns (address) 
  {
    return _requireOwned(tokenId);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC165, IERC165) returns (bool) 
  {
    return interfaceId == type(IERC721).interfaceId 
      || interfaceId == type(IERC721Metadata).interfaceId 
      || super.supportsInterface(interfaceId);
  }

  // ============ Approval Methods ============

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual {
    _approve(to, tokenId, _msgSender());
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) 
    public view virtual returns (address) 
  {
    _requireOwned(tokenId);
    return _getApproved(tokenId);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function setApprovalForAll(address operator, bool approved) 
    public virtual 
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) 
    public view virtual returns (bool) 
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev Returns the approved address for `tokenId`. Returns 0 if 
   * `tokenId` is not minted.
   */
  function _getApproved(uint256 tokenId) 
    internal view virtual returns (address) 
  {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   */
  function _approve(address to, uint256 tokenId, address auth) 
    internal 
  {
    _approve(to, tokenId, auth, true);
  }

  /**
   * @dev Variant of `_approve` with an optional flag to enable or 
   * disable the {Approval} event. The event is not emitted in the 
   * context of transfers.
   */
  function _approve(
    address to, 
    uint256 tokenId, 
    address auth, 
    bool emitEvent
  ) 
    internal virtual 
  {
    // Avoid reading the owner unless necessary
    if (emitEvent || auth != address(0)) {
      address owner = _requireOwned(tokenId);

      // We do not use _isAuthorized because single-token approvals should not be able to call approve
      if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
        revert ERC721InvalidApprover(auth);
      }

      if (emitEvent) {
        emit Approval(owner, to, tokenId);
      }
    }

    _tokenApprovals[tokenId] = to;
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Requirements:
   * - operator can't be the address zero.
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner, 
    address operator, 
    bool approved
  ) 
    internal virtual 
  {
    if (operator == address(0)) {
      revert ERC721InvalidOperator(operator);
    }
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `owner`'s 
   * tokens, or `tokenId` in particular (ignoring whether it is owned 
   * by `owner`).
   */
  function _isAuthorized(
    address owner, 
    address spender, 
    uint256 tokenId
  ) 
    internal view virtual returns (bool) 
  {
    return spender != address(0) && (owner == spender 
      || isApprovedForAll(owner, spender) 
      || _getApproved(tokenId) == spender
    );
  }

  /**
   * @dev Checks if `spender` can operate on `tokenId`, assuming the 
   * provided `owner` is the actual owner.
   */
  function _checkAuthorized(
    address owner, 
    address spender, 
    uint256 tokenId
  ) 
    internal view virtual 
  {
    if (!_isAuthorized(owner, spender, tokenId)) {
      if (owner == address(0)) {
        revert ERC721NonexistentToken(tokenId);
      } else {
        revert ERC721InsufficientApproval(spender, tokenId);
      }
    }
  }

  // ============ Transfer Methods ============

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(address from, address to, uint256 tokenId) 
    public virtual 
  {
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    // Setting an "auth" arguments enables the `_isAuthorized` check
    // which verifies that the token exists (from != 0). Therefore, it 
    // is not needed to verify that the return value is not 0 here.
    address previousOwner = _update(to, tokenId, _msgSender());
    if (previousOwner != from) {
      revert ERC721IncorrectOwner(from, tokenId, previousOwner);
    }
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from, 
    address to, 
    uint256 tokenId, 
    bytes memory data
  ) 
    public virtual 
  {
    transferFrom(from, to, tokenId);
    ERC721Utils.checkOnERC721Received(_msgSender(), from, to, tokenId, data);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`. As opposed to 
   * {transferFrom}, this imposes no restrictions on msg.sender.
   */
  function _transfer(address from, address to, uint256 tokenId) 
    internal 
  {
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    address previousOwner = _update(to, tokenId, address(0));
    if (previousOwner == address(0)) {
      revert ERC721NonexistentToken(tokenId);
    } else if (previousOwner != from) {
      revert ERC721IncorrectOwner(from, tokenId, previousOwner);
    }
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, 
   * checking that contract recipients are aware of the ERC-721 
   * standard to prevent tokens from being forever locked.
   */
  function _safeTransfer(address from, address to, uint256 tokenId) 
    internal 
  {
    _safeTransfer(from, to, tokenId, "");
  }

  /**
   * @dev Same as `_safeTransfer`, with an additional `data` parameter 
   * which is forwarded in {IERC721Receiver-onERC721Received} to 
   * contract recipients.
   */
  function _safeTransfer(
    address from, 
    address to, 
    uint256 tokenId, 
    bytes memory data
  ) 
    internal virtual 
  {
    _transfer(from, to, tokenId);
    ERC721Utils.checkOnERC721Received(
      _msgSender(), 
      from, 
      to, 
      tokenId, 
      data
    );
  }

  /**
   * @dev Transfers `tokenId` from its current owner to `to`, or 
   * alternatively mints (or burns) if the current owner (or `to`) is 
   * the zero address. Returns the owner of the `tokenId` before the 
   * update.
   */
  function _update(address to, uint256 tokenId, address auth) 
    internal virtual returns (address) 
  {
    address from = _ownerOf(tokenId);

    // Perform (optional) operator check
    if (auth != address(0)) {
      _checkAuthorized(from, auth, tokenId);
    }

    // Execute the update
    if (from != address(0)) {
      // Clear approval. No need to re-authorize 
      // or emit the Approval event
      _approve(address(0), tokenId, address(0), false);

      unchecked {
        _balances[from] -= 1;
      }
    }

    if (to != address(0)) {
      unchecked {
        _balances[to] += 1;
      }
    }

    _owners[tokenId] = to;
    emit Transfer(from, to, tokenId);
    return from;
  }

  // ============ Minting Methods ============

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   */
  function _mint(address to, uint256 tokenId) internal {
    if (to == address(0)) {
      revert ERC721InvalidReceiver(address(0));
    }
    address previousOwner = _update(to, tokenId, address(0));
    if (previousOwner != address(0)) {
      revert ERC721InvalidSender(address(0));
    }
  }

  /**
   * @dev Mints `tokenId`, transfers it to `to` and checks for `to` 
   * acceptance.
   */
  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as _safeMint, with an additional `data` parameter which 
   * is forwarded in {IERC721Receiver-onERC721Received} to contract 
   * recipients.
   */
  function _safeMint(address to, uint256 tokenId, bytes memory data) 
    internal virtual 
  {
    _mint(to, tokenId);
    ERC721Utils.checkOnERC721Received(
      _msgSender(), 
      address(0), 
      to, 
      tokenId, 
      data
    );
  }

  /**
   * @dev Unsafe write access to the balances, used by extensions that 
   * "mint" tokens using an {ownerOf} override.
   */
  function _increaseBalance(address account, uint128 value) 
    internal virtual 
  {
    unchecked {
      _balances[account] += value;
    }
  }

  // ============ Utility Methods ============

  /**
   * @dev Reverts if the `tokenId` doesn't have a current owner 
   * (it hasn't been minted, or it has been burned). Returns the owner.
   */
  function _requireOwned(uint256 tokenId) 
    internal view returns (address) 
  {
    address owner = _ownerOf(tokenId);
    if (owner == address(0)) {
      revert ERC721NonexistentToken(tokenId);
    }
    return owner;
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token 
   * doesn't exist.
   */
  function _ownerOf(uint256 tokenId) 
    internal view virtual returns (address) 
  {
    return _owners[tokenId];
  }
}