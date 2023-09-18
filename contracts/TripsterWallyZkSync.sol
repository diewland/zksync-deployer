// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TripsterWallyZkSync is ERC721A, Ownable {

    // config
    constructor() ERC721A("Tripster x Wally zkSync", "TRWAZKSYNC") {
        // _checkSupplyAndMint(MASTER_WALLET, MAX_MINT_PER_WALLET);
    }
    uint256 public MAX_SUPPLY = 3_333;
    uint256 public MAX_MINT_PER_WALLET = 3;
    uint256 public START_ID = 1;
    address private MASTER_WALLET = 0x6fF5723435b7dfC2371B57Fb5cB4c373E5995C78;

    bool public mintEnabled = true;
    bool public wlRound = true;
    bytes32 public merkleRoot = 0x05c956283909b748e1d1b2324a5e889c1fecd6c4179039babac6f6791d8140ef;
    string public baseURI = "ipfs://bafybeievosc27dmpwzbibltvhsgv3m3zjnqf7v4iqlm6johb7uq7gbz7we/";

    // start token id
    function _startTokenId() internal view virtual override returns (uint256) {
        return START_ID;
    }

    // metadata
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }

    // toggle sale, round
    function toggleSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }
    function toggleRound() external onlyOwner {
        wlRound = !wlRound;
    }

    // merkle tree
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    function verifyAddress(bytes32[] calldata _merkleProof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // mint
    function mint(uint quantity, bytes32[] calldata _merkleProof) external {
        require(mintEnabled, "Sale is not enabled");
        if (wlRound) require(verifyAddress(_merkleProof), "Invalid Proof");
        require(_numberMinted(msg.sender) + quantity <= MAX_MINT_PER_WALLET, "Over wallet limit");
        
        _checkSupplyAndMint(msg.sender, quantity);
    }
    function adminMint(uint quantity) external onlyOwner {
        _checkSupplyAndMint(msg.sender, quantity);
    }
    function _checkSupplyAndMint(address to, uint256 quantity) private {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Over supply");

        _mint(to, quantity);
    }

    // aliases
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }
    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - _totalMinted();
    }

    // transfer ownership
    function masterTransfer() external onlyOwner {
        transferOwnership(MASTER_WALLET);
    }

    // eth
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}
