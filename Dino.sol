// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Dinoworld is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 8800000000000000;
  uint256 public maxSupply = 8888;
  uint256 public maxSupplyWhitelist = 2000;
  uint256 public teamReserve = 555;
  uint256 maxSupplyPublic = 6333;
  uint256 publicFreeClaim = 750;
  uint256 whitelistAllocation = 1;
  uint256 maxMintPerWallet = 3;
  uint256 public publicFreeCount = 0;
  mapping(address => bool) public freeClaimed;

  address payable private recipient = payable(0xD3dC3cf8544bf19aEaa86cab0fECBcfDCE9748a4);
  
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setHiddenMetadataUri(_hiddenMetadataUri);
    _safeMint(msg.sender, teamReserve);
  }

  function mintWhitelist(bytes32[] calldata _merkleProof) public payable  {

    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(totalSupply() + 1 <= maxSupply, "Max Supply Exceeded");
    require(!whitelistClaimed[_msgSender()], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), 1);
  }

  function mintPublic(uint256 _mintAmount) public payable {
    require(msg.sender == tx.origin, "No transaction from smart contracts!");
    require(!paused, "The contract is paused!");
    require(totalSupply() + _mintAmount <= maxSupplyPublic, "Max supply exceeded!");
    if(publicFreeCount == publicFreeClaim){
        require(balanceOf(_msgSender()) + _mintAmount <= maxMintPerWallet - 1, "Limit Per Wallet Reached");
        require(msg.value >= cost * _mintAmount, "Insufficent Funds");
    } else {
        if (freeClaimed[_msgSender()] == false) {
            require(msg.value >= cost * (_mintAmount - 1), "One free, but payed ETH still too less.");
            require(balanceOf(_msgSender()) + _mintAmount <= maxMintPerWallet, "Limit Per Wallet Reached");

            publicFreeCount += 1;
            
        } else {
            require(msg.value >= cost * (_mintAmount), "Insufficient Funds");
            require(balanceOf(_msgSender()) + _mintAmount <= maxMintPerWallet, "Limit Per Wallet Reached");
        }

        freeClaimed[_msgSender()] = true;
    }


    _safeMint(_msgSender(), _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPublicSupply(uint256 _publicSupply) public onlyOwner {
    maxSupplyPublic = _publicSupply;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() external {
    require(msg.sender == recipient || msg.sender == owner(), "Invalid Sender");
    uint balance = address(this).balance;
    uint part = balance / 1000 * 25;

    recipient.transfer(part);
    payable(owner()).transfer(address(this).balance);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
