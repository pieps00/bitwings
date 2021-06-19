pragma solidity ^0.5.17;

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

contract Faucet is Ownable {
    mapping(address => uint256) public lastCall;

    function () payable external noOwner {
        // require(now > lastCall[msg.sender] + 10 minutes, "is possible withdraw each 10 minutes only");
        lastCall[msg.sender] = now;
        uint256 amount = msg.value == 1 ether ?  5 ether : 1 ether;
        msg.sender.transfer(amount);
    }
    
    function withdrawAll() payable external onlyOwner {
         msg.sender.transfer(address(this).balance);
    }
    
}