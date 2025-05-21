#[starknet::interface]
trait PresidentABI<TContractState> {
    fn create_president(
        ref self: TContractState,
        name: felt252,
        first_surname: felt252,
        second_surname: felt252,
        political_party: felt252,
        active: bool
    );
    fn deactivate_president(
        ref self: TContractState,
        id: felt252
    );
}

#[derive(Drop, Serde, starknet::Store)]
struct President {
    name: felt252,
    first_surname: felt252,
    second_surname: felt252,
    political_party: felt252,
    active: bool,
}


#[starknet::contract]
mod PresidentContract {
    use super::{PresidentABI, President};
    use starknet::storage::{Map, StoragePathEntry, StoragePointerWriteAccess, StoragePointerReadAccess};

 

    #[storage]
    struct Storage {
        presidents: Map<felt252, President>,
        next_president_id: felt252,
    }

    #[abi(embed_v0)]
    impl PresidentABIImpl of PresidentABI<ContractState> {
        fn create_president(
            ref self: ContractState,
            name: felt252,
            first_surname: felt252,
            second_surname: felt252,
            political_party: felt252,
            active: bool
        ) {
            let id = self.next_president_id.read();
            let new_president = President {
                name,
                first_surname,
                second_surname,
                political_party,
                active: true,
            };
            self.presidents.entry(id).write(new_president);
            self.next_president_id.write(id + 1);
        }

        fn deactivate_president(ref self: ContractState, id: felt252) {
            let mut president = self.presidents.entry(id).read();
            president.active = false;
            self.presidents.entry(id).write(president);
        }
    }
}