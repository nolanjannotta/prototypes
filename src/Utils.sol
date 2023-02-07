pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


library Utils {
    using ECDSA for bytes32;


    struct Chain {
        address purchaser;
        uint price;
        uint weight;
        uint timestamp;
        uint length;
        bool forSale;
        string arweaveHash;   
    }

    function getAttributes(string memory _weight, string memory _length) external pure returns (string memory) {
        return string(abi.encodePacked(
                                '"attributes": [{"trait_type": "Weight", "value": "', 
                                _weight,
                                'g',
                                '"},{"trait_type": "length", "value": "',
                                _length,
                                'in"}, {"trait_type": "Material", "value": "24k gold"},{"trait_type": "Origin", "value": "Los Angeles"}]'
                                
                                ));

    }


    function truncateAddress(string calldata addr) external pure returns (string memory) {
        bytes memory _truncate = abi.encodePacked(addr[:5], "...", addr[38:]);
        return string(_truncate);
    }
    function insertAndRound(string calldata str, uint index, uint decimals) external pure returns(string memory){
        string memory newStr = string(abi.encodePacked(str[:index],".", str[index:index+decimals]));
        return(newStr);
    }

    

    // taken from the ENS contract
    function stringLength(string memory s) external pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }


    function recoverAddr(bytes memory signature, bytes memory message) external view returns(address) {
        // address owner = ownerOf(id);
        bytes32 _hash = ECDSA.toEthSignedMessageHash(message);
        address signer = ECDSA.recover(_hash, signature);
        return signer;

    }



}