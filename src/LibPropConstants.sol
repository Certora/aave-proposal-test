
library LibPropConstants {
    

    // Addresses
    address internal constant AAVE_GOVERNANCE = 0xEC568fffba86c094cf06b22134B23074DFE2252c;
    address internal constant ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;
    address internal constant ECOSYSTEM_RESERVE_CONTROLLER = 0x1E506cbb6721B83B1549fa1558332381Ffa61A93;
    address internal constant SHORT_EXECUTOR = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
    address internal constant AAVE_TOKEN_PROXY = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9; 
    address internal constant USDC_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant SABLIER = 0xCD18eAa163733Da39c232722cBC4E8940b1D8888;
    address internal constant CERTORA_BENEFICIARY = address(0x0); // xxx
    address internal constant CERTORA_AAVE_MULTISIG = address(0x0); // xxx
    // new impl
    address internal constant AAVE_COLLECTOR = 0xa335E2443b59d11337E9005c9AF5bC31F8000714; // 0x464c71f6c2f760dda6093dcb91c24c39e5d6e18c; old impl?

    // Amounts
    uint256 internal constant USDC_V3 = 420_000;
    uint256 internal constant USDC_VEST = 1_000_000;
    uint256 internal constant AAVE_VEST_USDC_WORTH = 700_000;
    uint256 internal constant AAVE_FUND_USDC_WORTH = 200_000;

    uint256 internal constant AAVE_PRICE_USDC_6_DECIMALS = 158_226364; // $158.2263636 xxx
    uint8 internal constant AAVE_PRICE_DECIMALS = 6;
    /*
    ICollector public constant NEW_COLLECTOR_IMPL =
        ICollector(0xa335E2443b59d11337E9005c9AF5bC31F8000714);

    address public constant GOV_SHORT_EXECUTOR =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    IERC20 internal constant AAVE =
        IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    IERC20 internal constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IERC20 internal constant AUSDC =
        IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C);

    IERC20 internal constant AWETH =
        IERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e);
    IERC20 internal constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IPool internal constant POOL =
        IPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    uint256 internal constant USDC_AMOUNT = 90000 * 1e6; // 90k USDC
    uint256 internal constant ETH_AMOUNT = 3 ether;

    address internal constant FUNDS_RECIPIENT =
        0xB85fa70cf9aB580580D437BdEA785b71631a8A7c;*/
}
