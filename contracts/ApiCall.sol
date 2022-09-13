// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstract/Admin.sol";
import "./abstract/String.sol";
import "./abstract/Initializer.sol";
import "./abstract/SXTClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ApiCall is Admin, String, Initializer, SXTClient {
    using SXT for SXT.Request;

    /// @dev Fee for SXT request
    uint256 public constant FEE = (1 * SXT_DIVISIBILITY) / 10;

    /// @dev SpaceAndTime Job Id
    bytes32 public SXT_JOB_ID;

    /// @dev SpaceAndTime Gateway API Endpoint
    string public SXT_GATEWAY_ENDPOINT;

    /// @dev SXT Api call request Id
    bytes32 public currentRequestId;

    /// @dev SXT Api call response
    string public currentResponse;

    constructor() {
        admin = msg.sender;
    }

    /// @dev Initialize contract states
    function initialize(
        address _operator,
        address _sxt,
        string memory _jobId,
        string memory _sxtGatewayEndpoint
    ) external initializer onlyAdmin {
        setSXTToken(_sxt);
        setSXTOracle(_operator);

        SXT_JOB_ID = stringToBytes32(_jobId);
        SXT_GATEWAY_ENDPOINT = _sxtGatewayEndpoint;
    }

    /// @dev Set SXT operator contract address
    function setSXTOperator(address _operator) external onlyAdmin {
        setSXTOracle(_operator);
    }

    /// @dev Withdraw SXT from contract
    function withdrawSXT(address _to, uint256 _amount) external onlyAdmin {
        IERC20(SXTTokenAddress()).transferFrom(
            address(this),
            _to,
            _amount
        );
    }

    /// @dev Set SXT JOB ID
    function setSXTJobID(string memory _jobId) external onlyAdmin {
        SXT_JOB_ID = stringToBytes32(_jobId);
    }


    /// @dev Execute api call
    function executeApi(string memory _resourceId, string memory _query, string memory _path)
        external
        returns (bytes32 requestId)
    {
        SXT.Request memory request = buildSXTRequest(
            SXT_JOB_ID,
            address(this),
            this.callback.selector
        );

        // Set the URL to perform the GET request on
        request.add("post", SXT_GATEWAY_ENDPOINT);
        request.add("resourceId", _resourceId);
        request.add("query", _query);
        request.add("path", _path);

        // Sends the request
        return sendSXTRequest(request, FEE);
    }

    /// @dev SXT off-chain request callback
    function callback(bytes32 _requestId, string calldata _data)
        external
        recordSXTFulfillment(_requestId)
    {
        currentRequestId = _requestId;
        currentResponse = _data;
    }
}
