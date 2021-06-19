pragma solidity ^0.5.17;

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

library ArrayManager {
    function add(address[] storage a, mapping(address => uint256) storage i, address b) internal {
        require(i[b] == 0, "The address is already in the array.");
        a.push(b);
        i[b] = a.length;
    }

    function remove(address[] storage a, mapping(address => uint256) storage i, address b) internal {
        require(i[b] != 0, "The address is not in the array.");
        uint256 index = i[b]-1;
        
        address userMoved = a[a.length-1];
        
        a[index] = userMoved;
        i[userMoved] = index+1;
        
		i[b] = 0;
        a.length--;
    }
    
    function getNElementsStartingAt(address[] memory _addresses, uint256 _nElements, uint256 _startingPos) internal pure returns(address[] memory) {
        if(_addresses.length <= _nElements) return _addresses;
        require(_startingPos < _addresses.length , "_startingPos <= _addresses.length");
        
        address[] memory selected = new address[](_nElements);

        uint256 m = 0;
        for( uint256 i = 0; i<_nElements; i++) {
            uint256 e = _startingPos+i;
            if( e > _addresses.length-1) {
                e = m++;
            }
            selected[i] = _addresses[e];
        }
        return selected;
    }
    
    function concat(address[] memory accounts, address[] memory accounts2) internal pure returns(address[] memory) {
        if( accounts.length == 0) return accounts2;
        if( accounts2.length == 0) return accounts;
        address[] memory returnArr = new address[](accounts.length + accounts2.length);
    
        uint i=0;
        for (; i < accounts.length; i++) {
            returnArr[i] = accounts[i];
        }
    
        uint j=0;
        while (j < accounts2.length) {
            returnArr[i++] = accounts2[j++];
        }
    
        return returnArr;
    } 
    
}

interface OwnableInterface {
	function owner() external view returns(address);
}

contract Ownable {
	OwnableInterface public ownable;

    function owner() public view returns(address) {
        return ownable.owner();
    }
	
	function initOwnable(address _ownable) internal {
	    require(_ownable != address(0), "ownable must be set");
	    ownable = OwnableInterface(_ownable);
	}

	modifier onlyOwner() {
		require(msg.sender == ownable.owner(), "msg.sender should be equal to ownable.owner()");
		_;
	}
}

contract Random {
    function random(uint256 _n) public view returns(uint256 randomNumber) {
        if( _n == 0 ) return 0;
        // uint256 blocknumber = block.number-1;
        // bytes32 blockHash = blockhash(blocknumber);
        // bytes32 hash = keccak256(abi.encodePacked(blockHash, msg.sender, now));
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, now));
        uint256 rawNumber = uint256(hash);
        randomNumber = rawNumber % _n;
    }
}



contract proximityExtraction is Random {
    using ArrayManager for address[];
    
    struct position {
        uint256 latitude;
        uint256 longitude;
    }
    
    mapping(address => position) public addressPosition;
    
    mapping(address => uint256) public addressIndex;
    
    mapping(uint256 => mapping(uint256 => address[])) public latLongAddresses;
    
    /* View methods */
	
    function getLatLongAddresses(uint256 _latitude, uint256 _longitude) public view returns (address[] memory) {
		return latLongAddresses[_latitude][_longitude];
	}
	
    
    function registerPosition (address _user, uint256 _latitude, uint256 _longitude) internal {
        if(addressIndex[_user] > 0) {
            removePosition(_user);
        }
        
        position memory p;
        
        p.latitude = _latitude;
        p.longitude = _longitude;
        
        addressPosition[_user] = p;
        
        latLongAddresses[_latitude][_longitude].add(addressIndex, _user);
    }
    
     function removePosition (address _user) internal {
        require(addressIndex[_user] != 0, "User is not registered.");
        
        position storage p = addressPosition[_user];
        
        latLongAddresses[p.latitude][p.longitude].remove(addressIndex, _user);
        
        p.latitude = 0;
        p.longitude = 0;
        
    }
    
    function nearBy(address _user) public view returns(address[] memory nearestUsers) {
        position memory p = addressPosition[_user];
        uint256 at = addressIndex[_user];

        
        uint256 target = 100;

        // Step 0
        address[] memory arr;
        arr = latLongAddresses[p.latitude + 0][p.longitude + 0];
        nearestUsers = nearestUsers.concat(arr.getNElementsStartingAt( target-nearestUsers.length, at));
        if(nearestUsers.length == target) return nearestUsers;
        
        uint8[20] memory arrLat =  [0,0,1,1,1,1,1,1,0,0,2,2,1,1,2,2,2,2,1,1];
        
        uint8[20] memory arrLong = [1,1,0,0,1,1,1,1,2,2,0,0,2,2,1,1,1,1,2,2];
        
        
        for ( uint8 n = 0; n<arrLat.length; n = n + 4 ) {
            arr = latLongAddresses[p.latitude + arrLat[n]][p.longitude + arrLong[n]];
            nearestUsers = nearestUsers.concat(arr.getNElementsStartingAt( target-nearestUsers.length, at));
            if(nearestUsers.length == target) return nearestUsers;
            
            arr = latLongAddresses[p.latitude - arrLat[n+1]][p.longitude - arrLong[n+1]];
            nearestUsers = nearestUsers.concat(arr.getNElementsStartingAt( target-nearestUsers.length, at));
            if(nearestUsers.length == target) return nearestUsers;
            
            arr = latLongAddresses[p.latitude + arrLat[n+2]][p.longitude - arrLong[n+2]];
            nearestUsers = nearestUsers.concat(arr.getNElementsStartingAt( target-nearestUsers.length, at));
            if(nearestUsers.length == target) return nearestUsers;
            
            arr = latLongAddresses[p.latitude - arrLat[n+3]][p.longitude + arrLong[n+3]];
            nearestUsers = nearestUsers.concat(arr.getNElementsStartingAt( target-nearestUsers.length, at));
            if(nearestUsers.length == target) return nearestUsers;
        }
            
        /*
        // Step 1
        arr = latLongAddresses[p.latitude + 0][p.longitude + 1];
        arr = latLongAddresses[p.latitude - 0][p.longitude - 1];
        arr = latLongAddresses[p.latitude + 1][p.longitude - 0];
        arr = latLongAddresses[p.latitude - 1][p.longitude + 0];

        
        // Step 2
        arr = latLongAddresses[p.latitude + 1][p.longitude + 1];
        arr =latLongAddresses[p.latitude - 1][p.longitude - 1];
        arr = latLongAddresses[p.latitude + 1][p.longitude - 1];
        arr = latLongAddresses[p.latitude - 1][p.longitude + 1];
        
        // Step 3
        arr = latLongAddresses[p.latitude + 0][p.longitude + 2];
        arr = latLongAddresses[p.latitude - 0][p.longitude - 2];
        arr = latLongAddresses[p.latitude + 2][p.longitude - 0];
        arr = latLongAddresses[p.latitude - 2][p.longitude + 0];
        
        // Step 4
        arr = latLongAddresses[p.latitude + 1][p.longitude + 2];
        arr = latLongAddresses[p.latitude - 1][p.longitude - 2];
        arr = latLongAddresses[p.latitude + 2][p.longitude - 1];
        arr = latLongAddresses[p.latitude - 2][p.longitude + 1];
        
        arr = latLongAddresses[p.latitude + 2][p.longitude + 1];
        arr = latLongAddresses[p.latitude - 2][p.longitude - 1];
        arr = latLongAddresses[p.latitude + 1][p.longitude - 2];
        arr = latLongAddresses[p.latitude - 1][p.longitude + 2];
        */
    }
    
}


contract BlockReward is Ownable, Random, proximityExtraction {
    using SafeMath for uint256;
        
    address[] public users;
    mapping(address => uint256) public indexOfUser;
    address[] public lastWinners;
    uint256[] public lastAmounts;
    mapping( address => uint256 ) public totalEarns;
    mapping( uint256 => address[] ) public winnersAtBlock;
    mapping( uint256 => uint256[] ) public amountsAtBlock;
    
    
    function init(address _ownable) public {
        require(address(ownable) == address(0), "Already initialized.");
        initOwnable(_ownable);
    }
    
    modifier onlySystem {
		require(msg.sender == 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE);
		_;
	}

	function reward(address[] memory, uint16[] memory) public onlySystem returns ( address[] memory winners, uint256[] memory amounts) {
	    if ( users.length == 0 ) return (  winners, amounts );
	    
	    uint256 indexFirstWinner = random(users.length);
	    address winner = users[indexFirstWinner];
	    
	    uint256 amountFirstWinner = 0.3 * 1e18;
	    uint256 amountOtherWinners = 0.7 * 1e18;
	    
	    address[] memory selectedUsers = nearBy(winner);
	    
	    delete lastWinners;
	    delete lastAmounts;
	    lastWinners.push(winner);
	    lastAmounts.push(amountFirstWinner);
	    totalEarns[winner] = totalEarns[winner].add(amountFirstWinner);
	    
	    for( uint256 i = 1; i<selectedUsers.length; i++ ) {
	        address user = selectedUsers[i];
    	    lastWinners.push(user);
    	    uint256 amount = amountOtherWinners.div(selectedUsers.length-1);
            lastAmounts.push(amount);
    	    totalEarns[user] = totalEarns[user].add(amount);
	    }
	    
	    winnersAtBlock[block.number] = lastWinners;
	    amountsAtBlock[block.number] = lastAmounts;
	    
	    
	    winners = lastWinners;
	    amounts = lastAmounts;
	}
	
	
	/* View methods */
	
    function getUsers() public view returns (address[] memory) {
		return users;
	}
	
    function getLastWinners() public view returns (address[] memory) {
		return lastWinners;
	}
	
    function getLastAmounts() public view returns (uint256[] memory) {
		return lastAmounts;
	}
	
	function getWinnersAtBlock(uint256 _block) public view returns (address[] memory) {
		return winnersAtBlock[_block];
	}
	
	function getAmountsAtBlock(uint256 _block) public view returns (uint256[] memory) {
		return amountsAtBlock[_block];
	}
	
	/* Register and Unregister Internal methods */
	
	function addUser(address _user, uint256 _latitude, uint256 _longitude) internal {
	    if(indexOfUser[_user] > 0) {
	         removeUser(_user);
	    }
        users.add(indexOfUser, _user);
        registerPosition(_user, _latitude, _longitude);
    }
    
	function removeUser(address _user) internal {
	    users.remove(indexOfUser, _user);
	    removePosition(_user);
    }
	
	
	/* Register and Unregister ADMIN methods */
    
    function adminAddUser(address _user, uint256 _latitude, uint256 _longitude) public onlyOwner {
        addUser(_user, _latitude, _longitude);
    }
    
	function adminRemoveUser(address _user) public onlyOwner {
	    removeUser(_user);
    }
    
    
    /* Register and Unregister methods */
    
    function addMe(uint256 _latitude, uint256 _longitude) public {
        addUser(msg.sender, _latitude, _longitude);
    }
    
	function removeMe() public {
	    removeUser(msg.sender);
    }
}
