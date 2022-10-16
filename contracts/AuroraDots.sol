// SPDX-License-Identifier: NOLICENSE
// CC0 NFT Project

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import { Base64 } from "./libraries/Base64.sol";
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract AuroraDots is ERC721URIStorage, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant maxSupply = 6;
    uint256 public constant mintPrice = 0.005 ether;
    uint256 public constant perWallet = 3;

    Counters.Counter private _tokenIds;

    string public description;

    constructor() ERC721("myNFT", "NFT") {}

    /**
     * @notice Generate metadata for TokenURI.
     */
    function dataURI(uint256 tokenId) public view returns(string memory){
        // NFT title
        string memory name = string(abi.encodePacked('NFT #', tokenId.toString()));
        
        // NFT image
        string memory image = Base64.encode(generateSVG(tokenId));

        return string(
            abi.encodePacked('data:application/json;base64,',
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"', name,
                '", "description": "', description,
                '", "image" : "data:image/svg+xml;base64,', image,
                '"}'
            )))
            )
        );
    }

    /**
     * @notice Generate RGB colors at random.
     */
    function generateRGB(uint256 seed) internal pure returns (uint256[3] memory) {
        uint256[3] memory rgb;

        for (uint256 i = 0 ; i < 3; i++) {
            rgb[i] = seed % 256;
            seed = getNumber(seed);
        }
        return rgb;
    }

    /**
     * @notice Generate a linear gradient from the first and last RGB.
     */
    function generateColors(uint256 seed) internal pure returns (string[8] memory) {
        string[8] memory colors;
        uint256[3] memory first = generateRGB(seed);
        uint256[3] memory last = generateRGB(getNumber(seed));

        colors[0] = string(abi.encodePacked('rgb(',first[0].toString(), ',', first[1].toString(), ',', first[2].toString(),')'));

        for (uint256 i = 1; i < 7; i++) {
            colors[i] = string(abi.encodePacked(
                'rgb(',
                ((last[0] * i + (first[0] * (7 - i))) / 7).toString(), ',',
                ((last[1] * i + (first[1] * (7 - i))) / 7).toString(), ',',
                ((last[2] * i + (first[2] * (7 - i))) / 7).toString(),')'));
        }

        colors[7] = string(abi.encodePacked('rgb(',last[0].toString(), ',', last[1].toString(), ',', last[2].toString(),')'));

        return colors;
    }
    
    /**
     * @notice Generate paths for main.
     */    
    function generateMainPath(uint256 x, uint256 y, bytes memory path, string[8] memory colors) internal pure returns (bytes memory) {
        for (uint256 j = 0; j < 8; j++){
            path = abi.encodePacked(path,
                '<path fill="', colors[j % 8],'" d="M', x.toString(),',', (y + j).toString(),'h1v1H', x.toString(),'z"/>'
            );
        }
        return path;
    }

    /**
     * @notice Generates paths for both ends.
     */    
    function generateEndsPath(uint256 x, uint256 y, bytes memory path, string[8] memory colors, uint256 num) internal pure returns (bytes memory) {
        bytes memory _path = path;

        if (num == 0 || num == 19) {
            for (uint256 i = 0; i < 4; i++){
                _path = abi.encodePacked(_path,
                    '<path fill="', colors[i % 8],'" d="M', x.toString(),',', (y + i).toString(),'h1v1H', x.toString(),'z"/>'
                );
            }
        } else if(num == 1 || num == 18) {
            for (uint256 j = 0; j < 6; j++){
                _path = abi.encodePacked(_path,
                    '<path fill="', colors[j % 8],'" d="M', x.toString(),',', (y + j).toString(),'h1v1H', x.toString(),'z"/>'
                );
            }
        }

        return _path;
    }


    /**
     * @notice Generate SVG that will be the metadata image.
     */
    function generateSVG(uint256 tokenId) internal pure returns (bytes memory) {
        uint256 seedCol = random(tokenId);
        uint256 seedPos = random(seedCol);
        uint256 lasty = 6 + seedCol % 13; // Start y position => y = 6 ~ 18.
        string[8] memory colors = generateColors(seedCol);
        bytes memory path = abi.encodePacked('<svg width="1024" height="1024" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">');
            
        for (uint256 i = 0; i < 20; i++){
            uint256 y = lasty; // Last y position.
            uint256 x = 6 + i; // Start x position => x = 6 ~ 25.

            // Both ends are short.
            if (1 < i && i < 18 ) {
                path = generateMainPath(x, y, path, colors);
            } else {
                path = generateEndsPath(x, y, path, colors, i);
            }

            if (seedPos % 2 == 0) {
                // if 0 => up
                y = lasty - (seedPos % 2 + 1);
                if (y < 6) { // y = 0 ~ 5 (len: 6) => top margin.
                    y = lasty + (seedPos % 2 + 1);
                }
            } else if (seedPos % 2 == 1) {
                // if 1 => down
                y = lasty + (seedPos % 2 + 1);
                if (18 < y) { // y = 26 ~ 31 (len: 6), + MainPath (len: 8) => bottom margin.
                    y = lasty - (seedPos % 2 + 1);
                }
            }

            lasty = y; // Update the last y position.
            seedPos /= 10; // New random seed.
       }
        path = abi.encodePacked(path, '</svg>');

        return path;
    }

    function mintNFT() public payable {
        uint256 newItemId = _tokenIds.current();

        require(newItemId < maxSupply, "Sold out");
        // perWallet
        require(msg.value >= mintPrice, "Must send the mint price");

        _safeMint(msg.sender, newItemId);

        _tokenIds.increment();
    }

    function reservedMint(uint256 _mintAmount) external onlyOwner {
        require(_tokenIds.current() + _mintAmount <= maxSupply, "Sold out");

        for (uint256 i = 0; i < _mintAmount; i++){
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    function getNumber(uint256 seed) internal pure returns (uint256) {
        return seed / 1000;
    }
    
    function random(uint256 _input) internal pure returns(uint256){
        return uint256(keccak256(abi.encodePacked(_input)));
    }

    function setDescription(string memory _description) external onlyOwner {
        description = _description;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return dataURI(tokenId);
    }

    function withdraw() external onlyOwner{
        require(address(this).balance > 0, 'No balance');
        require(payable(msg.sender).send(address(this).balance));
    }
}