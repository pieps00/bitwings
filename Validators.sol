pragma solidity ^0.5.17;

interface OwnableInterface {
	function owner() external view returns(address);
}

contract Ownable {
	OwnableInterface public ownable;

    function owner() public view returns(address) {
        return ownable.owner();
    }
	
	constructor(address _ownable) internal {
	    require(_ownable != address(0), "ownable must be set");
	    ownable = OwnableInterface(_ownable);
	}

	modifier onlyOwner() {
		require(msg.sender == ownable.owner(), "msg.sender should be equal to ownable.owner()");
		_;
	}
}

contract ValidatorSet is Ownable {
    mapping(address => uint256) public indexOfValidator;
    address[] public validatorsArray;

    event AddValidator(address indexed adminAddress, uint256 indexed validatorNumber);
	event RemoveValidator(address indexed adminAddress, uint256 indexed validatorNumber);

    constructor(address _initialValidator, address _ownable) public  Ownable(_ownable) {
        require(_initialValidator != address(0), "initialValidator must be set");
        indexOfValidator[_initialValidator] = 1;
		validatorsArray.push(_initialValidator);
    }

    modifier onlyValidator() {
        require(indexOfValidator[msg.sender] > 0, "only a validator is allowed");
        _;
    }

    function addValidator(address _validatorAddress) public onlyOwner {
        emit AddValidator(_validatorAddress, validatorsArray.length + 1);
        indexOfValidator[_validatorAddress] = validatorsArray.length + 1;
		validatorsArray.push(_validatorAddress);
    }

	function removeValidator(address _validatorAddress) public onlyOwner {
        emit RemoveValidator(_validatorAddress, indexOfValidator[_validatorAddress]);
		delete validatorsArray[indexOfValidator[_validatorAddress]];
		indexOfValidator[_validatorAddress] = 0;
    }


    /// Issue this log event to signal a desired change in validator set.
    /// This will not lead to a change in active validator set until
    /// finalizeChange is called.
    ///
    /// Only the last log event of any block can take effect.
    /// If a signal is issued while another is being finalized it may never
    /// take effect.
    ///
    /// _parent_hash here should be the parent block hash, or the
    /// signal will not be recognized.
    // event InitiateChange(bytes32 indexed _parent_hash, address[] _new_set);

    /// Get current validator set (last enacted or initial if no changes ever made)
    function getValidators() public view returns (address[] memory _validators) {
		return validatorsArray;
	}

    /// Called when an initiated change reaches finality and is activated.
    /// Only valid when msg.sender == SUPER_USER (EIP96, 2**160 - 2)
    ///
    /// Also called when the contract is first enabled for consensus. In this case,
    /// the "change" finalized is the activation of the initial set.
    // function finalizeChange() public;

}