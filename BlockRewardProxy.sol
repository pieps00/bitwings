pragma solidity ^0.5.17;

contract Proxy {
  function implementation() public view returns (address);

  function () external payable {
    address impl = implementation();
    require(impl != address(0), "impl != address(0)");

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}
library RW {
    function read(bytes32 _position) internal view returns (address addr) {
        assembly {
            addr := sload(_position)
        }
    }
    function write(bytes32 _position, address _addr) internal {
        assembly {
            sstore(_position, _addr)
        }
    }
}

interface OwnableInterface {
	function owner() external view returns(address);
}

contract ProxyOwnable {
    using RW for bytes32;
    bytes32 private constant proxyOwnablePosition = keccak256("org.tl.proxy.Ownable");
    
    function proxyOwnable() public view returns(address) {
        return proxyOwnablePosition.read();
    }
    

    function proxyOwner() public view returns (address) {
        return OwnableInterface(proxyOwnable()).owner();
    }
	
	constructor(address _ownable) internal {
	    require(_ownable != address(0), "ownable must be set");
	    proxyOwnablePosition.write(_ownable);
	}

	modifier onlyProxyOwner() {
		require(msg.sender == proxyOwner(), "msg.sender should be equal to ownable.owner()");
		_;
	}
}
/*
interface BlockReward {
    function init(address _ownable) external;
}
*/
contract ExternalOwnedProxy is Proxy, ProxyOwnable {
    using RW for bytes32;

    bytes32 private constant implementationPosition = keccak256("org.tl.proxy.implementation");
    function implementation() public view returns (address impl) {
        impl = implementationPosition.read();
    }

    event Upgraded(address indexed implementation);
    function upgradeTo(address _newImpl) public onlyProxyOwner {
        implementationPosition.write(_newImpl);
        emit Upgraded(_newImpl);
    }

    function upgradeToAndCall(address _newImpl, bytes memory _data) public payable onlyProxyOwner {
        upgradeTo(_newImpl);
        (bool txOk, ) = address(this).call.value(msg.value)(_data);
        require(txOk, "txOk");
    }

    constructor(address _ownable, address _implementation) public ProxyOwnable(_ownable)  {
        implementationPosition.write(_implementation);
        // BlockReward(address(this)).init(_ownable);
    }
}