// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ENSInterface.sol";
import "../interfaces/SXTTokenInterface.sol";
import "../interfaces/SXTRequestInterface.sol";
import "../interfaces/OperatorInterface.sol";
import "../interfaces/PointerInterface.sol";
import "../libraries/SXT.sol";
import "../libraries/ENSResolver.sol";

/**
 * @title The SXTClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * SXT network
 */
abstract contract SXTClient {
  using SXT for SXT.Request;

  uint256 internal constant SXT_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("sxt");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant SXT_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  SXTTokenInterface private s_sxt;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event SXTRequested(bytes32 indexed id);
  event SXTFulfilled(bytes32 indexed id);
  event SXTCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A SXT Request struct in memory
   */
  function buildSXTRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (SXT.Request memory) {
    SXT.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A SXT Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (SXT.Request memory)
  {
    SXT.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a SXT request to the stored oracle address
   * @dev Calls `SXTRequestTo` with the stored oracle address
   * @param req The initialized SXT Request
   * @param payment The amount of SXT to send for the request
   * @return requestId The request ID
   */
  function sendSXTRequest(SXT.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendSXTRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a SXT request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send SXT which creates a request on the target oracle contract.
   * Emits SXTRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized SXT Request
   * @param payment The amount of SXT to send for the request
   * @return requestId The request ID
   */
  function sendSXTRequestTo(
    address oracleAddress,
    SXT.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      SXTRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of SXT sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a SXT request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized SXT Request
   * @param payment The amount of SXT to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(SXT.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a SXT request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send SXT which creates a request on the target oracle contract.
   * Emits SXTRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized SXT Request
   * @param payment The amount of SXT to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    SXT.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of SXT sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of SXT to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit SXTRequested(requestId);
    require(s_sxt.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits SXTCancelled event.
   * @param requestId The request ID
   * @param payment The amount of SXT sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelSXTRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit SXTCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setSXTOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the SXT token address
   * @param sxtAddress The address of the SXT token contract
   */
  function setSXTToken(address sxtAddress) internal {
    s_sxt = SXTTokenInterface(sxtAddress);
  }

  /**
   * @notice Sets the SXT token address for the public
   * network as given by the Pointer contract
   */
  function setPublicSXTToken() internal {
    setSXTToken(PointerInterface(SXT_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the SXT token
   * @return The address of the SXT token
   */
  function SXTTokenAddress() internal view returns (address) {
    return address(s_sxt);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function SXTOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addSXTExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and SXT token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useSXTWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 sxtSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver resolver = ENSResolver(s_ens.resolver(sxtSubnode));
    setSXTToken(resolver.addr(sxtSubnode));
    updateSXTOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useSXTWithENS` has been called previously
   */
  function updateSXTOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver resolver = ENSResolver(s_ens.resolver(oracleSubnode));
    setSXTOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateSXTCallback(bytes32 requestId)
    internal
    recordSXTFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits SXTFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordSXTFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit SXTFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}
