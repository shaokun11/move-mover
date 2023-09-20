// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
contract ERC20Custom {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address constant public ERC20 = 0xd9145CCE52D386f254917e481eB44e9943F39138;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _delegate() internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), ERC20, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _delegate();
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _delegate();
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _delegate();
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _delegate();
    }

    function decreaseAllowance(address spender, uint256 requestedDecrease) public returns (bool) {
        _delegate();
    }

    function mint(address _to, uint _amount) public {
        _delegate();
    }
}