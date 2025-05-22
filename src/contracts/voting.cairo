use super::{IVotingNFTDispatcher, IVotingNFTDispatcherTrait};
use starknet::{ContractAddress};
use starknet::get_caller_address;

#[starknet::interface]
trait VotingABINFT<TContractState> {
    fn vote(ref self: TContractState, president_index: felt252, secret_hash: felt252);
    fn get_votes(self: @TContractState, proposal_index: felt252) -> felt252;
}

#[starknet::contract]
mod VotingContract {
    use super::{ContractAddress, get_caller_address, VotingABINFT, IVotingNFTDispatcher, IVotingNFTDispatcherTrait};
    use starknet::storage::Map;
    use starknet::storage::{StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::storage::{StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        has_voted: Map<(ContractAddress, felt252), felt252>, // user -> proposal_index -> has_voted
        proposal_count: felt252,
        proposal_votes: Map<felt252, felt252>,
        voting_nft_contract: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.proposal_count.write(0);
    }

    #[abi(embed_v0)]
    impl VotingABIImpl of VotingABINFT<ContractState> {
        fn vote(ref self: ContractState, president_index: felt252, secret_hash: felt252) {
            // Verificar que no ha votado antes
            let caller = get_caller_address();

            let nft_contract_addr = self.voting_nft_contract.read();

             // Crear una instancia del dispatcher con la dirección del contrato VotingNFT
             let nft_dispatcher = IVotingNFTDispatcher { contract_address: nft_contract_addr };

             nft_dispatcher.mint_president_vote_token(caller)

            // Actualizar conteo de votos
            let current_votes = self.proposal_votes.read(president_index);
            self.proposal_votes.write(president_index, current_votes + 1);
        }

        fn get_votes(self: @ContractState, proposal_index: felt252) -> felt252 {
            // Obtener votos para el presidente
            let votes = self.proposal_votes.read(proposal_index);
            return votes;
        }
    }
}