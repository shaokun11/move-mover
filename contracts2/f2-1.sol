pragma solidity 0.8.17;


interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// (c) 2022-2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.


struct WarpMessage {
    bytes32 sourceChainID;
    address originSenderAddress;
    bytes32 destinationChainID;
    address destinationAddress;
    bytes payload;
}

struct WarpBlockHash {
    bytes32 sourceChainID;
    bytes32 blockHash;
}

interface WarpMessenger {
    event SendWarpMessage(
        bytes32 indexed destinationChainID,
        address indexed destinationAddress,
        address indexed sender,
        bytes message
    );

    // sendWarpMessage emits a request for the subnet to send a warp message from [msg.sender]
    // with the specified parameters.
    // This emits a SendWarpMessage log from the precompile. When the corresponding block is accepted
    // the Accept hook of the Warp precompile is invoked with all accepted logs emitted by the Warp
    // precompile.
    // Each validator then adds the UnsignedWarpMessage encoded in the log to the set of messages
    // it is willing to sign for an off-chain relayer to aggregate Warp signatures.
    function sendWarpMessage(
        bytes32 destinationChainID,
        address destinationAddress,
        bytes calldata payload
    ) external;

    // getVerifiedWarpMessage parses the pre-verified warp message in the
    // predicate storage slots as a WarpMessage and returns it to the caller.
    // If the message exists and passes verification, returns the verified message
    // and true.
    // Otherwise, returns false and the empty value for the message.
    function getVerifiedWarpMessage(uint32 index)
        external view
        returns (WarpMessage calldata message, bool valid);

    // getVerifiedWarpBlockHash parses the pre-verified WarpBlockHash message in the
    // predicate storage slots as a WarpBlockHash message and returns it to the caller.
    // If the message exists and passes verification, returns the verified message
    // and true.
    // Otherwise, returns false and the empty value for the message.
    function getVerifiedWarpBlockHash(uint32 index)
        external view
        returns (WarpBlockHash calldata warpBlockHash, bool valid);

    // getBlockchainID returns the snow.Context BlockchainID of this chain.
    // This blockchainID is the hash of the transaction that created this blockchain on the P-Chain
    // and is not related to the Ethereum ChainID.
    function getBlockchainID() external view returns (bytes32 blockchainID);
}

// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

struct TeleporterMessageReceipt {
    uint256 receivedMessageID;
    address relayerRewardAddress;
}

struct TeleporterMessageInput {
    bytes32 destinationChainID;
    address destinationAddress;
    TeleporterFeeInfo feeInfo;
    uint256 requiredGasLimit;
    address[] allowedRelayerAddresses;
    bytes message;
}

struct TeleporterMessage {
    uint256 messageID;
    address senderAddress;
    address destinationAddress;
    uint256 requiredGasLimit;
    address[] allowedRelayerAddresses;
    TeleporterMessageReceipt[] receipts;
    bytes message;
}

struct TeleporterFeeInfo {
    address contractAddress;
    uint256 amount;
}

/**
 * @dev Interface that describes functionalities for a cross-chain messenger implementing the Teleporter protcol.
 */
interface ITeleporterMessenger {
    /**
     * @dev Emitted when sending a Teleporter message cross-chain.
     */
    event SendCrossChainMessage(
        bytes32 indexed destinationChainID,
        uint256 indexed messageID,
        TeleporterMessage message,
        TeleporterFeeInfo feeInfo
    );

    /**
     * @dev Emitted when an additional fee amount is added to a Teleporter message that had previously
     * been sent, but not yet delivered to the destination chain.
     */
    event AddFeeAmount(
        bytes32 indexed destinationChainID,
        uint256 indexed messageID,
        TeleporterFeeInfo updatedFeeInfo
    );

    /**
     * @dev Emitted when a Teleporter message is being delivered on the destination chain to an address,
     * but message execution fails. Failed messages can then be retried with `retryMessageExecution`
     */
    event MessageExecutionFailed(
        bytes32 indexed originChainID,
        uint256 indexed messageID,
        TeleporterMessage message
    );

    /**
     * @dev Emitted when a Teleporter message is successfully executed with the
     * specified destination address and message call data. This can occur either when
     * the message is initially received, or on a retry attempt.
     *
     * Each message received can be executed successfully at most once.
     */
    event MessageExecuted(
        bytes32 indexed originChainID,
        uint256 indexed messageID
    );

    /**
     * @dev Emitted when a TeleporterMessage is successfully received.
     */
    event ReceiveCrossChainMessage(
        bytes32 indexed originChainID,
        uint256 indexed messageID,
        address indexed deliverer,
        address rewardRedeemer,
        TeleporterMessage message
    );

    /**
     * @dev Emitted when an account redeems accumulated relayer rewards.
     */
    event RelayerRewardsRedeemed(
        address indexed redeemer,
        address indexed asset,
        uint256 amount
    );

    /**
     * @dev Called by transactions to initiate the sending of a cross-chain message.
     */
    function sendCrossChainMessage(
        TeleporterMessageInput calldata messageInput
    ) external returns (uint256 messageID);

    /**
     * @dev Called by transactions to retry the sending of a cross-chain message.
     *
     * Retriggers the sending of a message previously emitted by sendCrossChainMessage that has not yet been acknowledged
     * with a receipt from the destination chain. This may be necessary in the unlikely event that less than the required
     * threshold of stake weight successfully inserted the message in their messages DB at the time of the first submission.
     * The message is checked to have already been previously submitted by comparing its message hash against those kept in
     * state until a receipt is received for the message.
     */
    function retrySendCrossChainMessage(
        bytes32 destinationChainID,
        TeleporterMessage calldata message
    ) external;

    /**
     * @dev Adds the additional fee amount to the amount to be paid to the relayer that delivers
     * the given message ID to the destination chain.
     *
     * The fee contract address must be the same asset type as the fee asset specified in the original
     * call to sendCrossChainMessage. Returns a failure if the message doesn't exist or there is already
     * receipt of delivery of the message.
     */
    function addFeeAmount(
        bytes32 destinationChainID,
        uint256 messageID,
        address feeContractAddress,
        uint256 additionalFeeAmount
    ) external;

    /**
     * @dev Receives a cross-chain message, and marks the `relayerRewardAddress` for fee reward for a successful delivery.
     *
     * The message specified by `messageIndex` must be provided at that index in the access list storage slots of the transaction,
     * and is verified in the precompile predicate.
     */
    function receiveCrossChainMessage(
        uint32 messageIndex,
        address relayerRewardAddress,
        bytes memory warpMessage
    ) external;

    /**
     * @dev Retries the execution of a previously delivered message by verifying the payload matches
     * the hash of the payload originally delivered, and calling the destination address again.
     *
     * Intended to be used if message excution failed on initial delivery of the Teleporter message.
     * For example, this may occur if the original required gas limit was not sufficient for the message
     * execution, or if the destination address did not contain a contract, but a compatible contract
     * was later deployed to that address. Messages are ensured to be successfully executed at most once.
     */
    function retryMessageExecution(
        bytes32 originChainID,
        TeleporterMessage calldata message
    ) external;

    /**
     * @dev Sends the receipts for the given `messageIDs`.
     *
     * Sends the receipts of the specified messages in a new message (with an empty payload) back to the origin chain.
     * This is intended to be used if the message receipts were originally included in messages that were dropped
     * or otherwise not delivered in a timely manner.
     */
    function sendSpecifiedReceipts(
        bytes32 originChainID,
        uint256[] calldata messageIDs,
        TeleporterFeeInfo calldata feeInfo,
        address[] calldata allowedRelayerAddresses
    ) external returns (uint256 messageID);

    /**
     * @dev Sends any fee amount rewards for the given fee asset out to the caller.
     */
    function redeemRelayerRewards(address feeAsset) external;

    /**
     * @dev Gets the hash of a given message stored in the EVM state, if the message exists.
     */
    function getMessageHash(
        bytes32 destinationChainID,
        uint256 messageID
    ) external view returns (bytes32 messageHash);

    /**
     * @dev Checks whether or not the given message has been received by this chain.
     */
    function messageReceived(
        bytes32 originChainID,
        uint256 messageID
    ) external view returns (bool delivered);

    /**
     * @dev Returns the address the relayer reward should be sent to on the origin chain
     * for a given message, assuming that the message has already been delivered.
     */
    function getRelayerRewardAddress(
        bytes32 originChainID,
        uint256 messageID
    ) external view returns (address relayerRewardAddress);

    /**
     * Gets the current reward amount of a given fee asset that is redeemable by the given relayer.
     */
    function checkRelayerRewardAmount(
        address relayer,
        address feeAsset
    ) external view returns (uint256);

    /**
     * @dev Gets the fee asset and amount for a given message.
     */
    function getFeeInfo(
        bytes32 destinationChainID,
        uint256 messageID
    ) external view returns (address feeAsset, uint256 feeAmount);

    /**
     * @dev Gets the number of receipts that have been sent to the given destination chain ID.
     */
    function getReceiptQueueSize(
        bytes32 chainID
    ) external view returns (uint256 size);

    /**
     * @dev Gets the receipt at the given index in the queue for the given chain ID.
     * @param chainID The chain ID to get the receipt queue for.
     * @param index The index of the receipt to get, starting from 0.
     */
    function getReceiptAtIndex(
        bytes32 chainID,
        uint256 index
    ) external view returns (TeleporterMessageReceipt memory receipt);
}

// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.


/**
 * @dev ReceiptQueue is a convenience library that creates a queue-like interface of
 * TeleporterMessageReceipt structs. It provides FIFO properties.
 * Note: All functions in this library are internal so that the library is not deployed as a contract.
 */
library ReceiptQueue {
    struct TeleporterMessageReceiptQueue {
        uint256 first;
        uint256 last;
        mapping(uint256 => TeleporterMessageReceipt) data;
    }

    // The maximum number of receipts to include in a single message.
    uint256 private constant _MAXIMUM_RECEIPT_COUNT = 5;

    // solhint-disable private-vars-leading-underscore
    /**
     * @dev Adds a receipt to the queue.
     */
    function enqueue(
        TeleporterMessageReceiptQueue storage queue,
        TeleporterMessageReceipt memory receipt
    ) internal {
        queue.data[queue.last++] = receipt;
    }

    /**
     * @dev Removes the oldest outstanding receipt from the queue.
     *
     * Requirements:
     * - The queue must be non-empty.
     */
    function dequeue(
        TeleporterMessageReceiptQueue storage queue
    ) internal returns (TeleporterMessageReceipt memory result) {
        uint256 first_ = queue.first;
        require(queue.last != first_, "ReceiptQueue: empty queue");
        result = queue.data[first_];
        delete queue.data[first_];
        queue.first = first_ + 1;
    }

    /**
     * @dev Returns the outstanding receipts for the given chain ID that should be included in the next message sent.
     */
    function getOutstandingReceiptsToSend(
        TeleporterMessageReceiptQueue storage queue
    ) internal returns (TeleporterMessageReceipt[] memory result) {
        // Get the current outstanding receipts for the given chain ID.
        // If the queue contract doesn't exist, there are no outstanding receipts to send.
        uint256 resultSize = size(queue);
        if (resultSize == 0) {
            return new TeleporterMessageReceipt[](0);
        }

        // Calculate the result size as the minimum of the number of receipts and maximum batch size.
        if (resultSize > _MAXIMUM_RECEIPT_COUNT) {
            resultSize = _MAXIMUM_RECEIPT_COUNT;
        }

        result = new TeleporterMessageReceipt[](resultSize);
        for (uint256 i = 0; i < resultSize; ++i) {
            result[i] = dequeue(queue);
        }
    }

    /**
     * @dev Returns the number of outstanding receipts in the queue.
     */
    function size(
        TeleporterMessageReceiptQueue storage queue
    ) internal view returns (uint256) {
        return queue.last - queue.first;
    }

    /**
     * @dev Returns the receipt at the given index in the queue.
     */
    function getReceiptAtIndex(
        TeleporterMessageReceiptQueue storage queue,
        uint256 index
    ) internal view returns (TeleporterMessageReceipt memory) {
        require(index < size(queue), "ReceiptQueue: index out of bounds");
        return queue.data[queue.first + index];
    }
    // solhint-enable private-vars-leading-underscore
}

// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.


/**
 * @dev Provides a wrapper used for calling an ERC20 transferFrom method
 * to receive tokens to a contract from msg.sender.
 *
 * Checks the balance of the recipient before and after the call to transferFrom, and
 * returns balance increase. Designed for safely handling ERC20 "fee on transfer" and "burn on transfer" implementations.
 *
 * Note: A reentrancy guard must always be used when calling token.safeTransferFrom in order to
 * prevent against possible "before-after" pattern vulnerabilities.
 */
library SafeERC20TransferFrom {
    using SafeERC20 for IERC20;

    // solhint-disable private-vars-leading-underscore
    function safeTransferFrom(
        IERC20 erc20,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = erc20.balanceOf(address(this));
        erc20.safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = erc20.balanceOf(address(this));

        require(
            balanceAfter > balanceBefore,
            "SafeERC20TransferFrom: balance not increased"
        );

        return balanceAfter - balanceBefore;
    }
    // solhint-enable private-vars-leading-underscore
}

// (c) 2022-2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.


/**
 * @dev Interface that cross-chain applications must implement to receive messages from Teleporter.
 */
interface ITeleporterReceiver {
    /**
     * @dev Called by TeleporterMessenger on the receiving chain.
     *
     * @param originChainID is provided by the TeleporterMessenger contract.
     * @param originSenderAddress is provided by the TeleporterMessenger contract.
     * @param message is the TeleporterMessage payload set by the sender.
     */
    function receiveTeleporterMessage(
        bytes32 originChainID,
        address originSenderAddress,
        bytes calldata message
    ) external;
}

// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.


/**
 * @dev Abstract contract that helps implement reentrancy guards between functions for sending and receiving.
 *
 * Consecutive calls for sending functions should work together, same for receive functions, but recursive calls
 * should be detected as a reentrancy and revert.
 *
 * Calls between send and receive functions should also be allowed, but not in the case it ends up being a recursive
 * send or receive call. For example the following should fail: send -> receive -> send.
 */
abstract contract ReentrancyGuards {
    // Send and Receive reentrancy guards
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _sendEntered;
    uint256 internal _receiveEntered;

    // senderNonReentrant modifier makes sure we can not reenter between sender calls.
    // This modifier should be used for messenger sender functions that have external calls and do not want to allow
    // recursive calls with other sender functions.
    modifier senderNonReentrant() {
        require(
            _sendEntered == _NOT_ENTERED,
            "ReentrancyGuards: sender reentrancy"
        );
        _sendEntered = _ENTERED;
        _;
        _sendEntered = _NOT_ENTERED;
    }

    // receiverNonReentrant modifier makes sure we can not reenter between receiver calls.
    // This modifier should be used for messenger receiver functions that have external calls and do not want to allow
    // recursive calls with other receiver functions.
    modifier receiverNonReentrant() {
        require(
            _receiveEntered == _NOT_ENTERED,
            "ReentrancyGuards: receiver reentrancy"
        );
        _receiveEntered = _ENTERED;
        _;
        _receiveEntered = _NOT_ENTERED;
    }

    constructor() {
        _sendEntered = _NOT_ENTERED;
        _receiveEntered = _NOT_ENTERED;
    }
}

/**
 * @dev Implementation of the {ITeleporterMessenger} interface.
 *
 * This implementation is used to send messages cross-chain using the WarpMessenger precompile,
 * and to receive messages sent from other chains. Teleporter contracts should be deployed through Nick's method
 * of universal deployer, such that the same contract is deployed at the same address on all chains.
 */
contract TeleporterMessenger is ITeleporterMessenger, ReentrancyGuards {
    using SafeERC20 for IERC20;
    using ReceiptQueue for ReceiptQueue.TeleporterMessageReceiptQueue;

    struct SentMessageInfo {
        bytes32 messageHash;
        TeleporterFeeInfo feeInfo;
    }

    WarpMessenger public constant WARP_MESSENGER =
        WarpMessenger(0x0200000000000000000000000000000000000005);

    // Tracks the latest message ID used for a given destination chain.
    // Key is the destination chain ID, and the value is the last message ID used for that chain.
    // Note that the first message ID used for each chain will be 1 (not 0).
    mapping(bytes32 => uint256) public latestMessageIDs;

    // Tracks the outstanding receipts to send back to a given chain in subsequent messages sent to it.
    // Key is the other chain ID, and the value is a queue of pending receipts for messages
    // we have received from that chain.
    mapping(bytes32 => ReceiptQueue.TeleporterMessageReceiptQueue)
        public outstandingReceipts;

    // Tracks the message hash and fee information for each message sent that we have not yet received
    // a receipt for. The messages are tracked per chain and keyed by message ID.
    // The first key is the chain ID, the second key is the message ID, and the value is the info
    // for the uniquely identified message.
    mapping(bytes32 => mapping(uint256 => SentMessageInfo))
        public sentMessageInfo;

    // Tracks the relayer reward address for each message delivered from a given chain.
    // Note that these values are also used to determine if a given message has been delivered or not.
    // The first key is the chain ID, the second key is the message ID, and the value is the reward address
    // provided by the deliverer of the uniquely identified message.
    mapping(bytes32 => mapping(uint256 => address))
        public relayerRewardAddresses;

    // Tracks the hash of messages that have been received but whose execution has never succeeded.
    // Enables retrying of failed messages with higher gas limits. Message execution is guaranteed to
    // succeed at most once.  The first key is the chain ID, the second key is the message ID, and
    // the value is the hash of the uniquely identified message whose execution failed.
    mapping(bytes32 => mapping(uint256 => bytes32))
        public receivedFailedMessageHashes;

    // Tracks the fee amounts for a given asset able to be redeemed by a given relayer.
    // The first key is the relayer address, the second key is the ERC20 token contract address,
    // and the value is the amount of the asset owed to the relayer.
    mapping(address => mapping(address => uint256)) public relayerRewardAmounts;

    // The blockchain ID of the chain the contract is deployed on. Initialized lazily when receiveCrossChainMessage() is called,
    // if the value has not already been set.
    bytes32 public blockchainID=0xdd084a5ba12bbdae7ccda7d2322009b6ce21267530467f9aa57eac8e71ce6f3f;

    /**
     * @dev See {ITeleporterMessenger-sendCrossChainMessage}
     *
     * When executed, a relayer may kick off an asynchronous event to have the validators of the
     * chain create an aggregate BLS signature of the message.
     *
     * Emits a {SendCrossChainMessage} event when message successfully gets sent.
     */
    function sendCrossChainMessage(
        TeleporterMessageInput calldata messageInput
    ) external senderNonReentrant returns (uint256 messageID) {
        // Get the outstanding receipts for messages that have been previously received
        // from the destination chain but not yet acknowledged, and attach the receipts
        // to the Teleporter message to be sent.
        return
            _sendTeleporterMessage({
                destinationChainID: messageInput.destinationChainID,
                destinationAddress: messageInput.destinationAddress,
                feeInfo: messageInput.feeInfo,
                requiredGasLimit: messageInput.requiredGasLimit,
                allowedRelayerAddresses: messageInput.allowedRelayerAddresses,
                message: messageInput.message,
                receipts: outstandingReceipts[messageInput.destinationChainID]
                    .getOutstandingReceiptsToSend()
            });
    }

    /**
     * @dev See {ITeleporterMessenger-retrySendCrossChainMessage}
     *
     * Emits a {SendCrossChainMessage} event.
     * Requirements:
     *
     * - `message` must have been previously sent to the given `destinationChainID`.
     * - `message` encoding mush match previously sent message.
     */
    function retrySendCrossChainMessage(
        bytes32 destinationChainID,
        TeleporterMessage calldata message
    ) external senderNonReentrant {
        // Get the previously sent message hash.
        SentMessageInfo memory existingMessageInfo = sentMessageInfo[
            destinationChainID
        ][message.messageID];
        // If the message hash is zero, the message was never sent.
        require(
            existingMessageInfo.messageHash != bytes32(0),
            "TeleporterMessenger: message not found"
        );

        // Check that the hash of the provided message matches the one that was originally submitted.
        bytes memory messageBytes = abi.encode(message);
        require(
            keccak256(messageBytes) == existingMessageInfo.messageHash,
            "TeleporterMessenger: invalid message hash"
        );

        // Emit and make state variable changes before external calls when possible,
        // though this function is protected by sender reentrancy guard.
        emit SendCrossChainMessage(
            destinationChainID,
            message.messageID,
            message,
            existingMessageInfo.feeInfo
        );

        // Resubmit the message to the warp message precompile now that we know the exact message was
        // already submitted in the past.
        WARP_MESSENGER.sendWarpMessage(
            destinationChainID,
            address(this),
            messageBytes
        );
    }

    /**
     * @dev See {ITeleporterMessenger-addFeeAmount}
     *
     * Emits an {AddFeeAmount} event.
     * Requirements:
     *
     * - `additionalFeeAmount` must be non-zero.
     * - `message` must exist and not have been delivered yet.
     * - `feeContractAddress` must match the fee asset contract address used in the original call to `sendCrossChainMessage`.
     */
    function addFeeAmount(
        bytes32 destinationChainID,
        uint256 messageID,
        address feeContractAddress,
        uint256 additionalFeeAmount
    ) external senderNonReentrant {
        // The additional fee amount must be non-zero.
        require(
            additionalFeeAmount > 0,
            "TeleporterMessenger: zero additional fee amount"
        );

        // Do not allow adding a fee asset with contract address zero.
        require(
            feeContractAddress != address(0),
            "TeleporterMessenger: zero fee asset contract address"
        );

        // If we have received the delivery receipt for this message, its hash and fee information
        // will be cleared from state. At this point, you can not add to its fee. This is also the
        // case if the given message never existed.
        require(
            sentMessageInfo[destinationChainID][messageID].messageHash !=
                bytes32(0),
            "TeleporterMessenger: message not found"
        );

        // Check that the fee contract address matches the one that was originally used. Only a single
        // fee asset can be used to incentivize the delivery of a given message.
        // We require users to explicitly pass the same fee asset contract address here rather than just using
        // the previously submitted asset type as a defensive measure to avoid having users accidentally confuse
        // which asset they are paying.
        require(
            sentMessageInfo[destinationChainID][messageID]
                .feeInfo
                .contractAddress == feeContractAddress,
            "TeleporterMessenger: invalid fee asset contract address"
        );

        // Transfer the additional fee amount to this Teleporter instance.
        uint256 adjustedAmount = SafeERC20TransferFrom.safeTransferFrom(
            IERC20(feeContractAddress),
            additionalFeeAmount
        );

        // Store the updated fee amount, and emit it as an event.
        sentMessageInfo[destinationChainID][messageID]
            .feeInfo
            .amount += adjustedAmount;

        emit AddFeeAmount(
            destinationChainID,
            messageID,
            sentMessageInfo[destinationChainID][messageID].feeInfo
        );
    }

    /**
     * @dev See {ITeleporterMessenger-receiveCrossChainMessage}
     *
     * Emits a {ReceiveCrossChainMessage} event.
     * Re-entrancy is explicitly disallowed between receiving functions. One message is not able to receive another message.
     * Requirements:
     *
     * - `relayerRewardAddress` must not be the zero address.
     * - `messageIndex` must specify a valid warp message in the transaction's storage slots.
     * - Valid warp message provided in storage slots, and sender address matches the address of this contract.
     * - Warp message `destinationChainID` must match the `blockchainID` of this contract.
     * - Warp message `destinationAddress` must match the address of this contract.
     * - Teleporter message was not previously delivered.
     * - Transaction was sent by an allowed relayer for corresponding teleporter message.
     */
    function receiveCrossChainMessage(
        uint32 messageIndex,
        address relayerRewardAddress,
        bytes memory msg_
    ) external receiverNonReentrant {
        // The relayer reward address is not allowed to be the zero address because it is how the
        // contract tracks whether or not a message has been delivered.
        require(
            relayerRewardAddress != address(0),
            "TeleporterMessenger: zero relayer reward address"
        );

        // Verify and parse the cross chain message included in the transaction access list
        // using the warp message precompile.
        (WarpMessage memory warpMessage, bool success) =  abi.decode(msg_, (WarpMessage,bool));
        require(success, "TeleporterMessenger: invalid warp message");

        // Only allow for messages to be received from the same address as this teleporter contract.
        // The contract should be deployed using the universal deployer pattern, such that it knows messages
        // received from the same address on other chains were constructed using the same bytecode of this contract.
        // This allows for trusting the message format and uniqueness as specified by sendCrossChainMessage.
        require(
            warpMessage.originSenderAddress == address(this),
            "TeleporterMessenger: invalid origin sender address"
        );

        // If the blockchain ID has yet to be initialized, do so now.
        if (blockchainID == bytes32(0)) {
            blockchainID = WARP_MESSENGER.getBlockchainID();
        }

        // Require that the message was intended for this blockchain and teleporter contract.
        require(
            warpMessage.destinationChainID == blockchainID,
            "TeleporterMessenger: invalid destination chain ID"
        );
        require(
            warpMessage.destinationAddress == address(this),
            "TeleporterMessenger: invalid destination address"
        );

        // Parse the payload of the message.
        TeleporterMessage memory teleporterMessage = abi.decode(
            warpMessage.payload,
            (TeleporterMessage)
        );

        // Check the message has not been delivered before by checking that there is no relayer reward
        // address stored for it already.
        require(
            relayerRewardAddresses[warpMessage.sourceChainID][
                teleporterMessage.messageID
            ] == address(0),
            "TeleporterMessenger: message already delivered"
        );

//         Check that the caller is allowed to deliver this message.
        require(
            _checkIsAllowedRelayer(
                msg.sender,
                teleporterMessage.allowedRelayerAddresses
            ),
            "TeleporterMessenger: unauthorized relayer"
        );

        // Store the relayer reward address provided, effectively marking the message as received.
        relayerRewardAddresses[warpMessage.sourceChainID][
            teleporterMessage.messageID
        ] = relayerRewardAddress;

        // Execute the message.
        if (teleporterMessage.message.length > 0) {
            _handleInitialMessageExecution(
                warpMessage.sourceChainID,
                teleporterMessage
            );
        }

        // Process the receipts that were included in the teleporter message by paying the
        // fee for the messages are reward to the given relayers.
        uint256 length = teleporterMessage.receipts.length;
        for (uint256 i = 0; i < length; ++i) {
            TeleporterMessageReceipt memory receipt = teleporterMessage
                .receipts[i];
            _markReceipt(
                warpMessage.sourceChainID,
                receipt.receivedMessageID,
                receipt.relayerRewardAddress
            );
        }

        // Store the receipt of this message delivery. When a subsquent message is sent back
        // to the origin of this message, we will clean up the receipt state.
        // If the receipts queue contract for this chain doesn't exist yet, create it now.
        ReceiptQueue.TeleporterMessageReceiptQueue
            storage receiptsQueue = outstandingReceipts[
                warpMessage.sourceChainID
            ];

        receiptsQueue.enqueue(
            TeleporterMessageReceipt({
                receivedMessageID: teleporterMessage.messageID,
                relayerRewardAddress: relayerRewardAddress
            })
        );

//        emit ReceiveCrossChainMessage(
//            warpMessage.sourceChainID,
//            teleporterMessage.messageID,
//            msg.sender,
//            relayerRewardAddress,
//            teleporterMessage
//        );
    }

    /**
     * @dev See {ITeleporterMessenger-retryMessageExecution}
     *
     * A Teleporter message has an associated `requiredGasLimit` that is used to execute the message.
     * If the `requiredGasLimit` is too low, then the message execution will fail. This method allows
     * for retrying the execution of a message with a higher gas limit. Contrary to `receiveCrossChainMessage`,
     * which will only use `requiredGasLimit` in the sub-call to execute the message, this method may
     * use all of the gas available in the transaction.
     *
     * Reverts if the message execution fails again on the specified message.
     * Emits a {MessageExecuted} event if the retry is successful.
     * Requirements:
     *
     * - `message` must have previously failed to execute, and matches the hash of the failed message.
     */
    function retryMessageExecution(
        bytes32 originChainID,
        TeleporterMessage calldata message
    ) external receiverNonReentrant {
        // Check that the hash of the payload provided matches the hash of the payload that preivously failed to execute.
        bytes32 failedMessageHash = receivedFailedMessageHashes[originChainID][
            message.messageID
        ];
        require(
            failedMessageHash != bytes32(0),
            "TeleporterMessenger: message not found"
        );
        require(
            keccak256(abi.encode(message)) == failedMessageHash,
            "TeleporterMessenger: invalid message hash"
        );

        // Check that the target address has fully initialized contract code prior to calling it.
        // If the target address does not have code, the execution automatically fails because
        // we disallow calling EOA addresses.
        require(
            message.destinationAddress.code.length > 0,
            "TeleporterMessenger: destination address has no code"
        );

        // Clear the failed message hash from state prior to retrying its execution to redundantly prevent
        // reentrance attacks (on top of the nonReentrant guard).
        emit MessageExecuted(originChainID, message.messageID);
        delete receivedFailedMessageHashes[originChainID][message.messageID];

        // Reattempt the message execution with all of the gas left available for execution of this transaction.
        // We use all of the gas left because this message has already been successfully delivered, and it is the
        // responsibility of the caller to provide as much gas is needed. Compared to the initial delivery, where
        // the relayer should still receive their reward even if the message exeuction takes more gas than expected.
        // We require that the call be successful because if not the retry is considered to have failed and we
        // should revert this transaction so the message can be retried again if desired.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = message.destinationAddress.call(
            abi.encodeCall(
                ITeleporterReceiver.receiveTeleporterMessage,
                (originChainID, message.senderAddress, message.message)
            )
        );
        require(success, "TeleporterMessenger: retry execution failed");
    }

    /**
     * @dev See {ITeleporterMessenger-sendSpecifiedReceipts}
     *
     * There is no explicit limit to the number of receipts able to be sent by a {sendSpecifiedReceipts} message because
     * this method is intended to be used by relayers themselves to ensure their receipts get returned.
     * There is no fee associated with the empty message, and the same relayer is expected to relay it
     * themselves in order to claim their rewards, so it is their responsibility to ensure that the necessary
     * gas is provided for however many receipts are being retried.
     *
     * These specified receipts are not removed from their corresponding receipt queue because there
     * is no efficient way to remove a specific receipt from an arbitrary position in the queue, and it is
     * harmless for receipts to be sent multiple times within the protocol.
     *
     * Emits {SendCrossChainMessage} event.
     * Requirements:
     * - `messageIDs` must all be valid and have existing receipts.
     */
    function sendSpecifiedReceipts(
        bytes32 originChainID,
        uint256[] calldata messageIDs,
        TeleporterFeeInfo calldata feeInfo,
        address[] calldata allowedRelayerAddresses
    ) external senderNonReentrant returns (uint256 messageID) {
        // Iterate through the specified message IDs and create teleporter receipts to send back.
        TeleporterMessageReceipt[]
            memory receiptsToSend = new TeleporterMessageReceipt[](
                messageIDs.length
            );
        for (uint256 i = 0; i < messageIDs.length; i++) {
            uint256 receivedMessageID = messageIDs[i];
            // Check the relayer reward address for this message.
            address relayerRewardAddress = relayerRewardAddresses[
                originChainID
            ][receivedMessageID];
            require(
                relayerRewardAddress != address(0),
                "TeleporterMessenger: receipt not found"
            );

            receiptsToSend[i] = TeleporterMessageReceipt({
                receivedMessageID: receivedMessageID,
                relayerRewardAddress: relayerRewardAddress
            });
        }

        messageID = _sendTeleporterMessage({
            destinationChainID: originChainID,
            destinationAddress: address(0),
            feeInfo: feeInfo,
            requiredGasLimit: uint256(0),
            allowedRelayerAddresses: allowedRelayerAddresses,
            message: new bytes(0),
            receipts: receiptsToSend
        });
        return messageID;
    }

    /**
     * @dev See {ITeleporterMessenger-redeemRelayerRewards}
     *
     * Requirements:
     *
     * - `rewardAmount` must be non-zero.
     */
    function redeemRelayerRewards(address feeAsset) external {
        uint256 rewardAmount = relayerRewardAmounts[msg.sender][feeAsset];
        require(rewardAmount > 0, "TeleporterMessenger: no reward to redeem");

        // Zero the reward balance before calling the external ERC20 to transfer the
        // reward to prevent any possible re-entrancy.
        delete relayerRewardAmounts[msg.sender][feeAsset];

        emit RelayerRewardsRedeemed(msg.sender, feeAsset, rewardAmount);

        // We don't need to handle "fee on transfer" tokens in a special case here because
        // the amount credited to the caller does not affect this contracts accounting. The
        // reward is considered paid in full in all cases.
        IERC20(feeAsset).safeTransfer(msg.sender, rewardAmount);
    }

    /**
     * See {ITeleporterMessenger-getMessageHash}
     */
    function getMessageHash(
        bytes32 destinationChainID,
        uint256 messageID
    ) external view returns (bytes32 messageHash) {
        return sentMessageInfo[destinationChainID][messageID].messageHash;
    }

    /**
     * @dev See {ITeleporterMessenger-messageReceived}
     */
    function messageReceived(
        bytes32 originChainID,
        uint256 messageID
    ) external view returns (bool delivered) {
        return relayerRewardAddresses[originChainID][messageID] != address(0);
    }

    /**
     * @dev See {ITeleporterMessenger-getRelayerRewardAddress}
     */
    function getRelayerRewardAddress(
        bytes32 originChainID,
        uint256 messageID
    ) external view returns (address relayerRewardAddress) {
        return relayerRewardAddresses[originChainID][messageID];
    }

    /**
     * @dev See {ITeleporterMessenger-checkRelayerRewardAmount}
     */
    function checkRelayerRewardAmount(
        address relayer,
        address feeAsset
    ) external view returns (uint256) {
        return relayerRewardAmounts[relayer][feeAsset];
    }

    /**
     * @dev See {ITeleporterMessenger-getFeeInfo}
     */
    function getFeeInfo(
        bytes32 destinationChainID,
        uint256 messageID
    ) external view returns (address feeAsset, uint256 feeAmount) {
        TeleporterFeeInfo memory feeInfo = sentMessageInfo[destinationChainID][
            messageID
        ].feeInfo;
        return (feeInfo.contractAddress, feeInfo.amount);
    }

    /**
     * @dev Returns the next message ID to be used to send a message to the given chain ID.
     */
    function getNextMessageID(
        bytes32 chainID
    ) external view returns (uint256 messageID) {
        return _getNextMessageID(chainID);
    }

    /**
     * @dev See {ITeleporterMessenger-getReceiptQueueSize}
     */
    function getReceiptQueueSize(
        bytes32 chainID
    ) external view returns (uint256) {
        return outstandingReceipts[chainID].size();
    }

    /**
     * @dev See {ITeleporterMessenger-getReceiptAtIndex}
     */
    function getReceiptAtIndex(
        bytes32 chainID,
        uint256 index
    ) external view returns (TeleporterMessageReceipt memory) {
        return outstandingReceipts[chainID].getReceiptAtIndex(index);
    }

    /**
     * @dev Checks whether `delivererAddress` is allowed to deliver the message.
     */
    function checkIsAllowedRelayer(
        address delivererAddress,
        address[] calldata allowedRelayers
    ) external pure returns (bool) {
        return _checkIsAllowedRelayer(delivererAddress, allowedRelayers);
    }

    /**
     * @dev Helper function for sending a teleporter message cross chain.
     * Constructs the Teleporter message and sends it through the Warp Messenger precompile,
     * and performs fee transfer if necessary.
     *
     * Emits a {SendCrossChainMessage} event.
     */
    function _sendTeleporterMessage(
        bytes32 destinationChainID,
        address destinationAddress,
        TeleporterFeeInfo calldata feeInfo,
        uint256 requiredGasLimit,
        address[] calldata allowedRelayerAddresses,
        bytes memory message,
        TeleporterMessageReceipt[] memory receipts
    ) private returns (uint256 messageID) {
        // Get the message ID to use for this message.
        messageID = _getNextMessageID(destinationChainID);

        // Construct and serialize the message.
        TeleporterMessage memory teleporterMessage = TeleporterMessage({
            messageID: messageID,
            senderAddress: msg.sender,
            destinationAddress: destinationAddress,
            requiredGasLimit: requiredGasLimit,
            allowedRelayerAddresses: allowedRelayerAddresses,
            receipts: receipts,
            message: message
        });
        bytes memory teleporterMessageBytes = abi.encode(teleporterMessage);

        // Set the message ID value as being used.
        latestMessageIDs[destinationChainID] = messageID;

        // If the fee amount is non-zero, transfer the asset into control of this TeleporterMessenger contract instance.
        // We allow the fee to be 0 because its possible for someone to run their own relayer and deliver their own messages,
        // which does not require further incentivization. They still must pay the transaction fee to submit the message, so
        // this is not a DOS vector in terms of being able to submit zero-fee messages.
        uint256 adjustedFeeAmount = 0;
        if (feeInfo.amount > 0) {
            // If the fee amount is non-zero, check that the contract address is not address(0)
            require(
                feeInfo.contractAddress != address(0),
                "TeleporterMessenger: zero fee asset contract address"
            );

            adjustedFeeAmount = SafeERC20TransferFrom.safeTransferFrom(
                IERC20(feeInfo.contractAddress),
                feeInfo.amount
            );
        }

        // Store the fee asset and amount to be paid to the relayer of this message upon receiving the receipt.
        // Also store the message hash so that it can be retried until we get receipt of its delivery.
        TeleporterFeeInfo memory adjustedFeeInfo = TeleporterFeeInfo({
            contractAddress: feeInfo.contractAddress,
            amount: adjustedFeeAmount
        });
        sentMessageInfo[destinationChainID][messageID] = SentMessageInfo({
            messageHash: keccak256(teleporterMessageBytes),
            feeInfo: adjustedFeeInfo
        });

        emit SendCrossChainMessage(
            destinationChainID,
            messageID,
            teleporterMessage,
            adjustedFeeInfo
        );

        // Submit the message to the AWM precompile.
        // The Teleporter contract only allows for sending messages to other instances of the same
        // contract at the same address on other EVM chains, which is why we set the destination adress
        // as the address of this contract.
        WARP_MESSENGER.sendWarpMessage(
            destinationChainID,
            address(this),
            teleporterMessageBytes
        );

        return messageID;
    }

    /**
     * @dev Marks the receipt of a message from the given `destinationChainID` with the given `messageID`.
     *
     * It is possible that the receipt was already received for this message, in which case we return early.
     * If existing message is found and not yet delivered, we delete it from state and increment the fee/reward
     */
    function _markReceipt(
        bytes32 destinationChainID,
        uint256 messageID,
        address relayerRewardAddress
    ) private {
        // Get the information about the sent message we are now marking as received.
        SentMessageInfo memory messageInfo = sentMessageInfo[
            destinationChainID
        ][messageID];

        // If the message hash does not exist, it could be the case that the receipt was already
        // received for this message (it's possible for receipts to be sent more than once)
        // or that the other chain sent an invalid receipt. We return early since this is an expected
        // case where there is no fee to be paid for the given message.
        if (messageInfo.messageHash == bytes32(0)) {
            return;
        }

        // Delete the message information from state now that we know it has been delivered.
        delete sentMessageInfo[destinationChainID][messageID];

        // Increment the fee/reward amount owed to the relayer for having delivered
        // the message identified in this receipt.
        relayerRewardAmounts[relayerRewardAddress][
            messageInfo.feeInfo.contractAddress
        ] += messageInfo.feeInfo.amount;
    }

    /**
     * @dev Attempts to execute the newly delivered message.
     *
     * Only revert in the event that the message deliverer (relayer) did not provide enough gas to handle the execution
     * (including possibly storing a failed message in state). All execution specific errors (i.e. invalid call data, etc)
     * that are not in the relayers control are caught and handled properly.
     *
     * Emits a {MessageExecuted} event if the call on destination address is successful.
     * Emits a {MessageExecutionFailed} event if the call on destination address fails with formatted call data.
     * Requirements:
     *
     * - There is enough gas left to cover `message.requiredGasLimit`.
     */
    function _handleInitialMessageExecution(
        bytes32 originChainID,
        TeleporterMessage memory message
    ) private {
        // Check that the message delivery was provided the required gas amount as specified by the sender.
        // If the required gas amount is provided, the message will be considered delivered whether or not
        // its execution succeeds, such that the relayer can claim their fee reward. However, if the message
        // execution fails, the message hash will be stored in state such that anyone can try to provide more
        // gas to successfully execute the message.
        require(
            gasleft() >= message.requiredGasLimit,
            "TeleporterMessenger: insufficient gas"
        );

        // The destination address must have fully initialized contract code in order for the message
        // to call it. If the destination address does not have code, we store the message as a failed
        // execution so that it can be retried in the future should a contract be later deployed to
        // the address.
        if (message.destinationAddress.code.length == 0) {
            _storeFailedMessageExecution(originChainID, message);
            return;
        }

        // Call the destination address of the message with the formatted call data.
        // We only provide the required gas limit to the sub-call because we know that
        // we have sufficient gas left to cover that amount, and do not want to allow the
        // end application to consume arbitrary gas.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = message.destinationAddress.call{
            gas: message.requiredGasLimit
        }(
            abi.encodeCall(
                ITeleporterReceiver.receiveTeleporterMessage,
                (originChainID, message.senderAddress, message.message)
            )
        );

        // If the execution failed, we will store a hash of the message in state such that it's
        // execution can be retried again in the future with a higher gas limit (paid by whoever
        // retries).Either way, the message will now be considered "delivered" since the relayer
        // provided enough gas to meet the required gas limit.
        if (!success) {
            _storeFailedMessageExecution(originChainID, message);
            return;
        }

        emit MessageExecuted(originChainID, message.messageID);
    }

    /**
     * @dev Stores the hash of a message that has been successfully delivered but fails to execute properly
     * such that the message execution can be retried by anyone in the future.
     */
    function _storeFailedMessageExecution(
        bytes32 originChainID,
        TeleporterMessage memory message
    ) private {
        receivedFailedMessageHashes[originChainID][
            message.messageID
        ] = keccak256(abi.encode(message));

        // Emit a failed execution event for anyone monitoring unsuccessful messages to retry.
        emit MessageExecutionFailed(originChainID, message.messageID, message);
    }

    /**
     * @dev Returns the next message ID to be used to send a message to the given `chainID`.
     */
    function _getNextMessageID(
        bytes32 chainID
    ) private view returns (uint256 messageID) {
        return latestMessageIDs[chainID] + 1;
    }

    /**
     * @dev Checks whether `delivererAddress` is allowed to deliver the message.
     */
    function _checkIsAllowedRelayer(
        address delivererAddress,
        address[] memory allowedRelayers
    ) private pure returns (bool) {
        // An empty allowed relayers list means anyone is allowed to deliver the message.
        if (allowedRelayers.length == 0) {
            return true;
        }

        // Otherwise, the deliverer address must be included in allowedRelayers.
        for (uint256 i = 0; i < allowedRelayers.length; ++i) {
            if (allowedRelayers[i] == delivererAddress) {
                return true;
            }
        }
        return false;
    }
}
