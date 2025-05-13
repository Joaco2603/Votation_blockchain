use starknet::ContractAddress;
use starknet::get_caller_address;


#[starknet::interface]
trait VotingABI<TContractState> {
    fn create_president(ref self: TContractState, president_name: felt252,president_first_surname: felt252,president_second_surname:felt252, political_party: felt252);
    fn deactive_presindent(ref self: TContractState, id: felt252);
}

#[starknet::contract]
mod VotingContract {
    use super::{ContractAddress, get_caller_address, VotingABI};
    use starknet::storage::Map;
    use starknet::storage::{StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};

    #[storage]
    struct Storage {
        information: Map<(felt252), felt252, felt252, felt252, bool>,
    }

    #[abi(embed_v0)]
    impl VotingABIImpl of VotingABI<ContractState> {
        fn create_president(ref self: ContractState, president_name: felt252,president_first_surname: felt252, president_second_surname: felt252, political_party: felt252) {
            let caller = get_caller_address();

            // Registrar presidente
            self.information.write(president_name, president_first_surname, president_second_surname, political_party, false);
        }
           
        fn deactive_presindent(ref self: ContractState, id: felt252) {
            let caller = get_caller_address();
            presidentUpdate = self.information.read(id);
            // Registrar voto
            self.information.write(presindentUpdate,!false);
        }
    }
}