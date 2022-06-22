// SPDX-License-Identifier: GPL3
pragma solidity >=0.8.14 <0.9.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WhiteList {
    bytes32 private root;
    uint256 listLength;
    address owner;
    uint256 visited;
    using MerkleProof for bytes32[];

    constructor() {
        owner = msg.sender;
    }

    function verify(
        bytes32[] memory _proof,
        bytes32 _leaf,
        bytes32 _root
    ) internal pure returns (bool) {
        bytes32 computedHash = _leaf;

        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofItem = _proof[i];

            if (computedHash <= proofItem) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofItem)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofItem, computedHash)
                );
            }
        }
        return computedHash == _root;
    }

    function calcRootHash(
        uint256 _idx,
        uint256 _len,
        bytes32 _leafHash,
        bytes32[] memory _proof
    ) internal pure returns (bytes32 _rootHash) {
        if (_len == 0) {
            return bytes32(0);
        }

        uint256 _proofIdx = 0;
        bytes32 _nodeHash = _leafHash;

        while (_len > 1) {
            uint256 _peerIdx = (_idx / 2) * 2;
            bytes32 _peerHash = bytes32(0);
            if (_peerIdx == _idx) {
                _peerIdx += 1;
            }
            if (_peerIdx < _len) {
                _peerHash = _proof[_proofIdx];
                _proofIdx += 1;
            }

            bytes32 _parentHash = bytes32(0);
            if (_peerIdx >= _len && _idx >= _len) {
                // pass, _parentHash = bytes32(0)
            } else if (_peerIdx > _idx) {
                _parentHash = keccak256(abi.encodePacked(_nodeHash, _peerHash));
            } else {
                _parentHash = keccak256(abi.encodePacked(_peerHash, _nodeHash));
            }

            _len = (_len - 1) / 2 + 1;
            _idx = _idx / 2;
            _nodeHash = _parentHash;
        }

        return _nodeHash;
    }

    modifier adminOnly() {
        require(msg.sender == owner, "Only admin allow");
        _;
    }

    function changeAdmin(address _newOwner) public adminOnly {
        owner = _newOwner;
    }

    function setRoot(bytes32 _root, uint256 _length) public adminOnly {
        root = _root;
        listLength = _length;
    }

    function addAddress(address _newAddress, bytes32[] memory _proof)
        public
        adminOnly
    {
        bytes32 leaf = keccak256(abi.encodePacked(_newAddress));
        bytes32 newRoot = calcRootHash(_len, _len + 1, _leafHash, _proof);
        root = newRoot;
        listLength++;
    }

    function mint(bytes32[] memory _proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verify(_proof, leaf, root), "You are not in the list");
        return true;
    }

    function getRoot() public view adminOnly returns (bytes32) {
        return root;
    }
}
