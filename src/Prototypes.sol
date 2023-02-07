// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Utils.sol";


contract Prototypes is ERC721, Ownable {
   using Counters for Counters.Counter;
    using Utils for string;

    string svgStart = "<svg xmlns='http://www.w3.org/2000/svg' width='500' height='500' version='1.1'> <rect x='5' y='5' width='490' height='490' fill='none' stroke='black'></rect> <rect x='10' y='10' width='480' height='480' fill='none' stroke='black'></rect> <g text-anchor='middle'> <text x='250' y='50'>PROTOTYPES</text> <text x='250' y='70'> Official receipt for prototype #1.</text> <text x='250' y='150'>A project by herestobeingonaroll.eth.</text> <text x='250' y='90'>Prototypes is a collection of 75 solid 24k gold chains.</text> <text x='250' y ='110'>All chains are handmade in Los Angeles by the creator. </text> </g> <g stroke='black' fill='none'> <circle cx='25' cy='197' r='2px'></circle> <circle cx='25' cy='227' r='2px'></circle> <circle cx='25' cy='257' r='2px'></circle> <circle cx='25' cy='287' r='2px'></circle> <circle cx='25' cy='317' r='2px'></circle> <circle cx='25' cy='347' r='2px'></circle> <circle cx='25' cy='377' r='2px'></circle> </g> <text id='id' x='35' y='200' class='heavy'></text> <text id='weight' x='35' y='230' class='heavy'></text> <text id='length' x='35' y='260' class='heavy'></text> <text id='owner' x='35' y='290' class='heavy'></text> <text id='purchaser' x='35' y='320' class='heavy'></text> <text id='price' x='35' y='350' class='heavy'></text> <text id='timestamp' x='35' y='380' class='heavy'></text> ";

    Counters.Counter private _tokenIdCounter;

    uint public max;

    string arweaveGateway = "https://arweave.net/";

    // string responsibilityMsg = string(abi.encodePacked(Strings.toString;

    

    mapping(uint => Utils.Chain) public idToChain;

    event ChainCreated(uint id);
    event ChainPurchased(uint id);


    constructor() ERC721("Prototypes", "PROTOTYPES") {
        max = 150;
        

    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        return this.onERC721Received.selector;
    }


    function getResponsibilityMessageHash(uint id, address purchaser) public view returns(string memory) {

        string memory str = string(abi.encodePacked("owner of address ",Strings.toHexString(purchaser), ", and purchaser of chain #",Strings.toString(id), ", accepts responsibility for any lost or stolen products."));
        return str;

    }

    function createChain(uint price, uint length, uint weight, bool forSale, string memory hash, bool mintToOwner) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current(); 
        require(tokenId <= max, "max amount reached");
        
        _safeMint(address(this), tokenId);

        Utils.Chain memory chain = Utils.Chain({
            purchaser: address(0), 
            price: price, 
            weight: weight, 
            timestamp: 0, 
            length: length,
            forSale: forSale,
            arweaveHash: hash
            });

        idToChain[tokenId] = chain;
        emit ChainCreated(tokenId);
        if(mintToOwner) {
            Utils.Chain storage _chain = idToChain[tokenId];
           _purchase(_chain, tokenId); 
        } 

    }

    function _purchase(Utils.Chain storage chain, uint id) private {
        chain.forSale = false;
        chain.purchaser = msg.sender;
        chain.timestamp = block.timestamp;
        _safeTransfer(address(this), msg.sender, id, "");
        emit ChainPurchased(id);

    }



    function purchase(uint id, bytes memory responsibilitysig) public payable {
        Utils.Chain storage chain = idToChain[id];
        require(chain.forSale == true, "chain not found or not for sale"); 
        require(msg.value == chain.price, "wrong price");
        require(verifyResponsibilitySig(responsibilitysig,id), "invalid signature");

        _purchase(chain, id);

       
    } 
    function addDecimalsAndRound(string memory str, uint decimcals, uint roundTo) public pure returns(string memory) {
        uint length = Utils.stringLength(str);

        if(length < decimcals) {
            
            for(uint i=0; i < decimcals-length; i++) {
                str = string(abi.encodePacked("0", str));
            }
            length = Utils.stringLength(str);
        }
        return Utils.insertAndRound(str, length-decimcals, roundTo);
    }


    function getTitle(string memory id) internal view returns(string memory) {
        string memory start = "<rect x='5' y='5' width='490' height='490' fill='none' stroke='black'></rect> <rect x='10' y='10' width='480' height='480' fill='none' stroke='black'></rect> <g text-anchor='middle'> <text x='250' y='50'>PROTOTYPES</text> <text x='250' y='70'> Official receipt for prototype #";
        string memory end = ".</text> <text x='250' y='150'>A project by herestobeingonaroll.eth.</text> <text x='250' y='90'>Prototypes is a collection of 150  solid 24k gold chains.</text> <text x='250' y ='110'>All chains are handmade in Los Angeles by the creator. </text> </g >";
        return string(abi.encodePacked(start, id, end));
    
    }  



    function getListItem(string memory id, string memory weight, string memory length, string memory owner, string memory purchaser, string memory price, string memory timestamp) internal view returns(string memory) {
        string[7] memory features = ["id: ", "weight: ", "length: ", "owner: ", "purchaser: ", "price: ", "timestamp: "];
        string[7] memory units = ["/150", " grams", " inches", "", "", " eth", ""];
        string[7] memory values = [id, weight, length, owner, purchaser, price, timestamp];
        purchaser = purchaser.truncateAddress();
        owner = owner.truncateAddress();
        // using "this" lets us pass a string memory to a function that takes a string calldata, which is required for addDecimalsAndRound()
        price = this.addDecimalsAndRound(price, 18, 3);
        length = this.addDecimalsAndRound(length, 2, 2);
        weight = this.addDecimalsAndRound(weight, 2, 2);
        
        
        bytes memory str;
        uint y = 200;
        for (uint i=0; i<7; i++) {
            // bytes memory circle = abi.encodePacked("<circle cx='25' cy='", Strings.toString(y - 3), "' r='2px' fill='none' stroke='black'></circle>");
            bytes memory text = abi.encodePacked("<text x='35' y='",Strings.toString(y), "' class='heavy'>", features[i], values[i], units[i], "</text>");
            str = abi.encodePacked(str, text);
            y += 30;
        }

        return string(str);



    }

    function getSvg(Utils.Chain memory chain, uint _id) internal view returns(string memory) {
        string memory id = Strings.toString(_id);
        string memory list = getListItem(
            id, 
            Strings.toString(chain.weight), 
            Strings.toString(chain.length), 
            Strings.toHexString(ownerOf(_id)), 
            Strings.toHexString(chain.purchaser), 
            Strings.toString(chain.price), 
            Strings.toString(chain.timestamp));

        string memory title = getTitle(id);
        string memory circles = " <circle fill='none' stroke='black' cx='25' cy='197' r='2px'></circle> <circle fill='none' stroke='black' cx='25' cy='227' r='2px'></circle> <circle fill='none' stroke='black' cx='25' cy='257' r='2px'></circle> <circle fill='none' stroke='black' cx='25' cy='287' r='2px'></circle> <circle fill='none' stroke='black' cx='25' cy='317' r='2px'></circle> <circle fill='none' stroke='black' cx='25' cy='347' r='2px'></circle> <circle fill='none' stroke='black' cx='25' cy='377' r='2px'></circle> ";
        return string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='500' height='500' version='1.1'>", 
            title, 
            circles, 
            list, 
            "</svg>"));
    }

    function getImages(uint id) internal view returns(string memory) {
        string memory arweaveUrl = string(abi.encodePacked(arweaveGateway, idToChain[id].arweaveHash));
        string memory imageTags;
        string memory title = string(abi.encodePacked("<text text-anchor='middle' x='50%' y='40'>chain #", Strings.toString(id), "</text>"));
        uint y = 75;

        for(uint i=1; i<=10; i++){
            imageTags = string(abi.encodePacked(imageTags,"<image x='2.5%' y='", Strings.toString(y), "' width='95%' href='",arweaveUrl, Strings.toString(i), ".jpg' />"));
            y += 2500;

        }

        return string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='100%' height='25500'>",
            title, 
            imageTags,
            "</svg>"));

    }
    

    function getJson(Utils.Chain memory chain, uint id) internal view returns(string memory)  {
        string memory svg = getSvg(chain, id);
        string memory images = getImages(id);
        string memory attributes = Utils.getAttributes(Strings.toString(chain.weight), Strings.toString(chain.length));
        string memory json = string(abi.encodePacked(
            '{"name": "prototype ',
            Strings.toString(id),
            '/150","description": "24k gold chain handmade in Los Angeles. A project by herestobeingonaroll.eth","image": "',
            'data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '","images": "',
            'data:image/svg+xml;base64,',
            Base64.encode(bytes(images)),
            '",',
            attributes,
            '}'
        ));
        return json;
    }



    function tokenURI(uint tokenId) public view override returns (string memory) {
        address owner = ownerOf(tokenId);
        Utils.Chain memory chain = idToChain[tokenId];
        string memory json = getJson(chain, tokenId);
        return string(abi.encodePacked("data:application/json;base64,",Base64.encode(bytes(json))));
    }



    function proveOwnerShip(bytes memory signature, uint id) public view returns(bool) {
        address signer = Utils.recoverAddr(signature, bytes(Strings.toString(id)));
        return signer == ownerOf(id);
    }

    function verifyResponsibilitySig(bytes memory signature, uint id) public view returns(bool) {
        string memory message = getResponsibilityMessageHash(id, msg.sender);
         address signer = Utils.recoverAddr(signature, bytes(message));
         return signer == msg.sender;
    }
}