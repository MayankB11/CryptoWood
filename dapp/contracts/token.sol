// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ContentToken is ERC1155 {
    address public owner;
    address public marketPlace;
    uint256 public totalTypesOfTokens;
    
    struct TokenInfo{
        address creator;
        string gatedURL;
        uint256 tokenPrice;
        bool isContentToken;
    }
    
    mapping(address => uint256) creatorTokenMapping;
    mapping(uint256 => TokenInfo) tokenInfos;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this");
        _;
    }
    
    modifier onlyCreator(uint256 tokenId){
        require(msg.sender == tokenInfos[tokenId].creator, "only creator can call this");
        _;
    }
    
    modifier onlyMarketPlace(){
        require(msg.sender == marketPlace, "only market place can call this");
        _;
    }

    constructor(address owner_, address marketPlace_) ERC1155("") {
        owner = owner_;
        marketPlace = marketPlace_;
        totalTypesOfTokens = 0;
    }
    
    function addNewToken(uint256 initialSupply, uint256 price) public returns (uint256){
        
        if (creatorTokenMapping[msg.sender] == 0){
            totalTypesOfTokens++;
            uint256 tokenId = totalTypesOfTokens;
            tokenInfos[tokenId].creator = msg.sender;
            tokenInfos[tokenId].tokenPrice = 100;
            tokenInfos[tokenId].isContentToken = false;
            creatorTokenMapping[msg.sender] = tokenId;
            _mint(msg.sender, tokenId, 100000000000, "");
        }
        
        totalTypesOfTokens++;
        uint256 tokenId = totalTypesOfTokens;
        tokenInfos[tokenId].creator = msg.sender;
        tokenInfos[tokenId].tokenPrice = price;
        tokenInfos[tokenId].isContentToken = true;

        _mint(msg.sender, tokenId, initialSupply, "");
        setApprovalForAll(marketPlace, true);
        
        return tokenId;

        // ChainLink Call
        // -- mintgate connection (Custom API call){tokenID, private-link-id}
    }
    
    function setGatedURI(uint256 tokenID, string memory uri) public onlyOwner{
        tokenInfos[tokenID].gatedURL = uri;
    }
    
    function getGatedURI(uint256 tokenID) public view returns(string memory){
        return tokenInfos[tokenID].gatedURL;
    }
    
    function addMoreSupply(uint256 tokenID, uint256 additionalSupply) public onlyCreator(tokenID){
        _mint(msg.sender, tokenID, additionalSupply, "");
    }
    
    function getTokenPriceAndCreator(uint256 tokenID) external view returns(uint256, address){
        require (tokenInfos[tokenID].tokenPrice > 0, "Token does not exist");
        return (tokenInfos[tokenID].tokenPrice, tokenInfos[tokenID].creator);
    }
    
    function setApprovalForMarketPlace() public{
        setApprovalForAll(marketPlace, true);
    }
}


contract MarketPlace {
    address public contentToken;
    address public owner;
    
    mapping(uint256 => mapping(address => uint256)) sellPrice;
    mapping(uint256 => address[]) sellers;
    
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
    
    function buyTokenFromCreator(uint256 tokenID) external payable{
        ContentToken c = ContentToken(contentToken);
        (uint256 tokenPrice, address creator) = c.getTokenPriceAndCreator(tokenID);
        
        require(msg.value >= tokenPrice, "Value less than token price");
        (bool sent, bytes memory data) = creator.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        c.safeTransferFrom(creator, msg.sender, tokenID, 1, "");
    }
    
    function sellToken(uint256 tokenID, uint256 price) public {
        ContentToken c = ContentToken(contentToken);
        
        require(c.isApprovedForAll(msg.sender, address(this)), "Market place needs to be approved by the seller");
        
        uint256 balance = c.balanceOf(msg.sender, tokenID);
        require(balance > 0, "Sender does not have enough to sell tokens");
        
        sellers[tokenID].push(msg.sender);
        sellPrice[tokenID][msg.sender] = price;
    }
    
    function getLowestPriceAndSeller(uint256 tokenID) public view returns(uint256, address){
        require(sellers[tokenID].length > 0, "No seller for this token");
        
        uint256 totalSellers = sellers[tokenID].length;
        uint256 ltp = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        address ltpAddr = address(0);
        for (uint8 i = 0; i < totalSellers; i++){
            if (ltp > sellPrice[tokenID][sellers[tokenID][i]]){
                if (sellPrice[tokenID][sellers[tokenID][i]] != 0){
                    ltp = sellPrice[tokenID][sellers[tokenID][i]];
                    ltpAddr = sellers[tokenID][i];
                }
            }
        }
        
        return (ltp, ltpAddr);
    }
    
    function buyTokenFromMarket(uint256 tokenID, address from) public payable{
        ContentToken c = ContentToken(contentToken);
        require (sellPrice[tokenID][from] > 0, "No sell price set");
        require(msg.value >= sellPrice[tokenID][from], "Value less than token price");
        
        uint256 balance = c.balanceOf(from, tokenID);
        require(balance > 0, "Seller does not have enough tokens");
        
        (bool sent, bytes memory data) = from.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        c.safeTransferFrom(from, msg.sender, tokenID, 1, "");
        
        sellPrice[tokenID][from] = 0;
    }
}
