use starknet::ContractAddress;
use starknet::get_caller_address;


#[starknet::interface]
trait VotingABI<TContractState> {
    fn vote(ref self: TContractState, proposal_index: felt252, secret_hash: felt252);
    fn create_proposal(ref self: TContractState, description: felt252) -> felt252;
    fn get_proposal_votes(self: @TContractState, proposal_index: felt252) -> felt252;
    fn get_proposal_description(self: @TContractState, proposal_index: felt252) -> felt252;
}

#[starknet::contract]
mod VotingContract {
    use super::{ContractAddress, get_caller_address, VotingABI};
    use starknet::storage::Map;
    use starknet::storage::{StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};

    #[storage]
    struct Storage {
        has_voted: Map<(ContractAddress, felt252), felt252>, // user -> proposal_index -> has_voted
        proposal_count: felt252,
        proposal_description: Map<felt252, felt252>, // proposal_index -> description
        proposal_votes: Map<felt252, felt252>, // proposal_index -> vote_count
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.proposal_count.write(0);
    }

    #[abi(embed_v0)]
    impl VotingABIImpl of VotingABI<ContractState> {
        fn vote(ref self: ContractState, proposal_index: felt252, secret_hash: felt252) {
            // Verificar que no ha votado antes
            let caller = get_caller_address();
            let already_voted = self.has_voted.read((caller, proposal_index));
            assert(already_voted == 0, 'User already voted');

            // Registrar voto
            self.has_voted.write((caller, proposal_index), 1);

            // Actualizar conteo de votos
            let current_votes = self.proposal_votes.read(proposal_index);
            self.proposal_votes.write(proposal_index, current_votes + 1);
        }

        fn create_proposal(ref self: ContractState, description: felt252) -> felt252 {
            let current_count = self.proposal_count.read();
            self.proposal_description.write(current_count, description);
            self.proposal_votes.write(current_count, 0);
            self.proposal_count.write(current_count + 1);
            current_count // Retorna el índice de la nueva propuesta
        }

        fn get_proposal_votes(self: @ContractState, proposal_index: felt252) -> felt252 {
            self.proposal_votes.read(proposal_index)
        }

        fn get_proposal_description(self: @ContractState, proposal_index: felt252) -> felt252 {
            self.proposal_description.read(proposal_index)
        }
    }
}