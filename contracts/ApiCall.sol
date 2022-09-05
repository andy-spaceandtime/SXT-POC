// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./abstract/Admin.sol";
import "./abstract/String.sol";
import "./abstract/Initializer.sol";

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ApiCall is Admin, String, Initializer, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    /// @dev Fee for chainlink request
    uint256 public constant FEE = (1 * LINK_DIVISIBILITY) / 10;

    /// @dev SpaceAndTime Job Id
    bytes32 public SXT_JOB_ID;

    /// @dev SpaceAndTime Gateway API Endpoint
    string public SXT_GATEWAY_ENDPOINT;

    /// @dev SXT Api call response
    string[][] public response;

    /// @dev Initialize contract states
    function initialize(
        address _operator,
        address _link,
        string memory _jobId,
        string memory _sxtGatewayEndpoint
    ) external initializer onlyAdmin {
        setChainlinkToken(_link);
        setChainlinkOracle(_operator);

        SXT_JOB_ID = stringToBytes32(_jobId);
        SXT_GATEWAY_ENDPOINT = _sxtGatewayEndpoint;
    }

    /// @dev Set SXT operator contract address
    function setSXTOperator(address _operator) external onlyAdmin {
        setChainlinkOracle(_operator);
    }

    /// @dev Withdraw LINK from contract
    function withdrawLINK(address _to, uint256 _amount) external onlyAdmin {
        IERC20(chainlinkTokenAddress()).transferFrom(
            address(this),
            _to,
            _amount
        );
    }

    /// @dev Execute api call
    function executeApi(string memory _query)
        external
        returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(
            SXT_JOB_ID,
            address(this),
            this.callback.selector
        );

        // Set the URL to perform the GET request on
        request.add("post", SXT_GATEWAY_ENDPOINT);
        request.add("query", _query);

        // Sends the request
        return sendChainlinkRequest(request, FEE);
    }

    /// @dev SXT off-chain request callback
    function callback(bytes32 _requestId, string[][] calldata _data)
        external
        recordChainlinkFulfillment(_requestId)
    {
        // Remove previous data
        delete response;

        uint256 i;
        uint256 j;
        uint256 inLength;
        string[] memory row;

        uint256 length = _data.length;
        // Store response
        for (i = 0; i < length; i++) {
            inLength = _data[i].length;
            row = new string[](inLength);
            for (j = 0; j < inLength; j++) {
                row[j] = _data[i][j];
            }
            response.push(row);
        }
    }
}
