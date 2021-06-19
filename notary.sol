pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}
	
	modifier noOwner() {
        if (msg.sender == owner) return;
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract Adminable is Ownable {
    mapping(address => bool) public admin;

    event AdminSet(address indexed adminAddress, bool indexed status);

	constructor() public {
        admin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender], "admin[msg.sender]");
        _;
    }

    function setAdmin(address adminAddress, bool status) public onlyOwner {
        emit AdminSet(adminAddress, status);
        admin[adminAddress] = status;
    }
}

contract Notary is Adminable {
    struct certificate { 
        address authority;
        bytes authoritySignature;
        bytes32 hashDocument;
        uint256 salt;
    }
    mapping(bytes32 => certificate) certificateArchive;
    
    function setCertificate( bytes32 _hashCertificate, address _authority, bytes memory _authoritySignature, bytes32 _hashDocument, uint256 _salt) public onlyAdmin returns (bool){        
        certificateArchive[_hashCertificate] = certificate(_authority, _authoritySignature, _hashDocument, _salt);
        return true;
    }

    function readCertificate(bytes32 _hashCertificate) public view returns (address authority, bytes memory authoritySignature, bytes32 hashDocument, uint256 salt) { 
        certificate memory cert = certificateArchive[_hashCertificate];
        authority = cert.authority;
        authoritySignature = cert.authoritySignature;
        hashDocument = cert.hashDocument;
        salt = cert.salt;
    }
}
