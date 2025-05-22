use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::storage::*;

#[starknet::interface]
trait IVotingNFT<TContractState> {
    // Estas deben coincidir con las funciones públicas de VotingNFT
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn get_has_voted(self: @TContractState, user: ContractAddress) -> bool;
    fn mint_vote_token(ref self: TContractState, to: ContractAddress);
}

#[starknet::contract]
pub mod VotingNFT {
    use starknet::ContractAddress;
    use starknet::storage::*;
    use starknet::get_caller_address;
    use core::panic_with_felt252;

    // Import necessary components and interfaces
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::token::erc721::interface::{IERC721, IERC721CamelOnly, IERC721Metadata, IERC721MetadataCamelOnly};

    // Declare components
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // Instantiate internal component implementations (not embedded)
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // Instantiate internal component implementations (not embedded)
    // impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;
    impl SRC5InternalImpl = openzeppelin::introspection::src5::SRC5Component::InternalImpl<ContractState>;

    // Instantiate empty hooks implementation (not embedded)
    // Even if not used, the trait must be implemented <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">2</a><a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/components#components" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">4</a>
    impl ERC721HooksImpl = ERC721HooksEmptyImpl<ContractState>;
    // In your contract module, alongside other impl instantiations

    // Define storage
    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        // Store the single unique owner address explicitly
        single_owner: ContractAddress,
        // Map to track if the unique token has been used
        token_used: Map<u256, bool>,
        // Address of the authorized voting contract
        pub voting_contract: ContractAddress, 
        // Map to track if a user has voted
        pub has_voted: Map::<ContractAddress, bool>, 
    }

    // Define events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        // Custom event for when the token is used
        TokenUsed: TokenUsed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TokenUsed {
        token_id: u256,
        user: ContractAddress,
    }

    // Constructor to initialize the contract, mint the unique token, and set the owner
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        initial_recipient: ContractAddress, // The address that will own the single, unique token
        token_id_to_mint: u256 // The ID of the single token to be minted
    ) {
        // Initialize components
        self.erc721.initializer(name, symbol, base_uri);

        // Store the single unique owner
        self.single_owner.write(initial_recipient);

        // Mint the single token to the initial recipient
        self.erc721.mint(initial_recipient, token_id_to_mint);
    }

    // Custom implementation of IERC721 to disable transfers and approvals
    // #[abi(embed_v0)] makes these functions external entrypoints <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/components#components" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">4</a>
    #[abi(embed_v0)]
    impl CustomERC721Impl of IERC721<ContractState> {
        // Allow querying balance (should be 1 for the owner, 0 for others) <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a><a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">2</a>
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc721.balance_of(account)
        }

        // Allow querying the owner of the unique token <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a><a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">2</a>
        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.owner_of(token_id)
        }

        // Override transfer functions to disable transfers
        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            panic_with_felt252('Transfers disabled');
        }

        fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256) {
            panic_with_felt252('Transfers disabled');
        }

        // Override approval functions to disable approvals
        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            panic_with_felt252('Approvals disabled');
        }

        fn set_approval_for_all(ref self: ContractState, operator: ContractAddress, approved: bool) {
            panic_with_felt252('Approvals disabled');
        }

        // Allow querying approved address (will likely be zero address if approvals are disabled) <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a><a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">2</a>
        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.get_approved(token_id)
        }

        // Allow querying if operator is approved for all (will be false if approvals are disabled) <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a><a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">2</a>
        fn is_approved_for_all(self: @ContractState, owner: ContractAddress, operator: ContractAddress) -> bool {
            self.erc721.is_approved_for_all(owner, operator)
        }
    }

    // Custom implementation of IERC721CamelOnly for camelCase interface <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a>
    // Override transfer and approval functions to disable them
    #[abi(embed_v0)]
    impl CustomERC721CamelOnlyImpl of IERC721CamelOnly<ContractState> {
         fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc721.balance_of(account)
        }

        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.erc721.owner_of(tokenId)
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            panic_with_felt252('Transfers disabled');
        }

        fn transferFrom(ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: u256) {
            panic_with_felt252('Transfers disabled');
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            panic_with_felt252('Approvals disabled');
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.erc721.get_approved(tokenId)
        }

        fn isApprovedForAll(self: @ContractState, owner: ContractAddress, operator: ContractAddress) -> bool {
            self.erc721.is_approved_for_all(owner, operator)
        }
    }

    // Embed standard Metadata implementations (optional but recommended) <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a>
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnlyImpl = ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;

    // Embed standard SRC5 implementation for interface introspection <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a>
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;


    // Custom external function to perform the "single-use" action
    // #[external(v0)]
    // fn use_token(ref self: ContractState, token_id: u256) {
    //     let caller = get_caller_address();
    //     let owner = self.erc721.owner_of(token_id);

    //     // Assert that the caller is the owner of the token <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">1</a><a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">2</a>
    //     if (caller != owner) {
    //         panic_with_felt252('Not owner');
    //     }

    //     // Check if the token has already been used
    //     let is_used = self.token_used.read(token_id);
    //     assert(!is_used, 'VotingNFT: Token already used');

    //     // Mark the token as used
    //     self.token_used.write(token_id, true);

    //     // Burn the token to enforce single use and remove it from circulation <a href="https://docs.openzeppelin.com/../contracts-cairo/1.0.0/api/erc721#erc721" target="_blank" rel="noopener noreferrer" className="bg-light-secondary dark:bg-dark-secondary px-1 rounded ml-1 no-underline text-xs text-black/70 dark:text-white/70 relative hover:underline">2</a>
    //     // This also makes owner_of(token_id) revert after use, preventing re-usage attempts
    //     self.erc721.burn(token_id);

    //     // Emit a custom event indicating the token was used
    //     self.emit(Event::TokenUsed(TokenUsed { token_id, user: caller }));
    // }

    // Optional: Add a view function to check if a token has been used
    // #[external(v0)]
    // fn is_token_used(self: @ContractState, token_id: u256) -> bool {
    //     self.token_used.read(token_id)
    // }

    // Optional: Add a view function to get the single owner address
    // #[external(v0)]
    // fn get_single_owner(self: @ContractState) -> ContractAddress {
    //     self.single_owner.read()
    // }

    #[external(v0)]
    fn mint_vote_token(ref self: ContractState, to: ContractAddress) {
        // Check if the caller is the authorized voting contract
        assert(get_caller_address() == self.voting_contract.read(), "Unauthorized caller");

        // Check if the recipient has already received a vote token
        assert(!self.has_voted.read(to), "Ya votaste en esta elección");

        // Token ID = recipient address (unique and verifiable)
        let token_id: u256 = to.into(); // Correctly convert ContractAddress to u256

        // Mint the ERC721 token using the internal _mint function
        self.erc721._mint(to, token_id);

        // Mark the recipient as having voted
        self.has_voted.write(to, true);

        // Emit a custom event for successful minting
        self.emit(Event::VoteTokenMinted(VoteTokenMinted { recipient: to, token_id }));
    }

    // Getter function to check if a user has voted
    #[external(v0)]
    fn get_has_voted(self: @ContractState, user: ContractAddress) -> bool {
        self.has_voted.read(user)
    }
}