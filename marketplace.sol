// SPDX-License-Identifier: MIT OR Apache-2.0 
pragma solidity ^0.8.4;

//A decentralized Marketplace System Using Smart Contract to Preserve Reviewer Anonymity

import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // for non-reentreance attack


contract Marketplace is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  address payable owner; 
  //uint256 listingPrice = 0.000000000000000001 ether;
  uint256 listingPrice = 2 ether;
  //uint256 reviewFee = 0.000000000000000001 ether;
  uint256 reviewFee = 5 ether;               // 5000000000000000000 we = 5 ether  || 10000000000000000000 = 10 ether

  constructor() {
    owner = payable(msg.sender);  // who ever deploys the contract is the owner of the Marketplace
  }

  struct Buyers{
    address buyer;
  }
   struct Reviewers{
    address payable reviewerAdd;
  }

  struct MarketItem {
    uint itemId;
    address contractAdd;
    address payable sellerAdd;
    uint soldQuantity;
    Reviewers[] reviewer;
    Buyers[] buyer;
    bytes32[] secretKey;
    string[] review;
    uint256 price;
    uint256 quantity;
    string itemName;
    string itemDetails;
  }

  
  Reviewers[] rev;
  Buyers[] buy;
  bytes32[] secKey;
  string[] revi;

  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed contractAdd,
    address sellerAdd,
    uint soldQuantity,
    Reviewers[] reviewer,
    Buyers[] buyer,
    bytes32[] secretKey,
    string[] review,
    uint256 price,
    uint256 quantity,
    string itemName,
    string itemDetails
  );


  function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
    return idToMarketItem[marketItemId];
  }

  function createMarketItem(
    address contractAdd,
    uint256 price,
    uint256 quantity,
    string memory _ItemName,
    string memory _ItemDetails
  ) public payable nonReentrant {
    require(price > 0, "Price can not be empty");
    require(msg.value == listingPrice, "Value must be equal to listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    idToMarketItem[itemId].itemId = itemId;
    idToMarketItem[itemId].contractAdd  = contractAdd;
    idToMarketItem[itemId].sellerAdd  = payable(msg.sender); // sellerAdd
    idToMarketItem[itemId].soldQuantity  = 0;
    idToMarketItem[itemId].price   = price;
    idToMarketItem[itemId].quantity  = quantity;
    idToMarketItem[itemId].itemName  = _ItemName;
    idToMarketItem[itemId].itemDetails = _ItemDetails;

    payable(owner).transfer(listingPrice);  // the owner of the smart contract
    console.log("Your item has been listed and the owner has received the listing price!");

    emit MarketItemCreated (
    itemId,
    contractAdd,
    msg.sender,
    0,
    rev,
    buy,
    secKey,
    revi,
    price,
    quantity,
    _ItemName,
    _ItemDetails
  );

  }


  function createMarketSale(
    uint256 itemId,
    string memory _sKey,
    uint256 quantity
    ) public payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    require(idToMarketItem[itemId].quantity>0 , "This item is sold out !");
    require(msg.value == (price*quantity)+reviewFee, "Please submit the total item price added to the review fee to complete the purchase");
    address buyerAdd = msg.sender;
    idToMarketItem[itemId].buyer.push(Buyers({buyer: buyerAdd}));
    idToMarketItem[itemId].sellerAdd.transfer(msg.value-reviewFee);
    idToMarketItem[itemId].secretKey.push(keccak256(abi.encodePacked(_sKey)));
     //                                     reviewerAdd: payable(address(0)),
     //                                     review: ""}));
      //                                    //keyUsed:0
    idToMarketItem[itemId].quantity -= quantity;
    idToMarketItem[itemId].soldQuantity = idToMarketItem[itemId].soldQuantity + quantity;
    console.log("Item purchase has been completed !");
  }

  function createReview(
    string memory _sKey,
    string memory _Review
    ) public payable nonReentrant {
        
    uint itemCount = _itemIds.current();
    uint found = 0;
    uint matchItem = 0;
    uint matchRev = 0;
    for (uint i = 0; i < itemCount+1; i++) {
      if (idToMarketItem[i+1].soldQuantity>0){
        for (uint j = 0; j < idToMarketItem[i+1].secretKey.length; j++) {
          if (idToMarketItem[i+1].secretKey[j] == keccak256(abi.encodePacked(_sKey))){
              found = 1;
              bytes32 rnd = randomString(10);
              bytes32 newKey = rnd;
              idToMarketItem[i+1].secretKey[j] = keccak256(abi.encodePacked(idToMarketItem[i+1].secretKey[j]^newKey));
              matchItem = i+1;
              matchRev = j;
              break;
          }
        }
      }
    }
    require( found == 1 , "The entered secret key is either not registered or has been used. Please enter another secret key");
    //idToMarketItem[matchItem].review[matchRev].keyUsed = 1;
    idToMarketItem[matchItem].review.push(_Review);
    idToMarketItem[matchItem].reviewer.push(Reviewers({reviewerAdd: payable(msg.sender)})); 
    payable(msg.sender).transfer(reviewFee);
    console.log("Item review has been added and the review fee has been returned to the reviewer !");
  }

    uint cnt = 1;

    function randomString(uint size) public  payable returns(bytes32){
        bytes memory randString = new bytes(size);
        bytes memory chars = new bytes(26);
        chars="abcdefghijklmnopqrstuvwxyz";
        for (uint i=0;i<size;i++){
            uint randNum=random(26);
            randString[i]=chars[randNum];
        }
        return bytes32(randString);
    }

    function random(uint number) public payable returns(uint){
        cnt++;
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender,cnt))) % number;
    }

  
}
