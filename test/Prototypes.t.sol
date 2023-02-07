// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Prototypes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PrototypesTest is Test {
    Prototypes public prototypes;

    // key pairs from anvil
    // to be used with vm.sign
    address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint userPrivateKey = uint(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);

    address user2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    uint user2PrivateKey = uint(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);

    event ChainCreated(uint id);
    event ChainPurchased(uint id);

    // struct Chain {
    //     address purchaser;
    //     uint price;
    //     uint weight;
    //     uint timestamp;
    //     uint length;
    //     bool forSale;
    //     string arweaveHash;       
    // }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
       prototypes = new Prototypes();
    }

    function createChain(bool _mintToOwner) internal {
        uint _price = 10.567234 ether;
        uint _length = 2643;
        uint _weight = 10123;
        bool _forSale = true;
        string memory _arweaveHash = "ZewwyYPRnpEK-p3iGbDFsW6cu_R-e9m6JthAfZIGZ7A/";
        prototypes.createChain(_price, _length, _weight, _forSale, _arweaveHash, _mintToOwner);

        (address purchaser,uint price,uint weight,uint timestamp,uint length,bool forSale, string memory arweaveHash) = prototypes.idToChain(1);
        
        // if minToOwner is true, then the purchaser should equal this contract (the owner)
        assertEq(purchaser, _mintToOwner ? address(this) : address(0));

        // if minToOwner is true, the it should not be for sale, because the owner owns it
        assertEq(forSale, _mintToOwner ? false : true);

        // if minToOwner is true, then the timestamp should not zero, becuase it was set to zero in createChain()
        assertEq(timestamp, _mintToOwner ? 1 : 0);


        assertEq(price, _price);
        assertEq(weight, _weight);        
        assertEq(length, _length);        
        assertEq(arweaveHash, _arweaveHash);


    }

    function testCreateChain() public {        
        vm.expectEmit(false, false, false, true);
        // The event we expect
        emit ChainCreated(1);
        // The event we get
        createChain(false);
        assertEq(prototypes.ownerOf(1), address(prototypes));

        // // why cant you return a struct?
        // (address purchaser,uint price,uint weight,uint timestamp,uint length,bool forSale, string memory arweaveHash) = prototypes.idToChain(1);

        
    }

    function testCreateChainMintToOwner() public {        
        vm.expectEmit(false, false, false, true);
        // The event we expect
        emit ChainCreated(1);
        // The event we get
        createChain(true);
        assertEq(prototypes.ownerOf(1), address(this));
        (address purchaser,,,uint timestamp,,bool forSale,) = prototypes.idToChain(1);


        assertEq(purchaser, address(this));
        
        assertEq(timestamp, block.timestamp);

        assertEq(forSale, false);
       

        
    }

    function testNonOwnerCreateChain() public {
        uint _price = 10.567234 ether;
        uint _length = 2643;
        uint _weight = 10123;
        bool _forSale = true;
        bool _mintToOwner = false;
        string memory _arweaveHash = "ZewwyYPRnpEK-p3iGbDFsW6cu_R-e9m6JthAfZIGZ7A/";
        prototypes.createChain(_price, _length, _weight, _forSale, _arweaveHash, _mintToOwner);

        
        
        vm.prank(address(0xBEEF));
        vm.expectRevert("Ownable: caller is not the owner");
        prototypes.createChain(_price, _length, _weight, _forSale, _arweaveHash, _mintToOwner);
        
        
    }

    function getSignedMessage() public view returns (bytes memory sig) {

        // get the message to sign
        string memory message = prototypes.getResponsibilityMessageHash(1,user);
        uint length = bytes(message).length;
        // create message hash
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(length), message));
        
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, msgHash);

        sig = abi.encodePacked(r,s,v);

    }
    function testProveOwnerShip() public returns(bytes memory) {
        // get the message to sign
        testPurchase();
        // were signing a string of the id of the token in question
        string memory message = "1";
        uint length = bytes(message).length;
        // create message hash
        bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(length), message));
        
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, msgHash);
        vm.startPrank(user);
        bytes memory sig = abi.encodePacked(r,s,v);
        
        
        bool success = prototypes.proveOwnerShip(sig, 1);
        assertEq(success, true);
        vm.stopPrank();

        // lets try another user trying to prove owner ship of a chain they dont own

        vm.startPrank(user2);
        (v, r, s) = vm.sign(user2PrivateKey, msgHash);
        sig = abi.encodePacked(r,s,v);
        success = prototypes.proveOwnerShip(sig, 1);
        // it should be false because user2 does not own tokenId 1
        assertEq(success, false);
        vm.stopPrank();
    }

    function testPurchase() public {
        bytes memory sig = getSignedMessage();
        vm.deal(user, 100 ether);

        vm.expectEmit(false, false, false, true);
        // The event we expect
        emit ChainCreated(1);
        createChain(false);
        vm.startPrank(user);
        // vm.prank(address(0xBEEF));
        (,uint price,,,,,) = prototypes.idToChain(1);
        // since this contract is the owner, we dont need to send eth;
        
        vm.expectEmit(false, false, false, true);
        // The event we expect
        emit ChainPurchased(1);
        
        prototypes.purchase{value: price}(1,sig);

        (address purchaser,,uint weight,uint timestamp,uint length,bool forSale, string memory arweaveHash) = prototypes.idToChain(1);


        assertEq(purchaser, user);
        assertEq(timestamp, block.timestamp);
        assertEq(forSale, false);


        
        vm.stopPrank();


    }

    function testTokenUri() public {
        createChain(true);
        string memory tokenURI = prototypes.tokenURI(1);
        console.log(tokenURI); 

    }

    function testAddDecimals() public {
        string memory length = "264134143";
        string memory weight = "23432424234";
        string memory newWeight = prototypes.addDecimalsAndRound(weight,4,1);        
        string memory newLength = prototypes.addDecimalsAndRound(length,4,2);
        assertEq(newWeight, "2343242.4");
        assertEq(newLength, "26413.41");

        length = "2643";
        weight = "10123";
        newWeight = prototypes.addDecimalsAndRound(weight,2,2);        
        newLength = prototypes.addDecimalsAndRound(length,2,2);
        assertEq(newWeight, "101.23");
        assertEq(newLength, "26.43");


        length = "123";
        weight = "321";
        newWeight = prototypes.addDecimalsAndRound(weight,15,13);        
        newLength = prototypes.addDecimalsAndRound(length,15,13);
        assertEq(newWeight, ".0000000000003");
        assertEq(newLength, ".0000000000001");


        length = "44";
        weight = "22";
        newWeight = prototypes.addDecimalsAndRound(weight,2,1);        
        newLength = prototypes.addDecimalsAndRound(length,2,2);
        assertEq(newWeight, ".2");
        assertEq(newLength, ".44");
        console.log(newWeight);
        console.log(newLength);


        length = "4";
        weight = "2";
        newWeight = prototypes.addDecimalsAndRound(weight,4,2);        
        newLength = prototypes.addDecimalsAndRound(length,4,4);
        assertEq(newWeight, ".00");
        assertEq(newLength, ".0004");
        console.log(newWeight);
        console.log(newLength);

        // convert wei to Eth
        string memory priceInWei = Strings.toString(10 ether);
        string memory newPrice = prototypes.addDecimalsAndRound(priceInWei,18,4);        
        assertEq(newPrice, "10.0000");
        console.log(newPrice);


        // convert gwei to Eth
        priceInWei = Strings.toString(234_654 gwei);
        newPrice = prototypes.addDecimalsAndRound(priceInWei,18,15);        
        assertEq(newPrice, ".000234654000000");
        console.log(priceInWei);
        console.log(newPrice);


    }


}
