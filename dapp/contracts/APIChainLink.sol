// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


interface ITokenContract {
    function setGatedURI(uint256 tokenID, string memory uri) external;
}

contract APIChainlink is ChainlinkClient {

    using Chainlink for Chainlink.Request;

    uint256 public mintId;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    address public tokenContract;
    uint256 public token;
    mapping(bytes32 => uint) public requestTokenMapping;


    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)
        tokenContract = address(0);
    }

    function setContractAddress(address _tokenContract) public {
        require(_tokenContract != address(0), "Already initialized");
        tokenContract = _tokenContract;
    }

    function requestMintGateAccess(uint256 tokenId, uint privateLinkId) external returns (bytes32 requestId)
    {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        string memory x = string(abi.encodePacked("http://1f28-106-51-88-138.ngrok.io/mintGate", "?tokenId=", uint2str(tokenId), "&privateLinkId=", uint2str(privateLinkId)));
        request.add("get", x);
        request.add("path", "uri");

        // Sends the request
        bytes32 requestID = sendChainlinkRequestTo(oracle, request, fee);
        requestTokenMapping[requestID] = tokenId;
        return requestID;
    }

    function fulfill(bytes32 _requestId, uint256 gatedURLId) public recordChainlinkFulfillment(_requestId)
    {
        mintId = gatedURLId;
        token = requestTokenMapping[_requestId];
        ITokenContract(tokenContract).setGatedURI(token, uint2str(mintId));
    }


    // Helper function to convert uint to string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {

        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}