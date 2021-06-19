pragma solidity ^0.5.17;

contract SuperOwnable {
	address public owner;
	address public newOwner;
	
	constructor() public {
	    owner = msg.sender;
	}

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
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

    function () external onlyOwner {      
    }
}