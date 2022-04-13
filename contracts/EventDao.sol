// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EIP712Whitelisting.sol";

contract EventDAO is ERC721, ReentrancyGuard, Ownable, EIP712Whitelisting {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

    /** MINTING **/
  uint256 public MAX_PASS_CARD_PER_WALLET;
  uint256 public MAX_VIP_CARD_PER_WALLET;
  uint256 public VIP_CARD_PRICE;
  uint256 public PASS_CARD_PRICE;
  uint256 public PASS_CARD_DIS_PRICE;
  uint256 public MAX_PASS_CARD_SUPPLY;
  uint256 public MAX_VIP_CARD_SUPPLY;
  uint256 public MAX_TEAM_CARD_SUPPLY;
  uint256 public MAX_SUPPLY;
  uint256 public MAX_PASS_CARD_RESERVED_SUPPLY;
  uint256 public MAX_VIP_CARD_RESERVED_SUPPLY;
  uint256 public MAX_MULTIMINT;
  uint256 public MAX_PASS_CARD_WHITELIST_SUPPLY;
  uint256 public MAX_VIP_CARD_WHITELIST_SUPPLY;

  PaymentSplitter private _splitter;


  constructor (
    string memory tokenName,
    string memory tokenSymbol,
    string memory customBaseURI_,
    address[] memory payees,
    uint256[] memory shares,
    uint256 passCardPrice,
    uint256 passDisCardPrice,
    uint256 vipCardPrice
   ) ERC721(tokenName, tokenSymbol) EIP712Whitelisting() {
    customBaseURI = customBaseURI_;

    _splitter = new PaymentSplitter(payees, shares);

    PASS_CARD_PRICE = passCardPrice;
    PASS_CARD_DIS_PRICE = passDisCardPrice;
    VIP_CARD_PRICE = vipCardPrice;
    MAX_VIP_CARD_PER_WALLET = 30;
    MAX_PASS_CARD_PER_WALLET = 50;

    MAX_MULTIMINT = 3;

    MAX_PASS_CARD_SUPPLY = 10000;
    MAX_VIP_CARD_SUPPLY = 100;
    MAX_TEAM_CARD_SUPPLY = 1;
    MAX_PASS_CARD_RESERVED_SUPPLY = 0;
    MAX_VIP_CARD_RESERVED_SUPPLY = 0;
    MAX_SUPPLY = MAX_PASS_CARD_SUPPLY + MAX_VIP_CARD_SUPPLY + MAX_TEAM_CARD_SUPPLY;

    MAX_PASS_CARD_WHITELIST_SUPPLY = 10000;
    MAX_VIP_CARD_WHITELIST_SUPPLY = 100;

    teamCardMintCount = 0;
  }

  /** ADMIN FUNCTIONS **/
  enum DaoStage { INACTIVE, WHITELIST_VIP, VIP, WHITELIST_PASS, PASS }
  DaoStage private stage_ = DaoStage.INACTIVE;

  function setStage(uint64 stage) external onlyOwner {
      if(uint(DaoStage.WHITELIST_VIP) == stage) {
        stage_ = DaoStage.WHITELIST_VIP;
      } else if(uint(DaoStage.WHITELIST_PASS) == stage) {
        stage_ = DaoStage.WHITELIST_PASS;
      } else if(uint(DaoStage.VIP) == stage) {
        stage_ = DaoStage.VIP;
      } else if(uint(DaoStage.PASS) == stage) {
        stage_ = DaoStage.PASS;
      } else {
        stage_ = DaoStage.INACTIVE;
      }
  }

  function setPassCardPrice(uint256 _price) external onlyOwner {
    PASS_CARD_PRICE = _price;
  }

  function setPassCardDisPrice(uint256 _price) external onlyOwner {
    PASS_CARD_DIS_PRICE = _price;
  }

  function setVipCardPrice(uint256 _price) external onlyOwner {
    VIP_CARD_PRICE = _price;
  }

  function setVipCardLimitPerWallet(uint256 maxPerWallet) external onlyOwner {
    MAX_VIP_CARD_PER_WALLET = maxPerWallet;
  }

  function setPassCardLimitPerWallet(uint256 maxPerWallet) external onlyOwner {
    MAX_PASS_CARD_PER_WALLET = maxPerWallet;
  }

  function setMultiMint(uint256 maxMultiMint) external onlyOwner {
    MAX_MULTIMINT = maxMultiMint;
  }

  function setMaxPassCardWhitelistSupply(uint256 maxSupply) external onlyOwner {
    MAX_PASS_CARD_WHITELIST_SUPPLY = maxSupply;
  }

  function setMaxVipCardWhitelistSupply(uint256 maxSupply) external onlyOwner {
    MAX_VIP_CARD_WHITELIST_SUPPLY = maxSupply;
  }

  mapping(address => uint256) private passCardMintCountMap;
  mapping(address => uint256) private vipCardMintCountMap;
  uint8 teamCardMintCount;

  function allowedPassCardMintCount(address minter) public view returns (uint256) {
    return MAX_PASS_CARD_PER_WALLET - passCardMintCountMap[minter];
  }

  function updatePassCardMintCount(address minter, uint256 count) private {
    passCardMintCountMap[minter] += count;
  }

  function allowedVipCardMintCount(address minter) public view returns (uint256) {
    return MAX_VIP_CARD_PER_WALLET - vipCardMintCountMap[minter];
  }

  function updateVipCardMintCount(address minter, uint256 count) private {
    vipCardMintCountMap[minter] += count;
  }

  Counters.Counter private passCardSupplyCounter;
  Counters.Counter private passCardReservedSupplyCounter;
  Counters.Counter private vipCardSupplyCounter;
  Counters.Counter private vipCardReservedSupplyCounter;
  Counters.Counter private passCardWhitelistMintCounter;
  Counters.Counter private vipCardWhitelistMintCounter;


  function totalSupply()  public view returns (uint256) {
    return passCardSupplyCounter.current() + vipCardSupplyCounter.current() + teamCardMintCount;
  }

  function totalPassCardSupply() public view returns (uint256) {
    return passCardSupplyCounter.current();
  }

  function totalPassCardReservedSupply() public view returns (uint256) {
    return passCardReservedSupplyCounter.current();
  }

  function totalVipCardSupply() public view returns (uint256) {
    return vipCardSupplyCounter.current();
  }

  function totalVipCardReservedSupply() public view returns (uint256) {
    return vipCardReservedSupplyCounter.current();
  }

  function totalPassCardWhitelistMints() public view returns (uint256) {
    return passCardWhitelistMintCounter.current();
  }

  function totalVipCardWhitelistMints() public view returns (uint256) {
    return vipCardWhitelistMintCounter.current();
  }

  //TODO : HATA FIRLATMIYOR GASFEE ALIYOR AMA MINT ETMIYOR..
  function mintCard(uint256 count) public payable nonReentrant {
    if(stage_==DaoStage.PASS) {
      mintPassCard(count);
    } else if (stage_==DaoStage.VIP) {
      mintVipCard(count);
    }
  }

  function mintPassCard(uint256 count) public payable nonReentrant {
    require(stage_ == DaoStage.PASS, "Sale not active");
    require(totalPassCardSupply() + count - 1 < MAX_PASS_CARD_SUPPLY - MAX_PASS_CARD_RESERVED_SUPPLY, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Exceeds mint limit");
    require(msg.value >= (count==2 ? PASS_CARD_DIS_PRICE : PASS_CARD_PRICE) * count, "Insufficient payment");

    if (allowedPassCardMintCount(_msgSender()) > 0) {
      updatePassCardMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      passCardSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_PASS_CARD_RESERVED_SUPPLY + totalPassCardSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function mintVipCard(uint256 count) public payable nonReentrant {
    require(stage_ == DaoStage.VIP, "Vip Sale not active");
    require(totalVipCardSupply() + count - 1 < MAX_VIP_CARD_SUPPLY - MAX_VIP_CARD_RESERVED_SUPPLY, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Exceeds mint limit");
    require(msg.value >= VIP_CARD_PRICE , "Insufficient payment");

    if (allowedVipCardMintCount(_msgSender()) > 0) {
      updateVipCardMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      vipCardSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_PASS_CARD_SUPPLY + MAX_VIP_CARD_RESERVED_SUPPLY + totalVipCardSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function mintTeamReserved() external onlyOwner {
    require(teamCardMintCount < MAX_TEAM_CARD_SUPPLY, "Exceeds max supply");
    _safeMint(_msgSender(), MAX_TEAM_CARD_SUPPLY);
    teamCardMintCount++;
  }

  function mintTeamReservedtoAddress(address account) external onlyOwner {
    require(teamCardMintCount < MAX_TEAM_CARD_SUPPLY, "Exceeds max supply");
    _safeMint(account, MAX_TEAM_CARD_SUPPLY);
    teamCardMintCount++;
  }

  function mintPassCardReserved(uint256 count) external onlyOwner {
    require(totalPassCardReservedSupply() + count - 1 < MAX_PASS_CARD_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      passCardReservedSupplyCounter.increment();
      _safeMint(_msgSender(), totalPassCardReservedSupply());
    }
  }

  function mintPassCardReservedToAddress(uint256 count, address account) external onlyOwner {
    require(totalPassCardReservedSupply() + count - 1 < MAX_PASS_CARD_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      passCardReservedSupplyCounter.increment();
      _safeMint(account, totalPassCardReservedSupply());
    }
  }

  function mintVipCardReserved(uint256 count) external onlyOwner{
    require(totalVipCardReservedSupply() + count - 1 < MAX_VIP_CARD_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      vipCardReservedSupplyCounter.increment();
      _safeMint(_msgSender(), MAX_PASS_CARD_SUPPLY + totalVipCardReservedSupply());
    }
  }

  function mintVipCardReservedToAddress(uint256 count, address account) external onlyOwner{
    require(totalVipCardReservedSupply() + count - 1 < MAX_VIP_CARD_RESERVED_SUPPLY, "Exceeds max supply");

    for (uint256 i = 0; i < count; i++) {
      vipCardReservedSupplyCounter.increment();
      _safeMint(account, MAX_PASS_CARD_SUPPLY + totalVipCardReservedSupply());
    }
  }

  function mintPassCardWhitelist(uint256 count, bytes calldata signature) public payable requiresWhitelist(signature) nonReentrant {
    require(stage_ == DaoStage.WHITELIST_PASS, "Pass Sale not active");
    require(totalPassCardWhitelistMints() + count - 1 < MAX_PASS_CARD_WHITELIST_SUPPLY, "Exceeds whitelist supply");
    require(totalPassCardSupply() < MAX_PASS_CARD_SUPPLY - MAX_PASS_CARD_RESERVED_SUPPLY + count - 1, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Exceeds mint limit");
    require(msg.value >= (count==2 ? PASS_CARD_DIS_PRICE : PASS_CARD_PRICE) * count, "Insufficient payment");

    if (allowedPassCardMintCount(_msgSender()) > 0) {
      updatePassCardMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      passCardSupplyCounter.increment();
      passCardWhitelistMintCounter.increment();
      _safeMint(_msgSender(), MAX_PASS_CARD_RESERVED_SUPPLY + totalPassCardSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function mintVipCardWhitelist(uint256 count, bytes calldata signature) public payable requiresWhitelist(signature) nonReentrant {
    require(stage_ == DaoStage.WHITELIST_VIP, "VIP Sale not active");
    require(totalVipCardWhitelistMints() + count - 1 < MAX_VIP_CARD_WHITELIST_SUPPLY, "Exceeds whitelist supply");
    require(totalVipCardSupply() < MAX_VIP_CARD_SUPPLY - MAX_VIP_CARD_RESERVED_SUPPLY + count - 1, "Exceeds max supply");
    require(count - 1 < MAX_MULTIMINT, "Exceeds mint limit");
    require(msg.value >= VIP_CARD_PRICE * count, "Insufficient payment");

    if (allowedVipCardMintCount(_msgSender()) > 0) {
      updateVipCardMintCount(_msgSender(), count);
    } else {
      revert("Minting limit exceeded");
    }

    for (uint256 i = 0; i < count; i++) {
      vipCardSupplyCounter.increment();
      vipCardWhitelistMintCounter.increment();
      _safeMint(_msgSender(), MAX_PASS_CARD_SUPPLY + MAX_VIP_CARD_RESERVED_SUPPLY + totalVipCardSupply());
    }

    payable(_splitter).transfer(msg.value);
  }

  function checkWhitelist(bytes calldata signature) public view requiresWhitelist(signature) returns (bool) {
    return true;
  }

  string private customBaseURI;

  function baseTokenURI() public view returns (string memory) {
    return customBaseURI;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function daoStage() external view virtual returns (DaoStage stage) {
    return stage_;
  }

  function mintPrice(uint64 count) external view virtual returns (uint256 price_) {
    require(count < MAX_MULTIMINT,"Exceeds multimint count.");
    uint256 activePrice = VIP_CARD_PRICE;
    if (stage_ == DaoStage.PASS) {
      activePrice = count==2 ? PASS_CARD_DIS_PRICE : PASS_CARD_PRICE;
    }

    return activePrice*count;
  }

  function release(address payable account) public virtual onlyOwner {
    _splitter.release(account);
  }
}
