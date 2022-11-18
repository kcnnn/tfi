// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";  

contract Truflationft is ERC721URIStorage, ChainlinkClient, ConfirmedOwner  {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;
    Counters.Counter private _tokenIds;

    string public yoyInflation;
    address public oracleId;
    string public jobId;
    uint256 public fee;

    mapping(uint256 => uint256) public tokenIdToLevels;
    mapping(uint256 => string) public tokenIdToInflation;

     constructor(
    address oracleId_,
    string memory jobId_,
    uint256 fee_
  )ERC721 ("Truflationft", "TRFL") ConfirmedOwner(msg.sender) {
    setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    
    oracleId = oracleId_;
    jobId = jobId_;
    fee = fee_;
  }

    function generateCharacter(uint256 tokenId) public returns(string memory){
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            '<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>',
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',"Truflation",'</text>',
            '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">', "YoY: ",yoyInflation,'</text>',
            '</svg>'
        );
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            ));
    }

    function getInflation(uint256 tokenId) public view returns (string memory) {
        string memory _inflation = tokenIdToInflation[tokenId];
        return _inflation;
    }

    function getTokenURI(uint256 tokenId) public returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Truflation', tokenId.toString(), '",',
                '"description": "YoY Inflation",',
                '"image": "', generateCharacter(tokenId), '"',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function mint() public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdToInflation[newItemId] = "1,000,001";
        _setTokenURI(newItemId, getTokenURI(newItemId));
    }

    function train(uint256 tokenId) public {
        require(_exists(tokenId));
        require(ownerOf(tokenId) == msg.sender, "You must own this NFT to train it!");
        uint256 currentLevel = tokenIdToLevels[tokenId];
        tokenIdToLevels[tokenId] = currentLevel + 1;
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }

    function setInflation(uint256 tokenId, string memory _inflation) public {
        require(_exists(tokenId));
        require(ownerOf(tokenId) == msg.sender, "You must own this NFT to train it!");
        tokenIdToInflation[tokenId] = _inflation;
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }
     function requestYoyInflation() public returns (bytes32 requestId) {
    Chainlink.Request memory req = buildChainlinkRequest(
      bytes32(bytes(jobId)),
      address(this),
      this.fulfillYoyInflation.selector
    );
    req.add("service", "truflation/current");
    req.add("keypath", "yearOverYearInflation");
    req.add("abi", "json");
    return sendChainlinkRequestTo(oracleId, req, fee);
  }

  function fulfillYoyInflation(
    bytes32 _requestId,
    bytes memory _inflation
  ) public recordChainlinkFulfillment(_requestId) {
    yoyInflation = string(_inflation);
  }

  function changeOracle(address _oracle) public onlyOwner {
    oracleId = _oracle;
  }

  function changeJobId(string memory _jobId) public onlyOwner {
    jobId = _jobId;
  }

  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))),
    "Unable to transfer");
  }
}
