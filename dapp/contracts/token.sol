// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ContentToken is ERC1155 {
    address public owner;
    address public marketPlace;
    uint256 public totalTypesOfTokens;
    
    mapping(uint256 => address) tokenCreator;
    mapping(uint256 => string) gatedURLs;
    mapping(uint256 => uint256) tokenPrice;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }
    
    modifier onlyCreator(uint256 tokenId){
        require(msg.sender == tokenCreator[tokenId], "only creator can call this");
        _;
    }

    constructor(address owner_, address marketPlace_) ERC1155("") {
        owner = owner_;
        marketPlace = marketPlace_;
        totalTypesOfTokens = 0;
    }
    
    function addNewToken(uint256 initialSupply, uint256 price) public {
        totalTypesOfTokens++;
        uint256 tokenId = totalTypesOfTokens;
        tokenCreator[tokenId] = msg.sender;
        tokenPrice[tokenId] = price;

        _mint(msg.sender, tokenId, initialSupply, "");
        setApprovalForAll(marketPlace, true);
    }
    
    function setGatedURI(uint256 tokenID, string memory uri) public onlyOwner{
        gatedURLs[tokenID] = uri;
    }
    
    function getGatedURI(uint256 tokenID) public view returns(string memory){
        return gatedURLs[tokenID];
    }
    
    function addMoreSupply(uint256 tokenID, uint256 additionalSupply) public onlyCreator(tokenID){
        _mint(msg.sender, tokenID, additionalSupply, "");
    }
    
    function getTokenPriceAndCreator(uint256 tokenID) external view returns(uint256, address){
        require (tokenPrice[tokenID] > 0, "Token does not exist");
        return (tokenPrice[tokenID], tokenCreator[tokenID]);
    }
}


contract MarketPlace {
    address public contentToken;
    address public owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }
    
    constructor(address owner_) {
        owner = owner_;
    }
    
    function setContentTokenAddress(address contentToken_) public onlyOwner{
        contentToken = contentToken_;
    }
    
    function buyToken(uint256 tokenID) external payable{
        ContentToken c = ContentToken(contentToken);
        (uint256 tokenPrice, address creator) = c.getTokenPriceAndCreator(tokenID);
        
        require(msg.value >= tokenPrice, "Value less than token price");
        (bool sent, bytes memory data) = creator.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        c.safeTransferFrom(creator, msg.sender, tokenID, 1, "");
    }
}